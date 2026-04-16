import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/download_task.dart';
import '../../../data/models/video_info.dart';
import '../../../data/services/binary_manager.dart';
import '../../../data/services/database_service.dart';
import '../../../data/services/ytdlp_service.dart';

// Service providers
final binaryManagerProvider = Provider<BinaryManager>((ref) {
  return BinaryManager();
});

final ytDlpServiceProvider = Provider<YtDlpService>((ref) {
  return YtDlpService(ref.read(binaryManagerProvider));
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Binary status provider
final binaryStatusProvider =
    NotifierProvider<BinaryStatusNotifier, BinaryProgress>(
        BinaryStatusNotifier.new);

class BinaryStatusNotifier extends Notifier<BinaryProgress> {
  @override
  BinaryProgress build() {
    _checkStatus();
    return const BinaryProgress();
  }

  BinaryManager get _binaryManager => ref.read(binaryManagerProvider);

  Future<void> _checkStatus() async {
    state = await _binaryManager.checkStatus();
  }

  Future<void> downloadAll() async {
    if (state.allReady) return;

    try {
      // Download yt-dlp
      if (!_binaryManager.ytDlpExists) {
        state = state.copyWith(ytDlpStatus: BinaryStatus.downloading);
        await _binaryManager.downloadYtDlp(
          onProgress: (p) {
            state = state.copyWith(ytDlpProgress: p);
          },
        );
        state = state.copyWith(
          ytDlpStatus: BinaryStatus.ready,
          ytDlpProgress: 1.0,
        );
      }

      // Download ffmpeg
      if (!_binaryManager.ffmpegExists) {
        state = state.copyWith(ffmpegStatus: BinaryStatus.downloading);
        await _binaryManager.downloadFfmpeg(
          onProgress: (p) {
            state = state.copyWith(ffmpegProgress: p);
          },
        );
        state = state.copyWith(
          ffmpegStatus: BinaryStatus.ready,
          ffmpegProgress: 1.0,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Video info fetch provider
final videoInfoProvider =
    NotifierProvider<VideoInfoNotifier, AsyncValue<VideoInfo?>>(
        VideoInfoNotifier.new);

class VideoInfoNotifier extends Notifier<AsyncValue<VideoInfo?>> {
  @override
  AsyncValue<VideoInfo?> build() {
    return const AsyncValue.data(null);
  }

  YtDlpService get _service => ref.read(ytDlpServiceProvider);

  Future<void> fetchInfo(String url) async {
    state = const AsyncValue.loading();
    try {
      final info = await _service.extractInfo(url);
      state = AsyncValue.data(info);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

// Download queue provider
final downloadQueueProvider =
    NotifierProvider<DownloadQueueNotifier, List<DownloadTask>>(
        DownloadQueueNotifier.new);

class DownloadQueueNotifier extends Notifier<List<DownloadTask>> {
  final Map<String, StreamSubscription> _subscriptions = {};
  int _activeCount = 0;

  @override
  List<DownloadTask> build() {
    ref.onDispose(() {
      _ytDlpService.cancelAll();
      for (final sub in _subscriptions.values) {
        sub.cancel();
      }
    });
    return [];
  }

  YtDlpService get _ytDlpService => ref.read(ytDlpServiceProvider);
  DatabaseService get _dbService => ref.read(databaseServiceProvider);

  void addTask(DownloadTask task) {
    state = [...state, task];
    _dbService.insertTask(task);
    _processQueue();
  }

  void addTasks(List<DownloadTask> tasks) {
    state = [...state, ...tasks];
    for (final task in tasks) {
      _dbService.insertTask(task);
    }
    _processQueue();
  }

  void cancelTask(String taskId) {
    _ytDlpService.cancelDownload(taskId);
    _subscriptions[taskId]?.cancel();
    _subscriptions.remove(taskId);
    _activeCount--;

    _updateTask(taskId, (t) => t.copyWith(status: DownloadStatus.cancelled));
    _processQueue();
  }

  void removeTask(String taskId) {
    _ytDlpService.cancelDownload(taskId);
    _subscriptions[taskId]?.cancel();
    _subscriptions.remove(taskId);
    state = state.where((t) => t.id != taskId).toList();
    _dbService.deleteTask(taskId);
  }

  void clearCompleted() {
    final completed = state.where((t) => t.isCompleted).toList();
    state = state.where((t) => !t.isCompleted).toList();
    for (final task in completed) {
      _dbService.updateTask(task);
    }
  }

  void _processQueue() {
    while (_activeCount < AppConstants.maxConcurrentDownloads) {
      final nextTask = state.cast<DownloadTask?>().firstWhere(
            (t) => t!.isQueued,
            orElse: () => null,
          );
      if (nextTask == null) break;
      _startDownload(nextTask);
    }
  }

  void _startDownload(DownloadTask task) {
    _activeCount++;
    _updateTask(
        task.id, (t) => t.copyWith(status: DownloadStatus.downloading));

    late final Stream<DownloadProgress> stream;

    if (task.type == DownloadType.audio) {
      stream = _ytDlpService.downloadAudio(
        taskId: task.id,
        url: task.url,
        outputPath: task.outputPath,
        audioFormat: task.format,
        audioQuality: task.quality,
      );
    } else if (task.type == DownloadType.videoWithAudio) {
      stream = _ytDlpService.downloadVideoWithAudio(
        taskId: task.id,
        url: task.url,
        outputPath: task.outputPath,
        quality: task.quality,
        format: task.format,
      );
    } else {
      stream = _ytDlpService.downloadVideo(
        taskId: task.id,
        url: task.url,
        outputPath: task.outputPath,
        quality: task.quality,
        format: task.format,
      );
    }

    _subscriptions[task.id] = stream.listen(
      (progress) {
        _updateTask(
          task.id,
          (t) => t.copyWith(
            progress: progress.percent / 100.0,
            speed: progress.speed ?? t.speed,
            eta: progress.eta ?? t.eta,
            fileSize: progress.totalSize ?? t.fileSize,
          ),
        );
      },
      onError: (error) {
        _activeCount--;
        _subscriptions.remove(task.id);
        _updateTask(
          task.id,
          (t) => t.copyWith(
            status: DownloadStatus.failed,
            error: error.toString(),
          ),
        );
        _processQueue();
      },
      onDone: () {
        _activeCount--;
        _subscriptions.remove(task.id);
        final current = state.firstWhere((t) => t.id == task.id);
        if (current.status != DownloadStatus.cancelled &&
            current.status != DownloadStatus.failed) {
          _updateTask(
            task.id,
            (t) => t.copyWith(
              status: DownloadStatus.completed,
              progress: 1.0,
              completedAt: DateTime.now(),
            ),
          );
        }
        _processQueue();
      },
    );
  }

  void _updateTask(String taskId, DownloadTask Function(DownloadTask) update) {
    state = [
      for (final task in state)
        if (task.id == taskId) update(task) else task,
    ];

    final updated = state.cast<DownloadTask?>().firstWhere(
          (t) => t!.id == taskId,
          orElse: () => null,
        );
    if (updated != null &&
        (updated.isCompleted || updated.isFailed || updated.isCancelled)) {
      _dbService.updateTask(updated);
    }
  }
}

// History provider
final historyProvider =
    NotifierProvider<HistoryNotifier, AsyncValue<List<DownloadTask>>>(
        HistoryNotifier.new);

class HistoryNotifier extends Notifier<AsyncValue<List<DownloadTask>>> {
  @override
  AsyncValue<List<DownloadTask>> build() {
    loadHistory();
    return const AsyncValue.loading();
  }

  DatabaseService get _dbService => ref.read(databaseServiceProvider);

  Future<void> loadHistory() async {
    try {
      final tasks = await _dbService.getHistory();
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteItem(String id) async {
    await _dbService.deleteTask(id);
    await loadHistory();
  }

  Future<void> clearAll() async {
    await _dbService.clearHistory();
    state = const AsyncValue.data([]);
  }
}
