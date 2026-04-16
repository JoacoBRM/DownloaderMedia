import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../data/models/download_task.dart';
import '../../shared/widgets/platform_icon.dart';
import 'providers/download_provider.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final queue = ref.watch(downloadQueueProvider);
    final activeDownloads = queue.where((DownloadTask t) => t.isActive || t.isQueued).toList();
    final completed = queue.where((DownloadTask t) => t.isCompleted).toList();
    final failed = queue.where((DownloadTask t) => t.isFailed || t.isCancelled).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.get('downloads'),
                style: Theme.of(context).textTheme.displayMedium,
              ),
              if (completed.isNotEmpty)
                TextButton.icon(
                  onPressed: () =>
                      ref.read(downloadQueueProvider.notifier).clearCompleted(),
                  icon: const Icon(Icons.done_all_rounded,
                      size: 16, color: AppColors.textMuted),
                  label: Text(
                    l10n.get('clearCompleted'),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
            ],
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 24),

          // Active downloads
          if (activeDownloads.isNotEmpty) ...[
            _SectionTitle(
              title: '${l10n.get('downloading')} (${activeDownloads.length})',
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            ...activeDownloads.map(
              (task) => _DownloadCard(task: task).animate().fadeIn(duration: 300.ms),
            ),
            const SizedBox(height: 24),
          ],

          // Completed
          if (completed.isNotEmpty) ...[
            _SectionTitle(
              title: '${l10n.get('completed')} (${completed.length})',
              color: AppColors.success,
            ),
            const SizedBox(height: 12),
            ...completed.map(
              (task) => _DownloadCard(task: task).animate().fadeIn(duration: 300.ms),
            ),
            const SizedBox(height: 24),
          ],

          // Failed
          if (failed.isNotEmpty) ...[
            _SectionTitle(
              title: '${l10n.get('failed')} (${failed.length})',
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            ...failed.map(
              (task) => _DownloadCard(task: task).animate().fadeIn(duration: 300.ms),
            ),
          ],

          // Empty state
          if (queue.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Column(
                  children: [
                    Icon(Icons.download_rounded,
                        size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      l10n.get('noDownloads'),
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 500.ms),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _DownloadCard extends ConsumerWidget {
  final DownloadTask task;

  const _DownloadCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Platform icon
              if (task.platform != null)
                PlatformIcon(platform: task.platform!, size: 18),
              if (task.platform != null) const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StatusBadge(status: task.status),
                        const SizedBox(width: 8),
                        Icon(
                          task.type == DownloadType.audio
                              ? Icons.music_note_rounded
                              : Icons.videocam_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${task.format.toUpperCase()} ${task.quality}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        if (task.speed != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            task.speed!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (task.eta != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'ETA ${task.eta}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              if (task.isActive)
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted, size: 18),
                  onPressed: () => ref
                      .read(downloadQueueProvider.notifier)
                      .cancelTask(task.id),
                  tooltip: 'Cancel',
                ),
              if (task.isCompleted || task.isFailed || task.isCancelled)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.textMuted, size: 18),
                  onPressed: () => ref
                      .read(downloadQueueProvider.notifier)
                      .removeTask(task.id),
                  tooltip: 'Remove',
                ),
            ],
          ),
          // Progress bar
          if (task.isActive || task.status == DownloadStatus.queued) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: task.isQueued ? null : task.progress,
                      minHeight: 6,
                      backgroundColor: AppColors.bgElevated,
                      valueColor:
                          AlwaysStoppedAnimation(_statusColor(task.status)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 45,
                  child: Text(
                    task.isQueued
                        ? '...'
                        : '${(task.progress * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _statusColor(task.status),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          // Error message
          if (task.error != null && task.isFailed) ...[
            const SizedBox(height: 8),
            Text(
              task.error!,
              style: const TextStyle(color: AppColors.error, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
      case DownloadStatus.fetchingInfo:
        return AppColors.primary;
      case DownloadStatus.completed:
        return AppColors.success;
      case DownloadStatus.failed:
        return AppColors.error;
      case DownloadStatus.cancelled:
        return AppColors.warning;
      case DownloadStatus.merging:
      case DownloadStatus.converting:
        return AppColors.info;
      default:
        return AppColors.textMuted;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final DownloadStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String get _label {
    switch (status) {
      case DownloadStatus.queued:
        return 'QUEUED';
      case DownloadStatus.fetchingInfo:
        return 'FETCHING';
      case DownloadStatus.downloading:
        return 'DOWNLOADING';
      case DownloadStatus.merging:
        return 'MERGING';
      case DownloadStatus.converting:
        return 'CONVERTING';
      case DownloadStatus.completed:
        return 'DONE';
      case DownloadStatus.failed:
        return 'FAILED';
      case DownloadStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color get _color {
    switch (status) {
      case DownloadStatus.downloading:
      case DownloadStatus.fetchingInfo:
        return AppColors.primary;
      case DownloadStatus.completed:
        return AppColors.success;
      case DownloadStatus.failed:
        return AppColors.error;
      case DownloadStatus.cancelled:
        return AppColors.warning;
      case DownloadStatus.merging:
      case DownloadStatus.converting:
        return AppColors.info;
      default:
        return AppColors.textMuted;
    }
  }
}
