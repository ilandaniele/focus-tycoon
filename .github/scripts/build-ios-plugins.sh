#!/usr/bin/env bash
set -euo pipefail

OUT="$PWD/ios/plugins"
WORK="$RUNNER_TEMP/ios-plugins"
HEADERS="$WORK/godot-headers.zip"
mkdir -p "$OUT" "$WORK"

download_headers() {
  local tag="${GODOT_VERSION}-stable"
  curl -fsSL -o "$HEADERS" \
    "https://github.com/godot-mobile-plugins/godot-headers/releases/download/${tag}/godot-headers-${tag}.zip"
}

build_notification_scheduler() {
  local src="$WORK/notification-scheduler"
  git clone --depth 1 --branch "$NOTIFICATION_PLUGIN_REF" \
    https://github.com/godot-mobile-plugins/godot-notification-scheduler.git "$src"
  printf 'godotVersion=%s\ngodotReleaseType=stable\n' "$GODOT_VERSION" > "$src/common/config/godot.properties"
  local gradle_file="$src/ios/ios-build.gradle.kts"
  local sdk_arg='addAll(listOf("-sdk", sdk))'
  local sim_arch="if (sdk == \"iphonesimulator\") add(\"ARCHS=$(uname -m)\")"
  sed -i '' "s|$sdk_arg|$sdk_arg; $sim_arch|" "$gradle_file"
  grep -qF "$sim_arch" "$gradle_file"
  (cd "$src/common" && ./gradlew --no-daemon \
    buildiOSDebug buildiOSRelease buildiOSDebugSimulator buildiOSReleaseSimulator copyiOSBuildArtifacts)
  local gdip
  gdip=$(find "$src" -name NotificationSchedulerPlugin.gdip -path "*/ios/plugins/*" | head -n 1)
  cp -R "$(dirname "$gdip")"/. "$OUT"/
}

archive_storekit() {
  local src="$1" config="$2" platform="$3" archive="$4"
  xcodebuild archive -project "$src/godot-storekit2.xcodeproj" -scheme godot-storekit2 \
    -configuration "$config" -destination "generic/platform=$platform" \
    -archivePath "$archive" SKIP_INSTALL=NO | tail -n 20
}

build_storekit() {
  local src="$WORK/storekit2"
  git clone https://github.com/godot-sdk-integrations/godot-storekit2.git "$src"
  git -C "$src" checkout "$STOREKIT_PLUGIN_REF"
  mkdir -p "$src/godot"
  unzip -q "$HEADERS" -d "$src/godot"
  local swift_file="$src/godot-storekit2/GodotStoreKit2Swift.swift"
  perl -0pi -e 's/if #available\(iOS 18\.4, \*\) \{.*?\} else \{/do {/s' "$swift_file"
  if grep -q "currentEntitlements" "$swift_file"; then exit 1; fi
  for config in Debug Release; do
    local device="$WORK/storekit-$config-device.xcarchive"
    local simulator="$WORK/storekit-$config-simulator.xcarchive"
    local variant
    archive_storekit "$src" "$config" "iOS" "$device"
    archive_storekit "$src" "$config" "iOS Simulator" "$simulator"
    variant=$(echo "$config" | tr '[:upper:]' '[:lower:]')
    xcodebuild -create-xcframework \
      -library "$(find "$device" -name "*.a" | head -n 1)" \
      -library "$(find "$simulator" -name "*.a" | head -n 1)" \
      -output "$OUT/godot-storekit2.$variant.xcframework"
  done
  cp "$src/godot-storekit2/godot-storekit2.gdip" "$OUT/"
}

download_headers
build_notification_scheduler
build_storekit
find "$OUT" -maxdepth 3 -name "*.a" -exec lipo -info {} \;
ls "$OUT"
