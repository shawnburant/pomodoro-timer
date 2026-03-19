#!/bin/bash
set -e

APP_NAME="PomodoroTimer"
SCHEME="PomodoroTimer"
INSTALL_DIR="/Applications"

echo "Building $APP_NAME (Release)..."
xcodebuild -scheme "$SCHEME" -configuration Release clean build \
    -derivedDataPath build/

APP_PATH=$(find build/ -name "$APP_NAME.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "Error: could not find built app" >&2
    exit 1
fi

echo "Installing to $INSTALL_DIR/$APP_NAME.app..."
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "$APP_PATH" "$INSTALL_DIR/"

echo "Killing any running instance..."
pkill -x "$APP_NAME" 2>/dev/null || true

echo "Launching..."
open "$INSTALL_DIR/$APP_NAME.app"

echo "Done. $APP_NAME is running from $INSTALL_DIR."
