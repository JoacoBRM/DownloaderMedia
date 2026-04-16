import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/url_validator.dart';
import '../../core/utils/format_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/download_task.dart';
import '../../data/models/video_info.dart';
import '../../shared/widgets/platform_icon.dart';
import '../downloads/providers/download_provider.dart';
import '../settings/providers/settings_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _urlController = TextEditingController();
  String? _detectedPlatform;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _onUrlChanged(String value) {
    setState(() {
      _detectedPlatform = UrlValidator.detectPlatform(value);
    });
  }

  Future<void> _fetchInfo() async {
    final url = _urlController.text.trim();
    if (!UrlValidator.isValidUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).get('invalidUrl'),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    await ref.read(videoInfoProvider.notifier).fetchInfo(url);
  }

  Future<void> _startDownload(VideoInfo info, DownloadType type) async {
    final settings = ref.read(settingsProvider);
    final l10n = AppLocalizations.of(context);

    // Let user pick folder
    final folder = await FilePicker.getDirectoryPath(
      dialogTitle: l10n.get('selectFolder'),
    );
    if (folder == null) return;

    final ext = type == DownloadType.audio
        ? settings.defaultAudioFormat
        : settings.defaultVideoFormat;
    final quality = type == DownloadType.audio
        ? settings.defaultAudioQuality
        : settings.defaultVideoQuality;

    // Sanitize filename
    final sanitizedTitle = info.title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final outputPath = p.join(folder, '$sanitizedTitle.$ext');

    final task = DownloadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: info.url,
      title: info.title,
      thumbnailUrl: info.thumbnailUrl,
      platform: info.platform ?? _detectedPlatform,
      outputPath: outputPath,
      type: type,
      format: ext,
      quality: quality,
      status: DownloadStatus.queued,
      duration: info.duration,
      createdAt: DateTime.now(),
    );

    ref.read(downloadQueueProvider.notifier).addTask(task);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added "${info.title}" to download queue',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final videoInfo = ref.watch(videoInfoProvider);
    final queue = ref.watch(downloadQueueProvider);
    final activeDownloads = queue.where((t) => t.isActive).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            l10n.get('home'),
            style: Theme.of(context).textTheme.displayMedium,
          ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05, end: 0),
          const SizedBox(height: 8),
          Text(
            l10n.get('supportedPlatforms'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),

          // Platform badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.supportedPlatforms.map((platform) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      AppColors.platformColor(platform).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.platformColor(platform)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PlatformIcon(platform: platform, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      platform,
                      style: TextStyle(
                        color: AppColors.platformColor(platform),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: 32),

          // URL Input
          _buildUrlInput(l10n),

          const SizedBox(height: 24),

          // Video Info Card
          videoInfo.when(
            data: (info) {
              if (info == null) return const SizedBox.shrink();
              return _buildVideoCard(info, l10n);
            },
            loading: () => _buildLoadingCard(l10n),
            error: (e, _) => _buildErrorCard(e.toString()),
          ),

          // Active downloads preview
          if (activeDownloads.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildActiveDownloads(activeDownloads, l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildUrlInput(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.bgCard,
            AppColors.bgElevated.withValues(alpha: 0.5),
          ],
        ),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              if (_detectedPlatform != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: PlatformIcon(
                      platform: _detectedPlatform!, size: 22)
                      .animate()
                      .scale(duration: 200.ms),
                ),
              Expanded(
                child: TextField(
                  controller: _urlController,
                  onChanged: _onUrlChanged,
                  onSubmitted: (_) => _fetchInfo(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.get('pasteUrl'),
                    prefixIcon: const Icon(Icons.link_rounded,
                        color: AppColors.textMuted),
                    suffixIcon: _urlController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: AppColors.textMuted, size: 18),
                            onPressed: () {
                              _urlController.clear();
                              _onUrlChanged('');
                              ref.read(videoInfoProvider.notifier).clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.bgDark.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _fetchInfo,
                  icon: const Icon(Icons.search_rounded, size: 20),
                  label: Text(l10n.get('download')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Paste from clipboard hint
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  _urlController.text = data!.text!;
                  _onUrlChanged(data.text!);
                  _fetchInfo();
                }
              },
              icon: const Icon(Icons.content_paste_rounded,
                  size: 14, color: AppColors.textMuted),
              label: Text(
                'Paste from clipboard',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildVideoCard(VideoInfo info, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                if (info.thumbnailUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: info.thumbnailUrl!,
                      width: 220,
                      height: 130,
                      fit: BoxFit.cover,
                      placeholder: (context2, url) => Container(
                        width: 220,
                        height: 130,
                        color: AppColors.bgElevated,
                        child: const Icon(Icons.image_rounded,
                            color: AppColors.textMuted),
                      ),
                      errorWidget: (context2, url, error) => Container(
                        width: 220,
                        height: 130,
                        color: AppColors.bgElevated,
                        child: const Icon(Icons.broken_image_rounded,
                            color: AppColors.textMuted),
                      ),
                    ),
                  ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (info.uploader != null)
                        Text(
                          info.uploader!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (info.platform != null)
                            PlatformIcon(
                                platform: info.platform!, size: 16),
                          if (info.platform != null)
                            const SizedBox(width: 8),
                          if (info.duration != null)
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  FormatUtils.formatDuration(info.duration!),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          if (info.formats.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                const Icon(Icons.high_quality_rounded,
                                    size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  'Up to ${info.formats.first.quality}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Download buttons
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _startDownload(
                                info, DownloadType.videoWithAudio),
                            icon: const Icon(
                                Icons.smart_display_rounded,
                                size: 18),
                            label: Text(
                                l10n.get('downloadVideoWithAudio')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _startDownload(info, DownloadType.video),
                            icon: const Icon(Icons.videocam_rounded,
                                size: 18),
                            label: Text(l10n.get('downloadVideo')),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _startDownload(info, DownloadType.audio),
                            icon: const Icon(
                                Icons.music_note_rounded,
                                size: 18),
                            label: Text(l10n.get('downloadAudio')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildLoadingCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(l10n.get('fetchingInfo'),
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.error.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).shake(hz: 2, curve: Curves.easeOut);
  }

  Widget _buildActiveDownloads(
      List<DownloadTask> downloads, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${l10n.get('downloading')} (${downloads.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
                begin: 0.5, end: 1.0, duration: 1000.ms),
          ],
        ),
        const SizedBox(height: 12),
        ...downloads.map((task) => _buildMiniProgress(task)),
      ],
    );
  }

  Widget _buildMiniProgress(DownloadTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (task.platform != null)
            PlatformIcon(platform: task.platform!, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: task.progress,
                    minHeight: 4,
                    backgroundColor: AppColors.bgElevated,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(task.progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (task.speed != null) ...[
            const SizedBox(width: 8),
            Text(
              task.speed!,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
