#!/bin/bash
set -e

# Version to install
FLUTTER_VERSION="3.29.0"

echo "Downloading Flutter..."
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
else
  echo "Flutter already exists, skipping clone."
fi
export PATH="$PATH:$HOME/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Building web app..."
cd frontend
flutter pub get
flutter build web --release --dart-define=API_URL="$API_URL"

echo "Build complete!"
