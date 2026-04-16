import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'DownloaderMedia',
      'home': 'Home',
      'downloads': 'Downloads',
      'history': 'History',
      'settings': 'Settings',
      'pasteUrl': 'Paste your link here...',
      'download': 'Download',
      'downloadVideo': 'Video Only',
      'downloadVideoWithAudio': 'Video + Audio',
      'downloadAudio': 'Audio Only',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'retry': 'Retry',
      'openFile': 'Open File',
      'openFolder': 'Open Folder',
      'clearHistory': 'Clear History',
      'clearCompleted': 'Clear Completed',
      'noDownloads': 'No active downloads',
      'noHistory': 'Download history is empty',
      'fetchingInfo': 'Fetching video info...',
      'selectFormat': 'Select Format',
      'videoQuality': 'Video Quality',
      'audioQuality': 'Audio Quality',
      'selectFolder': 'Select download folder',
      'downloading': 'Downloading',
      'completed': 'Completed',
      'failed': 'Failed',
      'cancelled': 'Cancelled',
      'queued': 'Queued',
      'merging': 'Merging',
      'converting': 'Converting',
      'speed': 'Speed',
      'eta': 'ETA',
      'size': 'Size',
      'duration': 'Duration',
      'platform': 'Platform',
      'format': 'Format',
      'quality': 'Quality',
      'settingsTitle': 'Settings',
      'language': 'Language',
      'maxDownloads': 'Max simultaneous downloads',
      'defaultQuality': 'Default quality',
      'defaultFormat': 'Default format',
      'about': 'About',
      'version': 'Version',
      'setupTitle': 'First Time Setup',
      'setupDesc': 'Downloading required components...',
      'downloadingYtDlp': 'Downloading yt-dlp...',
      'downloadingFfmpeg': 'Downloading FFmpeg...',
      'setupComplete': 'Setup complete!',
      'setupError': 'Setup failed. Please check your connection.',
      'retrySetup': 'Retry Setup',
      'invalidUrl': 'Please enter a valid URL',
      'playlist': 'Playlist',
      'videos': 'videos',
      'downloadAll': 'Download All',
      'supportedPlatforms': 'Supported Platforms',
    },
    'es': {
      'appTitle': 'DownloaderMedia',
      'home': 'Inicio',
      'downloads': 'Descargas',
      'history': 'Historial',
      'settings': 'Ajustes',
      'pasteUrl': 'Pega tu enlace aquí...',
      'download': 'Descargar',
      'downloadVideo': 'Solo Video',
      'downloadVideoWithAudio': 'Video + Audio',
      'downloadAudio': 'Solo Audio',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
      'retry': 'Reintentar',
      'openFile': 'Abrir Archivo',
      'openFolder': 'Abrir Carpeta',
      'clearHistory': 'Limpiar Historial',
      'clearCompleted': 'Limpiar Completadas',
      'noDownloads': 'Sin descargas activas',
      'noHistory': 'El historial está vacío',
      'fetchingInfo': 'Obteniendo información...',
      'selectFormat': 'Seleccionar Formato',
      'videoQuality': 'Calidad de Video',
      'audioQuality': 'Calidad de Audio',
      'selectFolder': 'Seleccionar carpeta de descarga',
      'downloading': 'Descargando',
      'completed': 'Completada',
      'failed': 'Fallida',
      'cancelled': 'Cancelada',
      'queued': 'En cola',
      'merging': 'Combinando',
      'converting': 'Convirtiendo',
      'speed': 'Velocidad',
      'eta': 'Tiempo restante',
      'size': 'Tamaño',
      'duration': 'Duración',
      'platform': 'Plataforma',
      'format': 'Formato',
      'quality': 'Calidad',
      'settingsTitle': 'Ajustes',
      'language': 'Idioma',
      'maxDownloads': 'Descargas simultáneas máximas',
      'defaultQuality': 'Calidad por defecto',
      'defaultFormat': 'Formato por defecto',
      'about': 'Acerca de',
      'version': 'Versión',
      'setupTitle': 'Configuración Inicial',
      'setupDesc': 'Descargando componentes necesarios...',
      'downloadingYtDlp': 'Descargando yt-dlp...',
      'downloadingFfmpeg': 'Descargando FFmpeg...',
      'setupComplete': '¡Configuración completa!',
      'setupError': 'Error en la configuración. Verifica tu conexión.',
      'retrySetup': 'Reintentar',
      'invalidUrl': 'Por favor ingresa una URL válida',
      'playlist': 'Lista de reproducción',
      'videos': 'videos',
      'downloadAll': 'Descargar Todo',
      'supportedPlatforms': 'Plataformas Soportadas',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
