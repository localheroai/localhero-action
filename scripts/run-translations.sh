#!/bin/bash
set -e

echo "🌍 Running LocalHero translations..."

if [ -z "$LOCALHERO_API_KEY" ]; then
  echo "❌ No API key available"
  echo "translations_processed=0" >> $GITHUB_OUTPUT
  exit 1
fi

if ! command -v npm &> /dev/null; then
  echo "❌ npm not found. Node.js is required."
  echo "translations_processed=0" >> $GITHUB_OUTPUT
  exit 1
fi

if [ ! -f "localhero.json" ]; then
  echo "❌ localhero.json configuration file not found"
  echo "translations_processed=0" >> $GITHUB_OUTPUT
  exit 1
fi

echo "📋 Current LocalHero configuration:"
cat localhero.json | jq '.' || echo "⚠️  Invalid JSON in localhero.json"

if [ -n "$LOCALHERO_API_HOST" ]; then
  echo "🔧 Using custom API host: $LOCALHERO_API_HOST"
fi

echo "🚀 Executing translation..."
npx -y @localheroai/cli translate

echo "translations_processed=1" >> $GITHUB_OUTPUT
