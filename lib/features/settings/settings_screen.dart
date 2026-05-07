import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/constants/app_constants.dart';
import '../downloads/providers/download_provider.dart';
import 'providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get('settingsTitle'),
            style: Theme.of(context).textTheme.displayMedium,
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 32),

          _SettingsSection(
            title: l10n.get('language'),
            icon: Icons.language_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LanguageChip(
                  label: 'English',
                  isSelected: settings.locale.languageCode == 'en',
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setLocale(const Locale('en')),
                ),
                _LanguageChip(
                  label: 'Espanol',
                  isSelected: settings.locale.languageCode == 'es',
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setLocale(const Locale('es')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SettingsSection(
            title: l10n.get('defaultQuality'),
            icon: Icons.high_quality_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['360', '480', '720', '1080', '1440', '2160']
                  .map(
                    (q) => _QualityChip(
                      label: '${q}p',
                      isSelected: settings.defaultVideoQuality == q,
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setDefaultVideoQuality(q),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          _SettingsSection(
            title: l10n.get('defaultVideoFormat'),
            icon: Icons.movie_creation_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['mp4', 'mkv', 'webm']
                  .map(
                    (f) => _QualityChip(
                      label: f.toUpperCase(),
                      isSelected: settings.defaultVideoFormat == f,
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setDefaultVideoFormat(f),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          _SettingsSection(
            title: l10n.get('defaultAudioFormat'),
            icon: Icons.music_note_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['mp3', 'aac', 'flac', 'wav', 'opus']
                  .map(
                    (f) => _QualityChip(
                      label: f.toUpperCase(),
                      isSelected: settings.defaultAudioFormat == f,
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setDefaultAudioFormat(f),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          _SettingsSection(
            title: l10n.get('defaultAudioQuality'),
            icon: Icons.graphic_eq_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['128', '192', '256', '320']
                  .map(
                    (q) => _QualityChip(
                      label: '$q kbps',
                      isSelected: settings.defaultAudioQuality == q,
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setDefaultAudioQuality(q),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          _SettingsSection(
            title: l10n.get('maxDownloads'),
            icon: Icons.speed_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [1, 2, 3, 4, 5]
                  .map(
                    (n) => _QualityChip(
                      label: '$n',
                      isSelected: settings.maxConcurrentDownloads == n,
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setMaxDownloads(n),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 32),

          _SettingsSection(
            title: l10n.get('about'),
            icon: Icons.info_outline_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppConstants.appName} v${AppConstants.appVersion}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.get('poweredBy'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.get('binaryLocation')}: '
                  '${ref.read(binaryManagerProvider).binDir}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.03);
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.bgElevated,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _QualityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QualityChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.bgElevated,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
