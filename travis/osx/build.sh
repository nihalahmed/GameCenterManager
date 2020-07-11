#!/bin/bash
set -ev
ROOT=${TRAVIS_BUILD_DIR:-"$( cd "$(dirname "$0")/../.." ; pwd -P )"}
echo "**** Building - OSX GameCenterManager Example Project ****"
xcodebuild -configuration Release -target "GameCenterManager Mac" -project "$ROOT/GameCenterManager.xcodeproj"

