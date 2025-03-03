Write-Host "Starting installation for influur-mobile on Windows..."

# Install Chocolatey (if not installed)
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
else {
    Write-Host "Chocolatey is already installed."
}

# Add Chocolatey to environment variable PATH
$chocoPath = "$env:ALLUSERSPROFILE\chocolatey\bin"
if ($env:Path -notmatch [regex]::Escape($chocoPath)) {
    $env:Path += ";$chocoPath"
    [System.Environment]::SetEnvironmentVariable("Path", $env:Path, "Machine")

    Write-Host "Chocolatey added to environment variable PATH."
    [System.Environment]::GetEnvironmentVariable("Path", "Machine")
}
else {
    Write-Host "Chocolatey already added to environment variable PATH."
}

# Install Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Git..."
    choco install git -y
}
else {
    Write-Host "Git is already installed."
}

# Create necessary directories
if (!(Test-Path -Path "$env:USERPROFILE\Development\influur")) {
    Write-Host "Create directory to clone repository."
    New-Item -ItemType Directory -Path "$env:USERPROFILE\Development\influur"
}

# Clone repository
if (!(Test-Path -Path "$env:USERPROFILE\Development\influur\influur-mobile")) {
    Write-Host "Cloning influur-mobile repository..."
    Write-Host "Must type your passphrase to clone the repository..."
    
    Set-Location  "$env:USERPROFILE\Development\influur"
    git clone git@github.com:influur-corp/influur-mobile.git
}
else {
    git checkout develop ; git pull origin develop
}

# Install Flutter
if (-not (Test-Path "$env:USERPROFILE\Development\flutter")) {
    Write-Host "Installing Flutter, this will take time..."

    $chromeAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 Edg/133.0.0.0"
    Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.3-stable.zip" -OutFile "$env:TEMP\flutter.zip" -UserAgent $chromeAgent

    Expand-Archive -Path "$env:TEMP\flutter.zip" -DestinationPath "$env:USERPROFILE\Development\flutter"
    Remove-Item "$env:TEMP\flutter.zip"
}
else {
    Write-Host "Flutter is already installed."
}

# Add Flutter to environment variable PATH
$flutterPath = "$env:USERPROFILE\Development\flutter\bin"
if ($env:Path -notmatch [regex]::Escape($chocoPath)) {
    $env:Path += ";$flutterPath"
    [System.Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::User)

    Write-Host "Flutter added to environment variable PATH."
    [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
}
else {
    Write-Host "Flutter already added to environment variable PATH."
}

# Verify Flutter installation
Write-Host "Verify Flutter installation with flutter doctor command."
flutter doctor

# Install Android Studio (if not installed)
if (-not (Test-Path "$env:ProgramFiles\Android\Android Studio")) {
    Write-Host "Installing Android Studio..."
    choco install androidstudio -y
}
else {
    Write-Host "Android Studio is already installed."
}

# Install Java (required for Android development)
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Java..."
    choco install jdk8 -y
}
else {
    Write-Host "Java is already installed."
}

# Install Android SDK & accept licenses
Write-Host "Accept Android licenses."
flutter doctor --android-licenses --suppress-analytics *> $null
if ($LASTEXITCODE -ne 0) {
    flutter doctor --android-licenses --suppress-analytics *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Android licenses have been accepted."
    }
    else {
        Write-Host "Android licenses could not be accepted automatically."
    }
}
else {
    Write-Host "Android licenses are accepted."
}

# Install FVM if the version it is not the same

# Install project dependencies
Write-Host "Get project's dependencies."
Set-Location "$env:USERPROFILE\Development\influur\influur-mobile"
flutter clean ; flutter pub get

# Remove generated file and the .env file
Remove-Item -Force ".env"
Remove-Item -Force -Path "lib\services\environment_manager\environment_manager.g.dart"

# Configure .env file
$ENV_FILE = "$env:USERPROFILE\environmentTemp\.env"
$TARGET_PATH = "$env:USERPROFILE\Development\influur\influur-mobile"
if (Test-Path -Path $ENV_FILE -PathType Leaf) {
    Move-Item -Path $ENV_FILE -Destination $TARGET_PATH
    Write-Host "File '$ENV_FILE' moved to $TARGET_PATH."

    Remove-Item -Force $ENV_FILE
}
else {
    Write-Host "The file '$ENV_FILE' doesn't exist."
}

# Run build_runner commands
Write-Host "Run build_runner command..."
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs

# Success message
Write-Host "Installation complete! Running the app..."
flutter run --dart-define=DART_BUILD_ENV=dev
