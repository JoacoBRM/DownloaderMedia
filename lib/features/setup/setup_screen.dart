import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../downloads/providers/download_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const SetupScreen({super.key, required this.onComplete});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  @override
  void initState() {
    super.initState();
    _startSetup();
  }

  Future<void> _startSetup() async {
    await ref.read(binaryStatusProvider.notifier).downloadAll();
    final status = ref.read(binaryStatusProvider);
    if (status.allReady) {
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(binaryStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.bgCard,
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05), duration: 1500.ms),
              const SizedBox(height: 24),

              Text(
                l10n.get('setupTitle'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.get('setupDesc'),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // yt-dlp progress
              _SetupItem(
                label: 'yt-dlp',
                description: l10n.get('downloadingYtDlp'),
                progress: status.ytDlpProgress,
                status: status.ytDlpStatus,
              ),
              const SizedBox(height: 16),

              // FFmpeg progress
              _SetupItem(
                label: 'FFmpeg',
                description: l10n.get('downloadingFfmpeg'),
                progress: status.ffmpegProgress,
                status: status.ffmpegStatus,
              ),

              // Error state
              if (status.error != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.error.withValues(alpha: 0.1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          status.error!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _startSetup,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n.get('retrySetup')),
                ),
              ],

              // Success state
              if (status.allReady) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.get('setupComplete'),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms).scale(),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
      ),
    );
  }
}

class _SetupItem extends StatelessWidget {
  final String label;
  final String description;
  final double progress;
  final dynamic status;

  const _SetupItem({
    required this.label,
    required this.description,
    required this.progress,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isReady = status.toString().contains('ready');
    final isDownloading = status.toString().contains('downloading');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.bgElevated.withValues(alpha: 0.5),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (isReady)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 18),
              if (isDownloading)
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          if (isDownloading) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.bgDark,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
