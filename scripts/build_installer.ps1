param(
    [switch]$SkipFlutterBuild,
    [switch]$SkipBinaryDownload
)

$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ReleaseDir = Join-Path $ProjectRoot 'build\windows\x64\runner\Release'
$ReleaseBinDir = Join-Path $ReleaseDir 'bin'
$InstallerScript = Join-Path $ProjectRoot 'installer\downloader_media.iss'
$DistDir = Join-Path $ProjectRoot 'dist'
$ToolsDir = Join-Path $ProjectRoot 'build\installer-tools'

function Find-InnoCompiler {
    $command = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $candidates = @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }

    return $null
}

function Install-InnoSetupIfMissing {
    $iscc = Find-InnoCompiler
    if ($iscc) {
        return $iscc
    }

    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw 'Inno Setup no esta instalado y winget no esta disponible. Instala Inno Setup 6 o agrega ISCC.exe al PATH.'
    }

    Write-Host 'Instalando Inno Setup con winget...'
    & $winget.Source install --id JRSoftware.InnoSetup -e --accept-source-agreements --accept-package-agreements | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw 'No se pudo instalar Inno Setup con winget.'
    }

    $iscc = Find-InnoCompiler
    if (-not $iscc) {
        throw 'Inno Setup se instalo, pero no se encontro ISCC.exe.'
    }

    return $iscc
}

function Copy-IfExists {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (Test-Path -LiteralPath $Source) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
    }
}

function Add-VisualCppRuntimeDlls {
    $systemDir = Join-Path $env:WINDIR 'System32'
    $runtimeDlls = @(
        'concrt140.dll',
        'msvcp140.dll',
        'vcruntime140.dll',
        'vcruntime140_1.dll'
    )

    foreach ($dll in $runtimeDlls) {
        $source = Join-Path $systemDir $dll
        $destination = Join-Path $ReleaseDir $dll
        Copy-IfExists -Source $source -Destination $destination
    }
}

function Ensure-MediaBinaries {
    New-Item -ItemType Directory -Path $ReleaseBinDir -Force | Out-Null

    $localBinDir = Join-Path $env:LOCALAPPDATA 'DownloaderMedia\bin'
    Copy-IfExists -Source (Join-Path $localBinDir 'yt-dlp.exe') -Destination (Join-Path $ReleaseBinDir 'yt-dlp.exe')
    Copy-IfExists -Source (Join-Path $localBinDir 'ffmpeg.exe') -Destination (Join-Path $ReleaseBinDir 'ffmpeg.exe')
    Copy-IfExists -Source (Join-Path $localBinDir 'ffprobe.exe') -Destination (Join-Path $ReleaseBinDir 'ffprobe.exe')

    $hasYtDlp = Test-Path -LiteralPath (Join-Path $ReleaseBinDir 'yt-dlp.exe')
    $hasFfmpeg = Test-Path -LiteralPath (Join-Path $ReleaseBinDir 'ffmpeg.exe')
    $hasFfprobe = Test-Path -LiteralPath (Join-Path $ReleaseBinDir 'ffprobe.exe')

    if (($hasYtDlp -and $hasFfmpeg -and $hasFfprobe) -or $SkipBinaryDownload) {
        return
    }

    New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null

    if (-not $hasYtDlp) {
        Write-Host 'Descargando yt-dlp para incluirlo en el instalador...'
        Invoke-WebRequest `
            -Uri 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe' `
            -OutFile (Join-Path $ReleaseBinDir 'yt-dlp.exe')
    }

    if (-not ($hasFfmpeg -and $hasFfprobe)) {
        $zipPath = Join-Path $ToolsDir 'ffmpeg.zip'
        $extractDir = Join-Path $ToolsDir 'ffmpeg'

        Write-Host 'Descargando FFmpeg para incluirlo en el instalador...'
        Invoke-WebRequest `
            -Uri 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip' `
            -OutFile $zipPath

        if (Test-Path -LiteralPath $extractDir) {
            $resolvedExtractDir = (Resolve-Path -LiteralPath $extractDir).Path
            $resolvedToolsDir = (Resolve-Path -LiteralPath $ToolsDir).Path
            if (-not $resolvedExtractDir.StartsWith($resolvedToolsDir, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw "Ruta de limpieza inesperada: $resolvedExtractDir"
            }
            Remove-Item -LiteralPath $extractDir -Recurse -Force
        }

        Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force
        $ffmpeg = Get-ChildItem -Path $extractDir -Recurse -Filter ffmpeg.exe | Select-Object -First 1
        $ffprobe = Get-ChildItem -Path $extractDir -Recurse -Filter ffprobe.exe | Select-Object -First 1

        if (-not $ffmpeg -or -not $ffprobe) {
            throw 'El zip de FFmpeg no contenia ffmpeg.exe y ffprobe.exe.'
        }

        Copy-Item -LiteralPath $ffmpeg.FullName -Destination (Join-Path $ReleaseBinDir 'ffmpeg.exe') -Force
        Copy-Item -LiteralPath $ffprobe.FullName -Destination (Join-Path $ReleaseBinDir 'ffprobe.exe') -Force
    }
}

Set-Location $ProjectRoot

if (-not $SkipFlutterBuild) {
    flutter pub get
    flutter build windows --release
}

if (-not (Test-Path -LiteralPath $ReleaseDir)) {
    throw "No existe el build release: $ReleaseDir"
}

Ensure-MediaBinaries
Add-VisualCppRuntimeDlls
New-Item -ItemType Directory -Path $DistDir -Force | Out-Null

$iscc = Install-InnoSetupIfMissing
Write-Host "Compilando instalador con $iscc"
& $iscc $InstallerScript
if ($LASTEXITCODE -ne 0) {
    throw 'Inno Setup no pudo compilar el instalador.'
}

$setupPath = Join-Path $DistDir 'downloader_media-setup.exe'
if (-not (Test-Path -LiteralPath $setupPath)) {
    throw "No se encontro el instalador esperado: $setupPath"
}

Write-Host "Instalador listo: $setupPath"
