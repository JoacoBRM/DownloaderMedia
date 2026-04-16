import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary accent
  static const Color primary = Color(0xFF2D7FF9);
  static const Color primaryLight = Color(0xFF5B9DFF);
  static const Color primaryDark = Color(0xFF1B5FCC);

  // Backgrounds
  static const Color bgDark = Color(0xFF0B0F19);
  static const Color bgSurface = Color(0xFF111827);
  static const Color bgCard = Color(0xFF1A2332);
  static const Color bgElevated = Color(0xFF212D3E);

  // Sidebar
  static const Color sidebarBg = Color(0xFF0D1117);
  static const Color sidebarHover = Color(0xFF161B26);
  static const Color sidebarActive = Color(0xFF2D7FF9);

  // Text
  static const Color textPrimary = Color(0xFFE6EDF5);
  static const Color textSecondary = Color(0xFF8B9BB4);
  static const Color textMuted = Color(0xFF5A6A82);
  static const Color textOnPrimary = Colors.white;

  // Status
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  // Borders
  static const Color border = Color(0xFF1E293B);
  static const Color borderLight = Color(0xFF334155);

  // Glassmorphism
  static Color glassWhite = Colors.white.withValues(alpha: 0.04);
  static Color glassBorder = Colors.white.withValues(alpha: 0.08);

  // Platform colors
  static const Color youtube = Color(0xFFFF0000);
  static const Color tiktok = Color(0xFF00F2EA);
  static const Color instagram = Color(0xFFE4405F);
  static const Color twitter = Color(0xFF1DA1F2);
  static const Color facebook = Color(0xFF1877F2);
  static const Color soundcloud = Color(0xFFFF5500);

  static Color platformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return youtube;
      case 'tiktok':
        return tiktok;
      case 'instagram':
        return instagram;
      case 'twitter':
      case 'x':
        return twitter;
      case 'facebook':
        return facebook;
      case 'soundcloud':
        return soundcloud;
      default:
        return primary;
    }
  }
}
