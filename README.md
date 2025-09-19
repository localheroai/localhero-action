# LocalHero AI Translation GitHub Action

> 🌍 **AI Translation in Every Push** — Zero-config, automatic, professional translations.

Add professional AI-powered translation to GitHub repositories.

## ✨ Features

- **🚀 Instant Trials** Automatically creates LocalHero trial accounts using your GitHub identity, if needed
- **🎯 Smart Framework Detection** Works with Rails, Next.js, React, and more
- **📝 Auto Config Generation** Detects project structure and creates settings
- **🏷️ Label-Based Control** Skip translation using PR labels like `skip-translation`
- **⚡ Zero Setup Required** Just add the action and run

## 🚀 Quick Start

### Basic Usage (Recommended)

```yaml
name: Translate
on: [push, pull_request]

jobs:
  translate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: localhero-ai/translate-action@v1
        with:
          target-locales: 'es,fr,de,ja'
```

That's it! The action will:
1. ✅ Detect your framework (Rails/Next.js/React)
2. ✅ Generate configuration files
3. ✅ Translate any keys missing translations

Further customization is done at https://localhero.ai by signing in with your GitHub account.

### Examples

#### Ruby on Rails
```yaml
- uses: localhero-ai/translate-action@v1
  with:
    target-locales: 'es,fr,de,it,pt,nl'
    file-pattern: 'config/locales/**/*.yml'
    file-format: 'yaml'
```

#### Next.js
```yaml
- uses: localhero-ai/translate-action@v1
  with:
    target-locales: 'de,nl,sv,no,da,fi'
    file-pattern: 'public/locales/**/*.json'
    framework: 'nextjs'
```

#### React
```yaml
- uses: localhero-ai/translate-action@v1
  with: source-locale: `no`
    target-locales: 'zh,ja,ko,hi'
    file-pattern: 'src/i18n/**/*.json'
    framework: 'react'
```

### Source and target locales

Use locale codes exactly as they appear in your file paths (case, separators, and regions must match):

**Examples:**
- Rails: `config/locales/en.yml` → `en`
- React (i18next): `locales/en_GB.json` → `en_GB`
- Next.js: `public/locales/en-US/common.json` → `en-US`
- Single files per locale: `de.json`, `fr.json`, `es.json` → `de,fr,es`
- Region-specific: `fr-CA.json`, `es-MX.json`, `de-AT.json` → `fr-CA,es-MX,de-AT`
- Directory per locale: `/locales/ja/...`, `/locales/zh/...` → `ja,zh`

Notes:
- Use the same separator your app uses (`en-US` vs `en_US`).
- Whitespace is ignored in comma-separated lists (`en, fr, de` works).

## 📋 Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `api_key` | LocalHero API key (leave empty for instant trial) | ❌ | - |
| `source_locale` | Source language code | ❌ | `en` |
| `target_locales` | Comma-separated target languages | ❌ | `es,fr,de` |
| `file_pattern` | Glob pattern for translation files | ❌ | Auto-detected |
| `file_format` | File format: `json`, `yaml`, or `auto` | ❌ | `auto` |
| `framework` | Framework preset: `rails`, `nextjs`, `react`, `auto` | ❌ | `auto` |
| `skip_labels` | PR labels that skip translation | ❌ | `skip-translation,no-translate,wip` |
| `create_config` | Create localhero.json if missing | ❌ | `true` |

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `api_key` | The API key used (masked in logs) |
| `organization_id` | LocalHero organization ID |
| `project_id` | LocalHero project ID |
| `is_new_user` | Whether this created a new trial user |
| `trial_days_remaining` | Days remaining in trial |
| `config_created` | Whether localhero.json was created |
| `translations_processed` | Number of translations processed |
| `skip_reason` | Reason translation was skipped (if applicable) |

## 🎛️ Skipping translations

Add any of these labels to your PR to skip translation:
- `skip-translation`
- `no-translate`
- `wip`


### Using Existing API Key

If you have an existing LocalHero account:

```yaml
- uses: localhero-ai/translate-action@v1
  env:
    LOCALHERO_API_KEY: ${{ secrets.LOCALHERO_API_KEY }}
```

Requires that the `LOCALHERO_API_KEY` repository secret is set.
You set the secret in the repository settings under `Settings > Secrets and variables > Actions`.

## 🆘 Troubleshooting

### Action Fails with "Invalid GitHub token"
- The GitHub token needs `repo` permissions
- Make sure you're using the standard `github.token`

### No translations generated
- Check that your file pattern matches existing files
- Verify the source files contain translatable content
- Look at the action logs for specific error messages


## 🔗 Links

- [LocalHero.ai](https://localhero.ai) - Main website
- [CLI Tool](https://github.com/localheroai/cli) - Command line interface
- [Support](mailto:hi@localhero.ai) - Get help
