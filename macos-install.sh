#!/bin/bash

echo "Starting installation for influur-mobile on macOS..."

# Install Homebrew (if not installed)
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew already installed!!"
fi

# Install Rosetta
if arch -x86_64 /usr/bin/true &>/dev/null; then
    echo "Rosetta already installed!!"
else
    echo "Installing Rosetta..."
    softwareupdate --install-rosetta --agree-to-license
fi

# Install Git
if ! command -v git &>/dev/null; then
    echo "Installing Git..."
    brew install git
else
    echo "Git already installed!!!"
fi

influur_root_directory="$HOME/Development/influur"

# Create necessary directories
if [ ! -d $influur_root_directory ]; then
    echo "Create directory to clone repository."
    mkdir -p $influur_root_directory
fi

# Clone repository
if [ ! -d "$influur_root_directory/influur-mobile" ]; then
    echo "Cloning influur-mobile repository..."
    echo "Must type your passphrase to clone the repository..."

    cd $influur_root_directory || exit
    git clone git@github.com:influur-corp/influur-mobile.git
else
    cd "$influur_root_directory/influur-mobile" || exit
    git checkout develop && git pull origin develop
fi

# Install Xcode (if not installed)
if ! xcode-select --print-path &>/dev/null; then
    echo "Installing Xcode..."
    xcode-select --install
else
    echo "Xcode already installed"
fi

# Accept Xcode license
echo "Accept Xcode licenses, it is possible that you must type your password."
sudo xcodebuild -license status | grep -q "accepted"
if [ $? -ne 0 ]; then
    echo "Xcode licenses are not accepted. I'm trying to accept them automatically..."
    sudo xcodebuild -license accept
    if [ $? -eq 0 ]; then
        echo "Xcode licenses have been accepted."
    else
        echo "Could not automatically accept Xcode licenses."
    fi
else
    echo "Xcode licenses are accepted."
fi

# Install CocoaPods
if ! command -v pod &>/dev/null; then
    echo "Installing CocoaPods..."
    sudo gem install cocoapods
else
    echo "Cocoapods already installed"
fi

# Configure Xcode command line tools and open Xcode.
echo "Configure command line tools and Xcode..."
sudo sh -c 'xcode-select -s /Applications/Xcode.app/Contents/Developer && xcodebuild -runFirstLaunch'
open -a Xcode

# Create Simulator and open it.
echo "Create Default Simulator..."
xcrun simctl create "MyCustomSimulator" "iPhone 15" "com.apple.CoreSimulator.SimRuntime.iOS-17-2"
open -a Simulator

# Install Flutter
FLUTTER_DIR="$HOME/Development/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
    echo "Installing Flutter..."
    mkdir -p "$FLUTTER_DIR"
    cd "$FLUTTER_DIR" || exit
    curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.24.3-stable.zip
    unzip flutter_macos_3.24.3-stable.zip
    rm flutter_macos_3.24.3-stable.zip
else
    echo "Flutter already installed"
fi

# Add Flutter to PATH
if ! grep -q 'export PATH=$HOME/Development/flutter/bin:$PATH' ~/.zshrc; then
    echo "Adding Flutter to PATH..."
    echo "# Start Flutter Configuration" >>~/.zshrc
    echo 'export PATH=$HOME/Development/flutter/bin:$PATH' >>~/.zshrc
    echo "# End Flutter Configuration" >>~/.zshrc
    source ~/.zshrc
fi

# Verify Flutter installation
echo "Verify Flutter installation with flutter doctor command."
flutter doctor

# Install Android Studio (if not installed)
if [ ! -d "/Applications/Android Studio.app" ]; then
    echo "Installing Android Studio..."
    brew install --cask android-studio
else
    echo "Android studio already installed"
fi

# Install Android SDK & accept licenses
echo "Accept Android licenses."
flutter doctor --android-licenses --suppress-analytics >/dev/null 2>&1
if [ $? -ne 0 ]; then
    flutter doctor --android-licenses --suppress-analytics >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Android licenses have been accepted."
    else
        echo "Android licenses could not be accepted automatically."
    fi
else
    echo "Android licenses are accepted."
fi

# Install project dependencies
echo "Get project's dependencies."
cd "$influur_root_directory/influur-mobile" || exit
flutter clean && flutter pub get

# Remove generated file and the .env file
rm -rf .env
rm -rf lib/services/environment_manager/environment_manager.g.dart

# Configure .env file
ENV_FILE="$HOME/environmentTemp/.env"
if [ -f "$ENV_FILE" ]; then
    mv "$ENV_FILE" "$influur_root_directory/influur-mobile"
    echo "File '$ENV_FILE' moved to '$influur_root_directory/influur-mobile'."

    rm -f $ENV_FILE
else
    echo "The file '$ENV_FILE' doesn't exist."
    exit 1
fi

# Run build_runner commands
echo "Run build_runner command..."
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
cd ios && pod install && cd ..

# Success message and run the app
echo "Installation complete! Running the app..."
flutter run --dart-define=DART_BUILD_ENV=dev
