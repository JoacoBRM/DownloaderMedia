import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PlatformIcon extends StatelessWidget {
  final String platform;
  final double size;

  const PlatformIcon({
    super.key,
    required this.platform,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        color: AppColors.platformColor(platform).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Icon(
          _platformIcon(platform),
          color: AppColors.platformColor(platform),
          size: size,
        ),
      ),
    );
  }

  IconData _platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return Icons.play_circle_fill_rounded;
      case 'tiktok':
        return Icons.music_note_rounded;
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'twitter':
      case 'x':
        return Icons.tag_rounded;
      case 'facebook':
        return Icons.facebook_rounded;
      case 'soundcloud':
        return Icons.cloud_rounded;
      default:
        return Icons.language_rounded;
    }
  }
}
