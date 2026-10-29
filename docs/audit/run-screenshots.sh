#!/bin/zsh
# Знімає скріншоти всіх екранів у 3 темах (docs/audit/screenshots/<тема>/).
# Працює на ОКРЕМОМУ чистому симуляторі: додаток там видаляється й ставиться заново.
# Симулятор з робочими даними (iPhone 17 Pro Max) не чіпається.
#
# Запуск з кореня проєкту:  zsh docs/audit/run-screenshots.sh

set -e

SIM_ID="${SIM_ID:-794A68D9-0076-4FDC-8EFC-2967B5F417A4}"   # чистий iPhone 17
BUNDLE_ID="Kiryk.BeautyCRM"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SHOTS="$ROOT/docs/audit/screenshots"
DD="${DERIVED_DATA:-${TMPDIR:-/tmp}/beautycrm-audit-dd}"
DEST="platform=iOS Simulator,id=$SIM_ID"

cd "$ROOT"

xcrun simctl boot "$SIM_ID" 2>/dev/null || true
xcrun simctl bootstatus "$SIM_ID" -b
xcrun simctl uninstall "$SIM_ID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl ui "$SIM_ID" appearance light
xcrun simctl status_bar "$SIM_ID" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3

rm -rf "$SHOTS"
mkdir -p "$SHOTS"

xcodebuild -project BeautyCRM.xcodeproj -scheme BeautyCRM -destination "$DEST" \
  -derivedDataPath "$DD" build-for-testing -quiet

run() {
  xcodebuild -project BeautyCRM.xcodeproj -scheme BeautyCRM -destination "$DEST" \
    -derivedDataPath "$DD" -parallel-testing-enabled NO \
    test-without-building "$@"
}

# 1. Реєстрація майстра через UI
TEST_RUNNER_AUDIT_SHOTS="$SHOTS" run -only-testing:BeautyCRMUITests/ScreenshotTourTests/test01_RegisterMaster

# 2. Демо-дані (вигадані клієнти, послуги, записи)
TEST_RUNNER_AUDIT_SEED=1 run -only-testing:BeautyCRMTests/AuditDemoDataSeeder

# 3. Обхід екранів у кожній темі
TEST_RUNNER_AUDIT_SHOTS="$SHOTS" run \
  -only-testing:BeautyCRMUITests/ScreenshotTourTests/test02_TourClassic \
  -only-testing:BeautyCRMUITests/ScreenshotTourTests/test03_TourGraphite \
  -only-testing:BeautyCRMUITests/ScreenshotTourTests/test04_TourPearlIvory

# 4. Те саме в темному режимі iPhone (теми задають кольори частково, тож перевіряємо змішування)
xcrun simctl ui "$SIM_ID" appearance dark
TEST_RUNNER_AUDIT_SHOTS="$SHOTS" TEST_RUNNER_AUDIT_SUFFIX="-dark" run \
  -only-testing:BeautyCRMUITests/ScreenshotTourTests/test02_TourClassic \
  -only-testing:BeautyCRMUITests/ScreenshotTourTests/test03_TourGraphite \
  -only-testing:BeautyCRMUITests/ScreenshotTourTests/test04_TourPearlIvory
xcrun simctl ui "$SIM_ID" appearance light

xcrun simctl status_bar "$SIM_ID" clear
echo "Готово: $SHOTS"
