import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';
import '../../core/constants/app_constants.dart';

enum BinaryStatus { notInstalled, downloading, ready, error }

class BinaryProgress {
  final BinaryStatus ytDlpStatus;
  final BinaryStatus ffmpegStatus;
  final double ytDlpProgress;
  final double ffmpegProgress;
  final String? error;

  const BinaryProgress({
    this.ytDlpStatus = BinaryStatus.notInstalled,
    this.ffmpegStatus = BinaryStatus.notInstalled,
    this.ytDlpProgress = 0.0,
    this.ffmpegProgress = 0.0,
    this.error,
  });

  bool get allReady =>
      ytDlpStatus == BinaryStatus.ready && ffmpegStatus == BinaryStatus.ready;

  BinaryProgress copyWith({
    BinaryStatus? ytDlpStatus,
    BinaryStatus? ffmpegStatus,
    double? ytDlpProgress,
    double? ffmpegProgress,
    String? error,
  }) {
    return BinaryProgress(
      ytDlpStatus: ytDlpStatus ?? this.ytDlpStatus,
      ffmpegStatus: ffmpegStatus ?? this.ffmpegStatus,
      ytDlpProgress: ytDlpProgress ?? this.ytDlpProgress,
      ffmpegProgress: ffmpegProgress ?? this.ffmpegProgress,
      error: error ?? this.error,
    );
  }
}

class BinaryManager {
  final Dio _dio = Dio();

  String get _binDir {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    return p.join(exeDir, 'bin');
  }

  String get ytDlpPath => p.join(_binDir, 'yt-dlp.exe');
  String get ffmpegPath => p.join(_binDir, 'ffmpeg.exe');
  String get ffprobePath => p.join(_binDir, 'ffprobe.exe');
  String get ffmpegLocation => _binDir;

  bool get ytDlpExists => File(ytDlpPath).existsSync();
  bool get ffmpegExists => File(ffmpegPath).existsSync();
  bool get allBinariesExist => ytDlpExists && ffmpegExists;

  Future<void> ensureBinDir() async {
    final dir = Directory(_binDir);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
  }

  Future<BinaryProgress> checkStatus() async {
    return BinaryProgress(
      ytDlpStatus: ytDlpExists ? BinaryStatus.ready : BinaryStatus.notInstalled,
      ffmpegStatus:
          ffmpegExists ? BinaryStatus.ready : BinaryStatus.notInstalled,
    );
  }

  Future<void> downloadYtDlp({
    required void Function(double progress) onProgress,
  }) async {
    await ensureBinDir();
    await _dio.download(
      AppConstants.ytDlpDownloadUrl,
      ytDlpPath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress(received / total);
        }
      },
    );
  }

  Future<void> downloadFfmpeg({
    required void Function(double progress) onProgress,
  }) async {
    await ensureBinDir();
    final zipPath = p.join(_binDir, 'ffmpeg.zip');

    // Download the zip
    await _dio.download(
      AppConstants.ffmpegDownloadUrl,
      zipPath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress(received / total * 0.8); // 80% is download
        }
      },
    );

    // Extract ffmpeg.exe and ffprobe.exe from the zip
    onProgress(0.85);
    await compute(_extractFfmpeg, {
      'zipPath': zipPath,
      'binDir': _binDir,
    });

    // Clean up zip
    onProgress(0.95);
    final zipFile = File(zipPath);
    if (zipFile.existsSync()) {
      await zipFile.delete();
    }
    onProgress(1.0);
  }

  static Future<void> _extractFfmpeg(Map<String, String> params) async {
    final zipPath = params['zipPath']!;
    final binDir = params['binDir']!;

    final bytes = File(zipPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final name = p.basename(file.name);
      if (name == 'ffmpeg.exe' || name == 'ffprobe.exe') {
        final outFile = File(p.join(binDir, name));
        outFile.writeAsBytesSync(file.content as List<int>);
      }
    }
  }

  Future<String?> updateYtDlp() async {
    if (!ytDlpExists) return 'yt-dlp not installed';
    try {
      final result = await Process.run(ytDlpPath, ['-U']);
      return result.stdout.toString().trim();
    } catch (e) {
      return 'Update failed: $e';
    }
  }
}
