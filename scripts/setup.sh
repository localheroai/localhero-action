#!/bin/bash
set -e

echo "🚀 Setting up LocalHero environment..."

if [ "$MOCK_MODE" = "true" ]; then
  echo "🎭 Running in mock mode for testing"
  echo "::add-mask::mock_api_key_12345"
  echo "api_key=mock_api_key_12345" >> $GITHUB_OUTPUT
  echo "organization_id=1" >> $GITHUB_OUTPUT
  echo "project_id=1" >> $GITHUB_OUTPUT
  echo "is_new_user=true" >> $GITHUB_OUTPUT
  echo "trial_days_remaining=30" >> $GITHUB_OUTPUT
  echo "✅ Mock trial account created successfully!"
  exit 0
fi

if [ -n "$INPUT_API_KEY" ]; then
  echo "Using provided API key"
  echo "::add-mask::$INPUT_API_KEY"
  echo "api_key=$INPUT_API_KEY" >> $GITHUB_OUTPUT
  echo "is_new_user=false" >> $GITHUB_OUTPUT
  echo "trial_days_remaining=0" >> $GITHUB_OUTPUT
  exit 0
fi

echo "🎯 Setting up LocalHero access..."

if [ -n "$LOCALHERO_API_HOST" ]; then
  API_BASE_URL="$LOCALHERO_API_HOST"
else
  API_BASE_URL="https://localhero.ai"
fi

API_URL="$API_BASE_URL/api/v1/github/instant-trial"
REQUEST_BODY=$(jq -n --arg repo "$GITHUB_REPOSITORY" '{repository: $repo}')
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "User-Agent: LocalHero-GitHub-Action/1.0" \
  -d "$REQUEST_BODY" \
  "$API_URL")

HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$RESPONSE" | head -n -1)

echo "API Response Status: $HTTP_STATUS"

if [ "$HTTP_STATUS" != "201" ]; then
  echo "❌ Failed to set up LocalHero access"
  echo "Response: $RESPONSE_BODY"
  exit 1
fi

echo "✅ LocalHero access configured successfully!"

API_KEY=$(echo "$RESPONSE_BODY" | jq -r '.api_key')
ORGANIZATION_ID=$(echo "$RESPONSE_BODY" | jq -r '.organization_id')
PROJECT_ID=$(echo "$RESPONSE_BODY" | jq -r '.project_id')
IS_NEW_USER=$(echo "$RESPONSE_BODY" | jq -r '.is_new_user')
TRIAL_DAYS_REMAINING=$(echo "$RESPONSE_BODY" | jq -r '.trial_days_remaining')

echo "::add-mask::$API_KEY"

echo "api_key=$API_KEY" >> $GITHUB_OUTPUT
echo "organization_id=$ORGANIZATION_ID" >> $GITHUB_OUTPUT
echo "project_id=$PROJECT_ID" >> $GITHUB_OUTPUT
echo "is_new_user=$IS_NEW_USER" >> $GITHUB_OUTPUT
echo "trial_days_remaining=$TRIAL_DAYS_REMAINING" >> $GITHUB_OUTPUT

if [ "$IS_NEW_USER" = "true" ]; then
  echo "🎉 Welcome to LocalHero! Your trial account has been created."
  echo "📅 Trial period: $TRIAL_DAYS_REMAINING days remaining"
fi
