#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"
cd ..

readonly SCHEME="Capstone"
readonly DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/${SCHEME}-derived}"
readonly MODULE_CACHE_PATH="${MODULE_CACHE_PATH:-/tmp/${SCHEME}-module-cache}"
readonly XCODEBUILD_COMMON_ARGS=(
  -scheme "${SCHEME}"
  -derivedDataPath "${DERIVED_DATA_PATH}"
  CODE_SIGN_IDENTITY=""
  CODE_SIGNING_REQUIRED=NO
  CODE_SIGNING_ALLOWED=NO
)

export HOME="${HOME:-/tmp}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-${MODULE_CACHE_PATH}}"
export SWIFTPM_MODULECACHE_OVERRIDE="${SWIFTPM_MODULECACHE_OVERRIDE:-${MODULE_CACHE_PATH}}"

run_xcodebuild() {
  local action="$1"
  local destination="$2"

  echo "[*] ${action} for ${destination}"

  if command -v xcbeautify >/dev/null 2>&1; then
    set -o pipefail
    xcodebuild "${action}" "${XCODEBUILD_COMMON_ARGS[@]}" -destination "${destination}" | xcbeautify --disable-logging
    local exit_code=${PIPESTATUS[0]}
    set +o pipefail
    if [[ ${exit_code} -ne 0 ]]; then
      echo "[!] ${action} failed for ${destination}"
      exit "${exit_code}"
    fi
  else
    xcodebuild "${action}" "${XCODEBUILD_COMMON_ARGS[@]}" -destination "${destination}"
  fi
}

run_xcodebuild build "generic/platform=macOS"
run_xcodebuild build "generic/platform=macOS,variant=Mac Catalyst"
run_xcodebuild build "generic/platform=iOS"
run_xcodebuild build "generic/platform=iOS Simulator"
run_xcodebuild build "generic/platform=tvOS"
run_xcodebuild build "generic/platform=tvOS Simulator"
run_xcodebuild build "generic/platform=watchOS"
run_xcodebuild build "generic/platform=watchOS Simulator"
run_xcodebuild build "generic/platform=xrOS"
run_xcodebuild build "generic/platform=xrOS Simulator"
run_xcodebuild test "platform=macOS"
