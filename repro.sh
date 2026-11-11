#!/usr/bin/env bash
# Builds ReproducerApp's release APK, installs and opens it on the Android device adb reaches (ANDROID_SERIAL picks
# one), taps its button, and reads what each commit put on screen from logcat. Exit 1 while a commit shows
# useColorScheme() and Appearance.getColorScheme() disagreeing after Appearance.setColorScheme, 0 once none does,
# 2 when a step fails first.
set -uo pipefail

fail() {
  echo "RESULT: step failed: $1"
  exit 2
}

package=com.reproducerapp
cd "$(dirname "${BASH_SOURCE[0]}")/ReproducerApp" || fail "cd ReproducerApp"
yarn install --frozen-lockfile --silent > /dev/null 2>&1 || fail "yarn install"
react_native=$(node -p 'require("react-native/package.json").version') || fail "reading react-native's version"
model=$(adb shell getprop ro.product.model | tr -d '\r') || fail "adb shell getprop"
android=$(adb shell getprop ro.build.version.release | tr -d '\r') || fail "adb shell getprop"
echo "react-native ${react_native}, release build, ${model}, Android ${android}"
build_log=$(mktemp) || fail "mktemp"
(cd android && ./gradlew assembleRelease --quiet > "${build_log}" 2>&1) || {
  tail -n 20 "${build_log}"
  fail "gradlew assembleRelease"
}
adb install -r android/app/build/outputs/apk/release/app-release.apk > /dev/null || fail "adb install"
adb shell am force-stop "${package}" || fail "am force-stop"
adb logcat -c || fail "adb logcat -c"
adb shell am start -W -n "${package}/.MainActivity" > /dev/null || fail "am start"
timeout 120 adb logcat -s ReactNativeJS:I -e '\[repro\] ready' -m 1 > /dev/null || fail "the app logged no ready line"
size=$(adb shell wm size | tr -d '\r' | sed -n 's/^Physical size: \([0-9]*\)x\([0-9]*\)$/\1 \2/p') || fail "adb shell wm size"
read -r width height <<< "${size}"
[[ -n "${width}" && -n "${height}" ]] || fail "reading the screen size"
adb shell input tap "$((width / 2))" "$((height * 2 / 3))" || fail "adb shell input tap"
timeout 30 adb logcat -s ReactNativeJS:I -e 'change listener' -m 1 > /dev/null || fail "no change listener ran within 30 s of the press"
lines=$(adb logcat -d -s ReactNativeJS:I | tr -d '\r' | sed -n 's/^.*ReactNativeJS: \[repro\] //p') || fail "adb logcat -d"
adb shell am force-stop "${package}" || fail "am force-stop"
echo "${lines}"
after_press=$(sed -n '/^press 1:/,$p' <<< "${lines}")
[[ -n "${after_press}" ]] || fail "the tap logged no press"
if grep -q '(DISAGREE)$' <<< "${after_press}"; then
  echo "RESULT: defect shows: after Appearance.setColorScheme a commit shows useColorScheme() and Appearance.getColorScheme() disagreeing, until the change listener runs"
  exit 1
fi
grep -q 'committed:' <<< "${after_press}" || fail "no commit after the press"
echo "RESULT: fixed: every commit after the press shows the two readers agreeing"
exit 0
