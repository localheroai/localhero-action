#!/bin/bash
set -e

echo "🔍 Detecting project framework and configuration..."

INPUT_FRAMEWORK="${INPUT_FRAMEWORK:-auto}"
INPUT_FILE_PATTERN="${INPUT_FILE_PATTERN:-}"
INPUT_FILE_FORMAT="${INPUT_FILE_FORMAT:-auto}"
INPUT_SOURCE_LOCALE="${INPUT_SOURCE_LOCALE:-en}"
INPUT_TARGET_LOCALES="${INPUT_TARGET_LOCALES:-es,fr,de}"
INPUT_CREATE_CONFIG="${INPUT_CREATE_CONFIG:-true}"

DETECTED_FRAMEWORK=""
DETECTED_PATTERN=""
DETECTED_FORMAT=""
PROJECT_ID=""
CONFIG_CREATED="false"

detect_framework() {
  if [ "$INPUT_FRAMEWORK" != "auto" ]; then
    DETECTED_FRAMEWORK="$INPUT_FRAMEWORK"
    echo "📋 Using specified framework: $DETECTED_FRAMEWORK"
    return 0
  fi

  echo "🕵️  Auto-detecting framework..."

  # Check for Rails
  if [ -f "Gemfile" ] && grep -q "rails" Gemfile; then
    DETECTED_FRAMEWORK="rails"
    echo "🚂 Detected Ruby on Rails project"
    return 0
  fi

  # Check for React/Next.js projects
  if [ -f "package.json" ] && grep -q '"react"' package.json; then
    DETECTED_FRAMEWORK="react"
    if grep -q '"next"' package.json || [ -f "next.config.js" ] || [ -f "next.config.ts" ]; then
      echo "⚛️  Detected React project (Next.js)"
    else
      echo "⚛️  Detected React project"
    fi
    return 0
  fi

  DETECTED_FRAMEWORK="generic"
  echo "📦 Using generic configuration"

  detect_existing_translation_files
}

detect_existing_translation_files() {
  echo "🔍 Scanning for existing translation files..."

  # Find JSON/YAML translation files (officially supported formats)
  TRANSLATION_FILES=$(find . -name "*.json" -o -name "*.yml" -o -name "*.yaml" 2>/dev/null | head -20)

  if [ -z "$TRANSLATION_FILES" ]; then
    echo "ℹ️  No existing translation files found"
    provide_setup_guidance
    return 0
  fi

  COMMON_DIRS=$(echo "$TRANSLATION_FILES" | sed 's|/[^/]*$||' | sort | uniq -c | sort -nr | head -3)

  if echo "$COMMON_DIRS" | head -1 | grep -q "translations\|locales\|i18n\|lang"; then
    MOST_COMMON=$(echo "$COMMON_DIRS" | head -1 | awk '{print $2}' | sed 's/^\.//')
    if [ -n "$MOST_COMMON" ]; then
      echo "💡 Found translations in: $MOST_COMMON"
      DETECTED_PATTERN="$MOST_COMMON/**/*.{json,yml,yaml}"
      echo "🎯 Using detected pattern: $DETECTED_PATTERN"
    fi
  fi

  echo "📁 Discovered translation files:"
  echo "$TRANSLATION_FILES" | head -5 | sed 's/^/  /'
  if [ $(echo "$TRANSLATION_FILES" | wc -l) -gt 5 ]; then
    echo "  ... and $(($(echo "$TRANSLATION_FILES" | wc -l) - 5)) more"
  fi

  echo ""
  echo "💡 To optimize detection, you can specify:"
  echo "   file_pattern: 'your/specific/path/*.json'"
  echo "   file_format: 'json' # or 'yaml'"
}

