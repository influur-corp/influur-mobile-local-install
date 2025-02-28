Write-Host "Starting installation for influur-mobile on Windows..."

# Install Chocolatey (if not installed)
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-Host "Chocolatey is already installed."
}

# Install Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Git..."
    choco install git -y
} else {
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
    
    cd  "$env:USERPROFILE\Development\influur"
    git clone git@github.com:influur-corp/influur-mobile.git
} else {
    git checkout develop && git pull origin develop
}

# Install Flutter
if (-not (Test-Path "$env:USERPROFILE\Development\flutter")) {
    Write-Host "Installing Flutter..."
    Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.3-stable.zip" -OutFile "$env:TEMP\flutter.zip"
    Expand-Archive -Path "$env:TEMP\flutter.zip" -DestinationPath "$env:USERPROFILE\Development\flutter"
    Remove-Item "$env:TEMP\flutter.zip"

    $env:Path += ";$env:USERPROFILE\Development\flutter\bin"
    [System.Environment]::SetEnvironmentVariable("Path", "$env:Path;$env:USERPROFILE\flutter\bin", [System.EnvironmentVariableTarget]::User)
} else {
    Write-Host "Flutter is already installed."
}

# Verify Flutter installation
Write-Host "Verify Flutter installation with flutter doctor command."
flutter doctor

# Install Android Studio (if not installed)
if (-not (Test-Path "$env:ProgramFiles\Android\Android Studio")) {
    Write-Host "Installing Android Studio..."
    choco install androidstudio -y
} else {
    Write-Host "Android Studio is already installed."
}

# Install Java (required for Android development)
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Java..."
    choco install jdk8 -y
} else {
    Write-Host "Java is already installed."
}

# Install Android SDK & accept licenses
Write-Host "Accept Android licenses."
flutter doctor --android-licenses --suppress-analytics *> $null
if ($LASTEXITCODE -ne 0) {
  flutter doctor --android-licenses --suppress-analytics *> $null
  if ($LASTEXITCODE -eq 0) {
    Write-Host "Android licenses have been accepted."
  } else {
    Write-Host "Android licenses could not be accepted automatically."
  }
} else {
  Write-Host "Android licenses are accepted."
}

# Install project dependencies
Write-Host "Get project's dependencies."
cd "$env:USERPROFILE\Development\influur\influur-mobile"
flutter clean && flutter pub get

# Remove generated file and the .env file
Remove-Item -Force ".env"
Remove-Item -Force -Path "lib\services\environment_manager\environment_manager.g.dart"

# Configure .env file
$ENV_FILE="$env:USERPROFILE\environmentTemp\.env"
$TARGET_PATH="$env:USERPROFILE\Development\influur\influur-mobile"
if (Test-Path -Path $ENV_FILE -PathType Leaf) {
  Move-Item -Path $ENV_FILE -Destination $TARGET_PATH
  Write-Host "File '$ENV_FILE' moved to $TARGET_PATH."

  Remove-Item -Force $ENV_FILE
} else {
  Write-Host "The file '$ENV_FILE' doesn't exist."
}

# Run build_runner commands
Write-Host "Run build_runner command..."
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs

# Success message
Write-Host "Installation complete! Running the app..."
flutter run --dart-define=DART_BUILD_ENV=dev
