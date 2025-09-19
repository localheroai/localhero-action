#!/bin/bash
set -e

echo ""
echo "📋 LocalHero Action Summary"
echo "=========================="

if [ -n "$SKIP_REASON" ] && [ "$SKIP_REASON" != "" ]; then
  echo "⏭️  Status: Skipped"
  echo "📝 Reason: $SKIP_REASON"
  echo ""
  echo "To run translations on this PR, remove the skip label and re-run the workflow."

  echo "skip_reason=$SKIP_REASON" >> $GITHUB_OUTPUT
  exit 0
fi

echo "✅ Status: Completed"

if [ -n "$IS_NEW_USER" ] && [ "$IS_NEW_USER" = "true" ]; then
  echo "🎉 New trial account created!"
  echo "📧 Check your email for LocalHero account details"
fi

if [ -n "$TRIAL_DAYS_REMAINING" ] && [ "$TRIAL_DAYS_REMAINING" -gt 0 ]; then
  echo "📅 Trial: $TRIAL_DAYS_REMAINING days remaining"
fi

if [ -n "$CONFIG_CREATED" ] && [ "$CONFIG_CREATED" = "true" ]; then
  echo "📝 Created localhero.json configuration file"
fi

if [ -n "$TRANSLATIONS_PROCESSED" ]; then
  echo "🌍 Processed: $TRANSLATIONS_PROCESSED translations"
fi

echo ""

if [ -n "$IS_NEW_USER" ] && [ "$IS_NEW_USER" = "true" ]; then
  echo "🔗 Next Steps:"
  echo "• Visit https://localhero.ai to manage your translations"
  echo "• Review and customize your project settings"
  echo "• Add team members to your organization"
elif [ -n "$TRIAL_DAYS_REMAINING" ] && [ "$TRIAL_DAYS_REMAINING" -gt 0 ]; then
  echo "🔗 Manage your translations at https://localhero.ai"
fi

echo "api_key=$API_KEY" >> $GITHUB_OUTPUT
echo "organization_id=$ORGANIZATION_ID" >> $GITHUB_OUTPUT  
echo "project_id=$PROJECT_ID" >> $GITHUB_OUTPUT
echo "is_new_user=$IS_NEW_USER" >> $GITHUB_OUTPUT
echo "trial_days_remaining=$TRIAL_DAYS_REMAINING" >> $GITHUB_OUTPUT
echo "config_created=$CONFIG_CREATED" >> $GITHUB_OUTPUT
echo "translations_processed=$TRANSLATIONS_PROCESSED" >> $GITHUB_OUTPUT

echo ""
