#!/usr/bin/env bash
# Fails the build when a built APK/AAB does not carry pubspec.yaml's version.
#
# The profile screen's "SRIBEES V1.2.4 ? SRILANKA" is the INSTALLED build's
# versionName (PackageInfo), and Play lists the same versionName/versionCode.
# Both come from `version:` in pubspec.yaml unless a build passes
# --build-name / --build-number. This check proves, for every build, that the
# number in the code, the number in the file and the number the customer sees
# are one number (owner, 2026-11-04).
#
# Usage: scripts/verify_build_version.sh <app.apk> [<app.aab>]
set -euo pipefail

apk="${1:?usage: verify_build_version.sh <apk> [aab]}"
aab="${2:-}"

full=$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}')
want_name="${full%%+*}"
want_code="${full##*+}"
if [ -z "$want_name" ] || [ "$want_code" = "$full" ]; then
  echo "::error::pubspec.yaml version '$full' is not NAME+CODE (e.g. 1.2.4+14)"
  exit 1
fi
echo "pubspec.yaml: versionName=$want_name versionCode=$want_code"

fail=0
aapt=$(ls "$ANDROID_HOME"/build-tools/*/aapt | tail -1)
badge=$("$aapt" dump badging "$apk" | grep -m1 '^package:')
apk_name=$(echo "$badge" | sed -n "s/.*versionName='\([^']*\)'.*/\1/p")
apk_code=$(echo "$badge" | sed -n "s/.*versionCode='\([^']*\)'.*/\1/p")
echo "APK:          versionName=$apk_name versionCode=$apk_code  ($apk)"
if [ "$apk_name" != "$want_name" ] || [ "$apk_code" != "$want_code" ]; then
  echo "::error::APK is $apk_name+$apk_code but pubspec.yaml says $full ? the profile screen would show the wrong version"
  fail=1
fi

if [ -n "$aab" ]; then
  jar="${RUNNER_TEMP:-/tmp}/bundletool.jar"
  [ -f "$jar" ] || curl -fsSL -o "$jar" \
    https://github.com/google/bundletool/releases/download/1.17.2/bundletool-all-1.17.2.jar
  aab_name=$(java -jar "$jar" dump manifest --bundle "$aab" --xpath /manifest/@android:versionName)
  aab_code=$(java -jar "$jar" dump manifest --bundle "$aab" --xpath /manifest/@android:versionCode)
  echo "AAB:          versionName=$aab_name versionCode=$aab_code  ($aab)"
  if [ "$aab_name" != "$want_name" ] || [ "$aab_code" != "$want_code" ]; then
    echo "::error::AAB is $aab_name+$aab_code but pubspec.yaml says $full ? Play would list the wrong version"
    fail=1
  fi
fi

[ "$fail" = 0 ] && echo "OK: every artifact is $full ? code, Play and the profile screen agree"
exit "$fail"