provide_setup_guidance() {
  echo ""
  echo "┌─────────────────────────────────────────────────────────────┐"
  echo "│ 💡 LocalHero Setup Guidance                                │"
  echo "└─────────────────────────────────────────────────────────────┘"
  echo ""
  echo "No translation files were found in your repository."
  echo ""
  echo "📝 What LocalHero does:"
  echo "   • Scans your translation files for missing keys"
  echo "   • Uses AI to translate missing content"
  echo "   • Updates your files with new translations"
  echo "   • Commits changes back to your repository"
  echo ""
  echo "To help LocalHero find your files, please:"
  echo ""
  echo "   Add the 'file_pattern' input to your workflow file (.github/workflows/*):"
  echo ""
  echo "   - uses: localheroai/localhero-action@v1"
  echo "     with:"
  echo "       target-locales: 'es,fr,de'"
  echo "       file-pattern: 'PATH/TO/YOUR/TRANSLATION/FILES'"
  echo ""
  echo "   Common patterns for web frameworks (JSON/YAML):"
  echo ""
  echo "   🌐 Web Frameworks:"
  echo "     • Vue.js: 'src/locales/*.json'"
  echo "     • Angular: 'src/assets/i18n/*.json'"
  echo "     • Django: 'locale/*/LC_MESSAGES/*.json'"
  echo "     • Laravel: 'resources/lang/*.json'"
  echo "     • Symfony: 'translations/*.yaml'"
  echo ""
  echo "   🔧 Generic JSON/YAML:"
  echo "     • JSON files: 'translations/*.json'"
  echo "     • YAML files: 'locales/*.yml'"
  echo "     • Mixed: 'i18n/*.{json,yml}'"
  echo "     • Nested: 'your/custom/path/**/*.json'"
  echo ""
  echo "────────────────────────────────────────────────────────────────"
  echo ""
}

set_framework_defaults() {
  case "$DETECTED_FRAMEWORK" in
    "rails")
      DETECTED_PATTERN="config/locales/**/*.yml"
      DETECTED_FORMAT="yaml"
      ;;
    "react")
      DETECTED_PATTERN="public/locales/**/*.json"
      DETECTED_FORMAT="json"
      ;;
    *)
      if [ -z "$DETECTED_PATTERN" ]; then
        DETECTED_PATTERN="**/*.json"
        echo "⚠️  Using broad pattern '**/*.json' - consider specifying file_pattern input for better performance"
      fi
      DETECTED_FORMAT="json"
      ;;
  esac
}

resolve_configuration() {
  if [ -n "$INPUT_FILE_PATTERN" ]; then
    FILE_PATTERN="$INPUT_FILE_PATTERN"
  else
    FILE_PATTERN="$DETECTED_PATTERN"
  fi

  if [ "$INPUT_FILE_FORMAT" != "auto" ]; then
    FILE_FORMAT="$INPUT_FILE_FORMAT"
  else
    FILE_FORMAT="$DETECTED_FORMAT"
  fi

  echo "📂 File pattern: $FILE_PATTERN"
  echo "📄 File format: $FILE_FORMAT"
  echo "🌍 Source locale: $INPUT_SOURCE_LOCALE"
  echo "🎯 Target locales: $INPUT_TARGET_LOCALES"
}

generate_config() {
  if [ "$INPUT_CREATE_CONFIG" != "true" ]; then
    echo "⏭️  Config file creation disabled"
    return 0
  fi

  if [ -f "localhero.json" ]; then
    echo "📋 localhero.json already exists"
    PROJECT_ID=$(jq -r '.projectId // ""' localhero.json 2>/dev/null || echo "")
    return 0
  fi

  echo "📝 Generating localhero.json configuration file..."

  REPO_NAME=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f2)
  PROJECT_ID="$REPO_NAME"

  TARGET_LOCALES_JSON=$(echo "$INPUT_TARGET_LOCALES" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$"; ""))')

  cat > localhero.json << EOF
{
  "schemaVersion": "1.0",
  "projectId": "$PROJECT_ID",
  "sourceLocale": "$INPUT_SOURCE_LOCALE",
  "outputLocales": $TARGET_LOCALES_JSON,
  "translationFiles": {
    "paths": [
      "$(dirname "$FILE_PATTERN")/"
    ],
    "pattern": "$(basename "$FILE_PATTERN")",
    "ignore": []
  },
  "lastSyncedAt": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"
}
EOF

  CONFIG_CREATED="true"
  echo "✅ Generated localhero.json"
  echo "📁 Project ID: $PROJECT_ID"
}

detect_framework
set_framework_defaults
resolve_configuration
generate_config

echo "framework=$DETECTED_FRAMEWORK" >> $GITHUB_OUTPUT
echo "file_pattern=$FILE_PATTERN" >> $GITHUB_OUTPUT
echo "file_format=$FILE_FORMAT" >> $GITHUB_OUTPUT
echo "project_id=$PROJECT_ID" >> $GITHUB_OUTPUT
echo "config_created=$CONFIG_CREATED" >> $GITHUB_OUTPUT

echo "🎯 Framework detection completed: $DETECTED_FRAMEWORK"
