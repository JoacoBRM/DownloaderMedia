# DownloaderMedia

DownloaderMedia is a Windows desktop app for downloading video or audio from media URLs supported by yt-dlp. It is built with Flutter, stores download history locally with SQLite, and uses FFmpeg for conversion and merging.

## Features

- Inspect a media URL before downloading.
- Download video with audio, video only, or audio only.
- Download playlists as a batch of queued items.
- Configure default video quality, video format, audio format, audio quality, and simultaneous downloads.
- Track active downloads with progress, speed, ETA, merging/conversion states, cancellation, retry, and cleanup.
- Keep a local completed-download history.
- Download and manage yt-dlp, FFmpeg, and FFprobe automatically.
- English and Spanish UI.

## Requirements

- Windows 10 or later.
- Flutter with Windows desktop support enabled.
- Visual Studio Build Tools with the Desktop development with C++ workload.
- Internet access for first-time setup and media downloads.

## Getting Started

```powershell
flutter pub get
flutter run -d windows
```

On first launch, the app downloads the required command-line tools. They are stored in:

```text
%LOCALAPPDATA%\DownloaderMedia\bin
```

Keeping the binaries in LocalAppData avoids write-permission problems when the app is installed under Program Files or as an MSIX package.

## Build

```powershell
flutter build windows --release
```

To create an MSIX package:

```powershell
dart run msix:create
```

The MSIX metadata lives in `pubspec.yaml` under `msix_config`.

To create a double-click Windows installer:

```powershell
.\scripts\build_installer.ps1
```

The installer is generated at:

```text
dist\downloader_media-setup.exe
```

The installer includes the Windows release files and the command-line tools in
`bin\` when they are already present locally, or downloads them during packaging.
On first launch, bundled tools are copied to `%LOCALAPPDATA%\DownloaderMedia\bin`
so the app can use a writable components folder.

## Tests and Analysis

```powershell
flutter test
flutter analyze
```

The test suite covers URL validation, download task persistence/retry behavior, and yt-dlp progress parsing.

## Notes

- Some sites require login, cookies, or regional access. The app surfaces these as actionable download errors where possible.
- If the app closes while downloads are running, unfinished tasks are restored as failed and can be retried.
- Playlist support depends on yt-dlp being able to resolve each playlist entry to a direct webpage URL.

## Responsible Use

Only download media that you own, that is licensed for download, or that you otherwise have permission to save. Respect each platform's terms of service and local law.
