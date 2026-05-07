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
      'download': 'Inspect',
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
      'fetchingInfo': 'Fetching media info...',
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
      'defaultQuality': 'Default video quality',
      'defaultVideoFormat': 'Default video format',
      'defaultAudioFormat': 'Default audio format',
      'defaultAudioQuality': 'Default audio quality',
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
      'pasteClipboard': 'Paste from clipboard',
      'addedToQueue': 'Added to download queue',
      'addedPlaylistToQueue': 'Playlist added to download queue',
      'interruptedDownload':
          'The app closed before this download finished. Retry it if needed.',
      'remove': 'Remove',
      'unknownError': 'The download failed. Please try again.',
      'binaryLocation': 'Components folder',
      'poweredBy': 'Powered by yt-dlp and FFmpeg',
    },
    'es': {
      'appTitle': 'DownloaderMedia',
      'home': 'Inicio',
      'downloads': 'Descargas',
      'history': 'Historial',
      'settings': 'Ajustes',
      'pasteUrl': 'Pega tu enlace aqui...',
      'download': 'Inspeccionar',
      'downloadVideo': 'Solo video',
      'downloadVideoWithAudio': 'Video + audio',
      'downloadAudio': 'Solo audio',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
      'retry': 'Reintentar',
      'openFile': 'Abrir archivo',
      'openFolder': 'Abrir carpeta',
      'clearHistory': 'Limpiar historial',
      'clearCompleted': 'Limpiar completadas',
      'noDownloads': 'No hay descargas activas',
      'noHistory': 'El historial esta vacio',
      'fetchingInfo': 'Obteniendo informacion...',
      'selectFormat': 'Seleccionar formato',
      'videoQuality': 'Calidad de video',
      'audioQuality': 'Calidad de audio',
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
      'size': 'Tamano',
      'duration': 'Duracion',
      'platform': 'Plataforma',
      'format': 'Formato',
      'quality': 'Calidad',
      'settingsTitle': 'Ajustes',
      'language': 'Idioma',
      'maxDownloads': 'Descargas simultaneas maximas',
      'defaultQuality': 'Calidad de video por defecto',
      'defaultVideoFormat': 'Formato de video por defecto',
      'defaultAudioFormat': 'Formato de audio por defecto',
      'defaultAudioQuality': 'Calidad de audio por defecto',
      'about': 'Acerca de',
      'version': 'Version',
      'setupTitle': 'Configuracion inicial',
      'setupDesc': 'Descargando componentes necesarios...',
      'downloadingYtDlp': 'Descargando yt-dlp...',
      'downloadingFfmpeg': 'Descargando FFmpeg...',
      'setupComplete': 'Configuracion completa!',
      'setupError': 'Error en la configuracion. Verifica tu conexion.',
      'retrySetup': 'Reintentar',
      'invalidUrl': 'Ingresa una URL valida',
      'playlist': 'Lista de reproduccion',
      'videos': 'videos',
      'downloadAll': 'Descargar todo',
      'supportedPlatforms': 'Plataformas soportadas',
      'pasteClipboard': 'Pegar desde el portapapeles',
      'addedToQueue': 'Agregado a la cola de descargas',
      'addedPlaylistToQueue': 'Lista agregada a la cola de descargas',
      'interruptedDownload':
          'La app se cerro antes de terminar esta descarga. Reintentala si hace falta.',
      'remove': 'Quitar',
      'unknownError': 'La descarga fallo. Intenta otra vez.',
      'binaryLocation': 'Carpeta de componentes',
      'poweredBy': 'Con yt-dlp y FFmpeg',
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
