import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/url_validator.dart';
import '../../../data/models/download_task.dart';
import '../../../data/models/video_info.dart';
import '../../../data/services/binary_manager.dart';
import '../../../data/services/database_service.dart';
import '../../../data/services/ytdlp_service.dart';
import '../../settings/providers/settings_provider.dart';

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
      BinaryStatusNotifier.new,
    );

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
    state = (await _binaryManager.checkStatus()).copyWith(clearError: true);
    if (state.allReady) return;

    try {
      // Download yt-dlp
      if (!_binaryManager.ytDlpExists) {
        state = state.copyWith(
          ytDlpStatus: BinaryStatus.downloading,
          ytDlpProgress: 0.0,
          clearError: true,
        );
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
      if (!_binaryManager.ffmpegBundleExists) {
        state = state.copyWith(
          ffmpegStatus: BinaryStatus.downloading,
          ffmpegProgress: 0.0,
          clearError: true,
        );
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
      state = state.copyWith(
        ytDlpStatus: _binaryManager.ytDlpExists
            ? BinaryStatus.ready
            : BinaryStatus.error,
        ffmpegStatus: _binaryManager.ffmpegBundleExists
            ? BinaryStatus.ready
            : BinaryStatus.error,
        error: e.toString(),
      );
    }
  }
}

// Video info fetch provider
final videoInfoProvider =
    NotifierProvider<VideoInfoNotifier, AsyncValue<MediaPreview?>>(
      VideoInfoNotifier.new,
    );

class MediaPreview {
  final VideoInfo info;
  final PlaylistInfo? playlist;

  const MediaPreview({required this.info, this.playlist});

  bool get isPlaylist => playlist != null || info.isPlaylist;
  List<VideoInfo> get entries => playlist?.entries ?? const [];
}

class VideoInfoNotifier extends Notifier<AsyncValue<MediaPreview?>> {
  @override
  AsyncValue<MediaPreview?> build() {
    return const AsyncValue.data(null);
  }

  YtDlpService get _service => ref.read(ytDlpServiceProvider);

  Future<void> fetchInfo(String url) async {
    state = const AsyncValue.loading();
    try {
      if (UrlValidator.isPlaylist(url)) {
        final playlist = await _service.extractPlaylistInfo(url);
        state = AsyncValue.data(
          MediaPreview(info: playlist.toVideoInfo(), playlist: playlist),
        );
      } else {
        final info = await _service.extractInfo(url);
        state = AsyncValue.data(MediaPreview(info: info));
      }
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
      DownloadQueueNotifier.new,
    );

class DownloadQueueNotifier extends Notifier<List<DownloadTask>> {
  final Map<String, StreamSubscription> _subscriptions = {};
  int _activeCount = 0;

  @override
  List<DownloadTask> build() {
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.maxConcurrentDownloads != next.maxConcurrentDownloads) {
        _processQueue();
      }
    });
    _restoreInterruptedTasks();
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
  int get _maxConcurrentDownloads =>
      ref.read(settingsProvider).maxConcurrentDownloads;

  Future<void> _restoreInterruptedTasks() async {
    final interrupted = await _dbService.getUnfinishedTasks();
    if (interrupted.isEmpty) return;

    const message =
        'The app closed before this download finished. Retry it if needed.';
    final failed = [
      for (final task in interrupted)
        task.copyWith(status: DownloadStatus.failed, error: message),
    ];
    await _dbService.markInterruptedTasksFailed(message);
    state = [...state, ...failed];
  }

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
    final wasRunning = _subscriptions.containsKey(taskId);
    _subscriptions[taskId]?.cancel();
    _subscriptions.remove(taskId);
    if (wasRunning) _decrementActive();

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

  void retryTask(String taskId) {
    _updateTask(taskId, (t) => t.resetForRetry(), persistImmediately: true);
    _processQueue();
  }

  void clearCompleted() {
    final completed = state.where((t) => t.isCompleted).toList();
    state = state.where((t) => !t.isCompleted).toList();
    for (final task in completed) {
      _dbService.updateTask(task);
    }
  }

  void _processQueue() {
    while (_activeCount < _maxConcurrentDownloads) {
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
    _updateTask(task.id, (t) => t.copyWith(status: DownloadStatus.downloading));

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
        if (progress.phase != null) {
          _updateTask(
            task.id,
            (t) => t.copyWith(
              status: progress.phase == 'merging'
                  ? DownloadStatus.merging
                  : DownloadStatus.converting,
            ),
          );
          return;
        }

        final percent = progress.percent;
        if (percent == null) return;
        _updateTask(
          task.id,
          (t) => t.copyWith(
            progress: percent / 100.0,
            speed: progress.speed ?? t.speed,
            eta: progress.eta ?? t.eta,
            fileSize: progress.totalSize ?? t.fileSize,
          ),
        );
      },
      onError: (error) {
        _decrementActive();
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
        _decrementActive();
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

  void _decrementActive() {
    if (_activeCount > 0) {
      _activeCount--;
    }
  }

  void _updateTask(
    String taskId,
    DownloadTask Function(DownloadTask) update, {
    bool persistImmediately = false,
  }) {
    state = [
      for (final task in state)
        if (task.id == taskId) update(task) else task,
    ];

    final updated = state.cast<DownloadTask?>().firstWhere(
      (t) => t!.id == taskId,
      orElse: () => null,
    );
    if (updated != null &&
        (persistImmediately ||
            updated.isCompleted ||
            updated.isFailed ||
            updated.isCancelled)) {
      _dbService.updateTask(updated);
    }
  }
}

// History provider
final historyProvider =
    NotifierProvider<HistoryNotifier, AsyncValue<List<DownloadTask>>>(
      HistoryNotifier.new,
    );

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
