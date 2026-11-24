#!/bin/zsh
# Готує ОКРЕМИЙ симулятор для контенту Instagram: свіжий додаток, майстер без імені («Доброго дня, Майстер»),
# українські демо-дані (MarketingDemoDataSeeder), мова — українська, статус-бар 9:41.
#
# Робочі симулятори розробки (iPhone 17 DDF7BD9E, iPhone 17 Pro Max 5000E35E) не чіпаються.
#
# Запуск з кореня проєкту:   zsh docs/marketing/prepare-simulator.sh
# Інший симулятор:           SIM_ID=<udid> zsh docs/marketing/prepare-simulator.sh
# Темний вигляд:             APPEARANCE=dark zsh docs/marketing/prepare-simulator.sh
# Інша мова додатку:         LANG_CODE=en zsh docs/marketing/prepare-simulator.sh

set -e

SIM_ID="${SIM_ID:-14A7411F-1492-4A4C-8F2A-5E35FA937273}"   # iPhone 17 Pro — тільки для контенту
BUNDLE_ID="Kiryk.BeautyCRM"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DD="${DERIVED_DATA:-${TMPDIR:-/tmp}/beautycrm-marketing-dd}"
DEST="platform=iOS Simulator,id=$SIM_ID"

cd "$ROOT"

xcrun simctl boot "$SIM_ID" 2>/dev/null || true
xcrun simctl bootstatus "$SIM_ID" -b
xcrun simctl uninstall "$SIM_ID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl ui "$SIM_ID" appearance "${APPEARANCE:-light}"
xcrun simctl status_bar "$SIM_ID" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3

xcodebuild -project BeautyCRM.xcodeproj -scheme BeautyCRM -destination "$DEST" \
  -derivedDataPath "$DD" build-for-testing -quiet

run() {
  xcodebuild -project BeautyCRM.xcodeproj -scheme BeautyCRM -destination "$DEST" \
    -derivedDataPath "$DD" -parallel-testing-enabled NO test-without-building "$@" -quiet
}

# 1. Реєстрація майстра через UI (тест працює лише з AUDIT_SHOTS; скріни тут не потрібні)
TEST_RUNNER_AUDIT_SHOTS="${TMPDIR:-/tmp}/beautycrm-marketing-register" \
  run -only-testing:BeautyCRMUITests/ScreenshotTourTests/test01_RegisterMaster

# Вхід без сервера на цьому симуляторі: демо-майстер — локальний акаунт (лише Debug-збірка)
xcrun simctl spawn "$SIM_ID" defaults write "$BUNDLE_ID" localAuth -bool YES

# 2. Українські демо-дані
TEST_RUNNER_MARKETING_SEED=1 TEST_RUNNER_MARKETING_LANG="${LANG_CODE:-uk}" run -only-testing:BeautyCRMTests/MarketingDemoDataSeeder

# 3. Доступ до фото (мову задає профіль майстрині — LANG_CODE)
xcrun simctl terminate "$SIM_ID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl privacy "$SIM_ID" grant photos "$BUNDLE_ID" 2>/dev/null || true

# 4. Відкрити додаток. Запит на сповіщення iPhone покаже один раз — натиснути «Дозволити»
xcrun simctl launch "$SIM_ID" "$BUNDLE_ID" >/dev/null
echo "Готово: симулятор $SIM_ID, майстер «Майстер», демо-дані українською."
echo "Додаток: $DD/Build/Products/Debug-iphonesimulator/BeautyCRM.app"
