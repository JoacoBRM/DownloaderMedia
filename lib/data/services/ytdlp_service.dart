import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../models/video_info.dart';
import 'binary_manager.dart';

class DownloadProgress {
  final double percent;
  final String? speed;
  final String? eta;
  final String? totalSize;

  const DownloadProgress({
    required this.percent,
    this.speed,
    this.eta,
    this.totalSize,
  });
}

class YtDlpService {
  final BinaryManager _binaryManager;
  final Map<String, Process> _activeProcesses = {};

  YtDlpService(this._binaryManager);

  /// Extract video metadata without downloading
  Future<VideoInfo> extractInfo(String url) async {
    final result = await Process.run(
      _binaryManager.ytDlpPath,
      [
        '--dump-json',
        '--no-download',
        '--no-warnings',
        '--ffmpeg-location', _binaryManager.ffmpegLocation,
        url.trim(),
      ],
    );

    if (result.exitCode != 0) {
      final error = result.stderr.toString().trim();
      throw Exception('Failed to extract info: $error');
    }

    final json = jsonDecode(result.stdout.toString().trim());
    return VideoInfo.fromJson(json as Map<String, dynamic>);
  }

  /// Extract playlist info (titles and URLs only)
  Future<List<VideoInfo>> extractPlaylistInfo(String url) async {
    final result = await Process.run(
      _binaryManager.ytDlpPath,
      [
        '--dump-json',
        '--flat-playlist',
        '--no-warnings',
        url.trim(),
      ],
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to extract playlist: ${result.stderr}');
    }

    final lines = result.stdout.toString().trim().split('\n');
    final videos = <VideoInfo>[];
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final json = jsonDecode(line.trim());
        videos.add(VideoInfo.fromJson(json as Map<String, dynamic>));
      } catch (_) {
        // Skip malformed entries
      }
    }
    return videos;
  }

  /// Download video only (no audio) with real-time progress
  Stream<DownloadProgress> downloadVideo({
    required String taskId,
    required String url,
    required String outputPath,
    required String quality,
    String format = 'mp4',
  }) async* {
    final args = [
      '--newline',
      '--progress',
      '--no-warnings',
      '--ffmpeg-location', _binaryManager.ffmpegLocation,
      '-f', 'bestvideo[height<=$quality]',
      '-o', outputPath,
      url.trim(),
    ];

    yield* _runProcess(taskId, args);
  }

  /// Download video WITH audio merged via FFmpeg
  Stream<DownloadProgress> downloadVideoWithAudio({
    required String taskId,
    required String url,
    required String outputPath,
    required String quality,
    String format = 'mp4',
  }) async* {
    final formatStr = AppConstants.videoFormats[quality] ??
        'bestvideo+bestaudio/best';

    final args = [
      '--newline',
      '--progress',
      '--no-warnings',
      '--ffmpeg-location', _binaryManager.ffmpegLocation,
      '-f', formatStr,
      '--merge-output-format', format,
      '--postprocessor-args', 'Merger+ffmpeg:-c:a aac -b:a 192k',
      '-o', outputPath,
      url.trim(),
    ];

    yield* _runProcess(taskId, args);
  }

  /// Download audio only with real-time progress
  Stream<DownloadProgress> downloadAudio({
    required String taskId,
    required String url,
    required String outputPath,
    String audioFormat = 'mp3',
    String audioQuality = '192',
  }) async* {
    final args = [
      '--newline',
      '--progress',
      '--no-warnings',
      '--ffmpeg-location', _binaryManager.ffmpegLocation,
      '-x',
      '--audio-format', audioFormat,
      '--audio-quality', audioQuality,
      '--postprocessor-args', 'ExtractAudio+ffmpeg:-c:a libmp3lame -q:a 2',
      '-o', outputPath,
      url.trim(),
    ];

    yield* _runProcess(taskId, args);
  }

  Stream<DownloadProgress> _runProcess(String taskId, List<String> args) async* {
    final process = await Process.start(_binaryManager.ytDlpPath, args);
    _activeProcesses[taskId] = process;

    final controller = StreamController<DownloadProgress>();

    // Listen to stdout for progress updates
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      final progress = _parseLine(line);
      if (progress != null) {
        controller.add(progress);
      }
    });

    // Log stderr for debugging
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      debugPrint('[yt-dlp stderr] $line');
    });

    // Wait for process to finish, then close the stream
    process.exitCode.then((exitCode) {
      _activeProcesses.remove(taskId);
      if (exitCode != 0) {
        controller.addError(Exception('yt-dlp exited with code $exitCode'));
      }
      controller.close();
    });

    // Forward all progress events until controller closes
    yield* controller.stream;
  }

  DownloadProgress? _parseLine(String line) {
    // Full progress line: [download]  45.2% of ~150.3MiB at 5.2MiB/s ETA 00:15
    final fullMatch = AppConstants.progressRegex.firstMatch(line);
    if (fullMatch != null) {
      return DownloadProgress(
        percent: double.parse(fullMatch.group(1)!),
        totalSize: fullMatch.group(2),
        speed: fullMatch.group(3),
        eta: fullMatch.group(4),
      );
    }

    // Simple progress: [download]  45.2%
    final simpleMatch = AppConstants.progressSimpleRegex.firstMatch(line);
    if (simpleMatch != null) {
      return DownloadProgress(
        percent: double.parse(simpleMatch.group(1)!),
      );
    }

    return null;
  }

  /// Cancel an active download
  void cancelDownload(String taskId) {
    final process = _activeProcesses[taskId];
    if (process != null) {
      process.kill(ProcessSignal.sigterm);
      _activeProcesses.remove(taskId);
    }
  }

  /// Cancel all active downloads
  void cancelAll() {
    for (final process in _activeProcesses.values) {
      process.kill(ProcessSignal.sigterm);
    }
    _activeProcesses.clear();
  }

  int get activeCount => _activeProcesses.length;
}
