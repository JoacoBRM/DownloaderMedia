import 'package:flutter_test/flutter_test.dart';
import 'package:downloader_media/data/services/ytdlp_service.dart';

void main() {
  group('YtDlpService progress parser', () {
    test('parses full progress lines', () {
      final progress = YtDlpService.parseProgressLine(
        '[download]  45.2% of ~150.3MiB at 5.2MiB/s ETA 00:15',
      );

      expect(progress, isNotNull);
      expect(progress!.percent, 45.2);
      expect(progress.totalSize, '150.3MiB');
      expect(progress.speed, '5.2MiB/s');
      expect(progress.eta, '00:15');
    });

    test('parses simple progress lines', () {
      final progress = YtDlpService.parseProgressLine('[download]  7.5%');

      expect(progress, isNotNull);
      expect(progress!.percent, 7.5);
    });

    test('ignores non-progress lines', () {
      expect(
        YtDlpService.parseProgressLine('[Merger] Merging formats'),
        isNull,
      );
    });
  });
}
