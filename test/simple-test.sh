#!/bin/bash
set -e

echo "LocalHero Action - Simple Test Suite"

export GITHUB_OUTPUT="/tmp/localhero_test_output"
export GITHUB_REPOSITORY="test/localhero-action"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION_ROOT="$(dirname "$SCRIPT_DIR")"
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

cleanup() {
    cd /
    rm -rf "$TEMP_DIR"
    rm -f "$GITHUB_OUTPUT"
}
trap cleanup EXIT

pass() {
    echo "✅ $1"
}

fail() {
    echo "❌ $1"
}

run_framework_detection() {
    local framework_name=$1
    local setup_command=$2
    local expected_framework=$3
    local expected_pattern=$4

    mkdir -p "test-$framework_name"
    cd "test-$framework_name"

    eval "$setup_command"

    export INPUT_FRAMEWORK="auto"
    export INPUT_CREATE_CONFIG="true"
    export INPUT_SOURCE_LOCALE="en"
    export INPUT_TARGET_LOCALES="es,fr"

    echo "" > "$GITHUB_OUTPUT"
    "$ACTION_ROOT/scripts/detect-framework.sh" >/dev/null 2>&1

    framework=$(grep "^framework=" "$GITHUB_OUTPUT" | cut -d'=' -f2)
    pattern=$(grep "^file_pattern=" "$GITHUB_OUTPUT" | cut -d'=' -f2)
    config_created=$(grep "^config_created=" "$GITHUB_OUTPUT" | cut -d'=' -f2)

    if [ "$framework" != "$expected_framework" ]; then
        fail "Framework: $framework (expected: $expected_framework)"
        return 1
    fi

    if [ "$config_created" != "true" ] || [ ! -f "localhero.json" ]; then
        fail "Config file not created"
        return 1
    fi

    if ! jq '.' localhero.json >/dev/null 2>&1; then
        fail "Invalid JSON config"
        return 1
    fi

    source_locale=$(jq -r '.sourceLocale' localhero.json)
    output_locales=$(jq -r '.outputLocales | join(",")' localhero.json)

    if [ "$source_locale" != "en" ] || [ "$output_locales" != "es,fr" ]; then
        fail "Config content incorrect: source=$source_locale, targets=$output_locales"
        return 1
    fi

    cd ..
    pass "$framework_name"
    return 0
}

test_skip_labels() {
    export GITHUB_EVENT_NAME="push"
    echo "" > "$GITHUB_OUTPUT"

    "$ACTION_ROOT/scripts/check-skip-labels.sh" >/dev/null 2>&1

    skip=$(grep "^skip=" "$GITHUB_OUTPUT" | cut -d'=' -f2)
    if [ "$skip" != "false" ]; then
        fail "Non-PR events should not skip"
        return 1
    fi

    pass "Skip labels"
    return 0
}

run_framework_detection "Rails" \
    'echo "gem \"rails\"" > Gemfile; mkdir -p config/locales' \
    "rails" \
    "config/locales/**/*.yml"

run_framework_detection "Next.js" \
    'echo "{\"dependencies\": {\"next\": \"^13.0.0\"}}" > package.json; mkdir -p public/locales/en' \
    "nextjs" \
    "public/locales/**/*.json"

run_framework_detection "React" \
    'echo "{\"dependencies\": {\"react\": \"^18.0.0\"}}" > package.json; mkdir -p src/i18n' \
    "react" \
    "src/i18n/**/*.json"

run_framework_detection "Generic" \
    'mkdir -p translations; echo "{\"test\": \"value\"}" > translations/en.json' \
    "generic" \
    "**/*.json"

test_skip_labels

echo ""
echo "🎉 All tests passed!"
