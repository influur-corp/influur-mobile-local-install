Write-Host "Starting installation for influur-mobile on Windows..."

# Install Chocolatey (if not installed)
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
else {
    Write-Host "Chocolatey is already installed."
}

# Add Chocolatey to environment variable PATH
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    $chocoPath = "$($env:ProgramData)\chocolatey\bin"
    $envPaths = $env:Path -split ";"

    if (-not ($envPaths -contains $chocoPath)) {
        [System.Environment]::SetEnvironmentVariable("Path", ($env:Path + ";$chocoPath"), [System.EnvironmentVariableTarget]::Machine)
    
        $env:Path += ";$chocoPath"
        Write-Host "Chocolatey added to environment variable PATH.: " $env:Path
    }
    else {
        Write-Host "Chocolatey is already added to environment variable with current PATH.: " $env:Path
    }
}
else {
    Write-Host "Chocolatey already added to environment variable PATH.: " $env:Path
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
$influurPath = "$($env:USERPROFILE)\Development\influur"
if (!(Test-Path -Path $influurPath)) {
    Write-Host "Create directory to clone repository."
    New-Item -ItemType Directory -Path $influurPath
}

# Clone repository
if (!(Test-Path -Path "$influurPath\influur-mobile")) {
    Write-Host "Cloning influur-mobile repository..."
    Write-Host "Must type your passphrase to clone the repository..."
    
    Set-Location $influurPath
    git clone git@github.com:influur-corp/influur-mobile.git
}
else {
    git checkout develop ; git pull origin develop
}

# Install Flutter
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    $flutterPath = "$($env:USERPROFILE)\Development\flutter"
    if (-not (Test-Path $flutterPath)) {
        Write-Host "Installing Flutter, this will take time..."
    
        $chromeAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 Edg/133.0.0.0"
        Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.3-stable.zip" -OutFile "$env:TEMP\flutter.zip" -UserAgent $chromeAgent
    
        Expand-Archive -Path "$env:TEMP\flutter.zip" -DestinationPath $flutterPath
        Remove-Item "$env:TEMP\flutter.zip"
    }
    else {
        Write-Host "Flutter is already installed in the current directory."
    }
}
else {
    Write-Host "Flutter is already installed."
}

# Add Flutter to environment variable PATH
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    $flutterPath = "$($env:USERPROFILE)\Development\flutter\bin"
    $envPaths = $env:Path -split ";"

    if (-not ($envPaths -contains $flutterPath)) {
        [System.Environment]::SetEnvironmentVariable("Path", ($env:Path + ";$flutterPath"), [System.EnvironmentVariableTarget]::User)

        $env:Path += ";$flutterPath"
        Write-Host "Flutter added to environment variable PATH.: " $env:Path
    }
    else {
        Write-Host "Flutter is already added to environment variable with current PATH.: " $env:Path
    }
}
else {
    Write-Host "Flutter already added to environment variable PATH.: " $env:Path
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
$influurRepoPath = "$($env:USERPROFILE)\Development\influur\influur-mobile"

Set-Location $influurRepoPath
flutter clean ; flutter pub get

# Remove generated file and the .env file
$envFile = "$($influurRepoPath)\.env"
if (Test-Path -Path $envFile -PathType Leaf) {
    Remove-Item -Force $envFile
}

$generatedFile = "$($influurRepoPath)\lib\services\environment_manager\environment_manager.g.dart"
if (Test-Path -Path $generatedFile -PathType Leaf) {
    Remove-Item -Force $generatedFile
}

# Configure .env file
$tempEnvFile = "$($env:USERPROFILE)\environmentTemp\.env"
if (Test-Path -Path $tempEnvFile -PathType Leaf) {
    Move-Item -Path $tempEnvFile -Destination $influurRepoPath
    Write-Host "File '$tempEnvFile' moved to $influurRepoPath."

    Remove-Item -Path "$($env:USERPROFILE)\environmentTemp" -Recurse
}
else {
    Write-Host "The file '$tempEnvFile' doesn't exist."
    exit 1
}

# Run build_runner commands
Write-Host "Run build_runner command..."
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs

# Success message
Write-Host "Installation complete! Running the app..."
flutter run --dart-define=DART_BUILD_ENV=dev
