#!/bin/bash
set -e

# Version to install
FLUTTER_VERSION="3.29.0"

echo "Downloading Flutter..."
git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Building web app..."
cd frontend
flutter pub get
flutter build web --release

echo "Build complete!"
