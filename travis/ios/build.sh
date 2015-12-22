#!/bin/bash
set -ev
echo "**** Building - iOS GameCenterManager Example Project ****"
ROOT=${TRAVIS_BUILD_DIR:-"$( cd "$(dirname "$0")/../.." ; pwd -P )"}
xcodebuild -project "$ROOT/GameCenterManager.xcodeproj"  -target GameCenterManager -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO

