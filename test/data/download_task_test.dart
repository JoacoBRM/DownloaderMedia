import 'package:flutter_test/flutter_test.dart';
import 'package:downloader_media/data/models/download_task.dart';

void main() {
  group('DownloadTask', () {
    test('round trips through database map', () {
      final createdAt = DateTime(2026, 5, 7, 12);
      final completedAt = DateTime(2026, 5, 7, 13);
      final task = DownloadTask(
        id: '1',
        url: 'https://example.com/video',
        title: 'Example',
        outputPath: r'C:\Downloads\example.mp4',
        type: DownloadType.videoWithAudio,
        format: 'mp4',
        quality: '1080',
        status: DownloadStatus.completed,
        progress: 1,
        fileSize: '20MiB',
        createdAt: createdAt,
        completedAt: completedAt,
      );

      final restored = DownloadTask.fromMap(task.toMap());

      expect(restored.id, task.id);
      expect(restored.type, task.type);
      expect(restored.status, task.status);
      expect(restored.completedAt, completedAt);
    });

    test('resetForRetry clears runtime state', () {
      final task = DownloadTask(
        id: '1',
        url: 'https://example.com/video',
        title: 'Example',
        outputPath: r'C:\Downloads\example.mp4',
        type: DownloadType.audio,
        format: 'mp3',
        quality: '192',
        status: DownloadStatus.failed,
        progress: 0.5,
        speed: '1MiB/s',
        eta: '00:05',
        error: 'Network error',
        createdAt: DateTime(2026, 5, 7),
      );

      final retry = task.resetForRetry();

      expect(retry.status, DownloadStatus.queued);
      expect(retry.progress, 0);
      expect(retry.speed, isNull);
      expect(retry.eta, isNull);
      expect(retry.error, isNull);
    });
  });
}
