import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path/path.dart' as p;
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/format_utils.dart';
import '../../data/models/download_task.dart';
import '../../shared/widgets/platform_icon.dart';
import '../downloads/providers/download_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final historyAsync = ref.watch(historyProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.get('history'),
                style: Theme.of(context).textTheme.displayMedium,
              ),
              historyAsync.whenOrNull(
                    data: (items) => items.isNotEmpty
                        ? TextButton.icon(
                            onPressed: () => ref
                                .read(historyProvider.notifier)
                                .clearAll(),
                            icon: const Icon(Icons.delete_sweep_rounded,
                                size: 16, color: AppColors.textMuted),
                            label: Text(
                              l10n.get('clearHistory'),
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 13),
                            ),
                          )
                        : null,
                  ) ??
                  const SizedBox.shrink(),
            ],
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 24),

          historyAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Column(
                      children: [
                        Icon(Icons.history_rounded,
                            size: 64,
                            color:
                                AppColors.textMuted.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          l10n.get('noHistory'),
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms);
              }

              return Column(
                children: items.map((task) {
                  return _HistoryItem(task: task)
                      .animate()
                      .fadeIn(duration: 300.ms);
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (e, _) => Center(
              child: Text(
                e.toString(),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends ConsumerWidget {
  final DownloadTask task;

  const _HistoryItem({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          // Platform icon
          if (task.platform != null)
            PlatformIcon(platform: task.platform!, size: 18),
          if (task.platform != null) const SizedBox(width: 12),

          // Type icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: task.type == DownloadType.audio
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              task.type == DownloadType.audio
                  ? Icons.music_note_rounded
                  : Icons.videocam_rounded,
              size: 16,
              color: task.type == DownloadType.audio
                  ? AppColors.warning
                  : AppColors.info,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${task.format.toUpperCase()} • ${task.completedAt != null ? FormatUtils.timeAgo(task.completedAt!) : ''}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            icon: const Icon(Icons.folder_open_rounded,
                color: AppColors.textMuted, size: 18),
            onPressed: () => _openFolder(task.outputPath),
            tooltip: 'Open folder',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textMuted, size: 18),
            onPressed: () =>
                ref.read(historyProvider.notifier).deleteItem(task.id),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }

  Future<void> _openFolder(String filePath) async {
    final dir = p.dirname(filePath);
    if (Platform.isWindows) {
      await Process.run('explorer', [dir]);
    }
  }
}
