#!/bin/bash
set -e

echo "🏷️  Checking for skip labels..."

if [ "$GITHUB_EVENT_NAME" != "pull_request" ]; then
  echo "Not a pull request - proceeding with translation"
  echo "skip=false" >> $GITHUB_OUTPUT
  exit 0
fi

PR_NUMBER=$(jq -r .number "$GITHUB_EVENT_PATH")
if [ "$PR_NUMBER" = "null" ]; then
  echo "Could not determine PR number - proceeding with translation"
  echo "skip=false" >> $GITHUB_OUTPUT
  exit 0
fi

echo "Fetching PR labels for #$PR_NUMBER..."
PR_DATA=$(curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER")

if [ $? -ne 0 ] || [ -z "$PR_DATA" ]; then
  echo "Failed to fetch PR data - proceeding with translation"
  echo "skip=false" >> $GITHUB_OUTPUT
  exit 0
fi

LABELS=$(echo "$PR_DATA" | jq -r '.labels[]?.name // empty' 2>/dev/null || echo "")

IFS=',' read -ra SKIP_LABEL_ARRAY <<< "$SKIP_LABELS"

for label in $LABELS; do
  for skip_label in "${SKIP_LABEL_ARRAY[@]}"; do
    skip_label=$(echo "$skip_label" | tr -d ' ')  # Remove spaces
    if [ "$label" = "$skip_label" ]; then
      echo "⏭️  Skipping translation due to label: $label"
      echo "skip=true" >> $GITHUB_OUTPUT
      echo "skip_reason=Label '$label' found on PR" >> $GITHUB_OUTPUT
      exit 0
    fi
  done
done

echo "✅ No skip labels found - proceeding with translation"
echo "skip=false" >> $GITHUB_OUTPUT
