import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class AppSettings {
  final Locale locale;
  final int maxConcurrentDownloads;
  final String defaultVideoQuality;
  final String defaultAudioQuality;
  final String defaultVideoFormat;
  final String defaultAudioFormat;

  const AppSettings({
    this.locale = const Locale('en'),
    this.maxConcurrentDownloads = 3,
    this.defaultVideoQuality = '1080',
    this.defaultAudioQuality = '192',
    this.defaultVideoFormat = 'mp4',
    this.defaultAudioFormat = 'mp3',
  });

  AppSettings copyWith({
    Locale? locale,
    int? maxConcurrentDownloads,
    String? defaultVideoQuality,
    String? defaultAudioQuality,
    String? defaultVideoFormat,
    String? defaultAudioFormat,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      defaultVideoQuality: defaultVideoQuality ?? this.defaultVideoQuality,
      defaultAudioQuality: defaultAudioQuality ?? this.defaultAudioQuality,
      defaultVideoFormat: defaultVideoFormat ?? this.defaultVideoFormat,
      defaultAudioFormat: defaultAudioFormat ?? this.defaultAudioFormat,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      locale: Locale(prefs.getString('locale') ?? 'en'),
      maxConcurrentDownloads: prefs.getInt('maxDownloads') ?? 3,
      defaultVideoQuality: prefs.getString('videoQuality') ?? '1080',
      defaultAudioQuality: prefs.getString('audioQuality') ?? '192',
      defaultVideoFormat: prefs.getString('videoFormat') ?? 'mp4',
      defaultAudioFormat: prefs.getString('audioFormat') ?? 'mp3',
    );
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }

  Future<void> setMaxDownloads(int value) async {
    state = state.copyWith(maxConcurrentDownloads: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxDownloads', value);
  }

  Future<void> setDefaultVideoQuality(String quality) async {
    state = state.copyWith(defaultVideoQuality: quality);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('videoQuality', quality);
  }

  Future<void> setDefaultAudioFormat(String format) async {
    state = state.copyWith(defaultAudioFormat: format);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audioFormat', format);
  }
}
