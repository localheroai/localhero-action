# Localhero GitHub Action 🌍

> Translate locale files with AI in CI, on every pull request

The official GitHub Action for [Localhero.ai](https://localhero.ai). It translates the i18n keys that changed in a PR and commits them back to the same PR, so translations stop holding up releases. It knows your glossary and brand terms, preserves ICU placeholders and plural forms, and gives your team a review UI instead of a YAML diff.

Works with the common code-native i18n setups: **react-i18next**, **LinguiJS**, **Rails i18n** (YAML), and **Django / gettext** (`.po`), plus JSON and YAML locale files generally. [Start your free trial](https://localhero.ai) to get automatic translations in your PRs.

## Quick Start 🚀

```yaml
name: Translate with Localhero.ai

on:
  pull_request:
    paths:
      - "locales/**"
      - "localhero.json"
  repository_dispatch:
    types: [localhero-sync]
  workflow_dispatch:

concurrency:
  group: translate-${{ github.event.client_payload.branch || github.head_ref || github.run_id }}
  cancel-in-progress: true

jobs:
  translate:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v5
        with:
          ref: ${{ github.event.client_payload.branch || github.head_ref || github.ref_name }}
          fetch-depth: 0

      - name: Translate
        uses: localheroai/localhero-action@v1
        with:
          api-key: ${{ secrets.LOCALHERO_API_KEY }}
```

That's it! The action will automatically:
- Fetch the base branch for comparison
- Translate missing keys
- Commit the changes to your PR

## Setup 🏁

1. **Sign up** for a free trial at [localhero.ai](https://localhero.ai)
2. **Get your API key** at [localhero.ai/api-keys](https://localhero.ai/api-keys)
3. **Add the secret** to your repository:
   - Go to Settings > Secrets and variables > Actions
   - Create a new secret named `LOCALHERO_API_KEY`
4. **Initialize your project** (if you haven't already):
   ```bash
   npx @localheroai/cli init
   ```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `api-key` | Yes | - | Your Localhero.ai API key |
| `command` | No | `ci` | CLI command: `ci`, `translate`, `push`, `pull` |
| `verbose` | No | `false` | Show detailed output |
| `cli-version` | No | `latest` | Pin CLI version (e.g., `1.2.3`) |
| `skip-labels` | No | `skip-translation` | Comma-separated PR labels that skip translation |

## Outputs

| Output | Description |
|--------|-------------|
| `skipped` | `true` if translation was skipped |
| `skip-reason` | Reason for skipping (if applicable) |

## Examples 👏

### Basic Usage

The simplest setup uses the `ci` command which auto-detects your context:

```yaml
- uses: localheroai/localhero-action@v1
  with:
    api-key: ${{ secrets.LOCALHERO_API_KEY }}
```

### With Pre/Post Processing Steps

For projects that need custom setup (e.g., PO file extraction):

```yaml
jobs:
  translate:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v5
        with:
          ref: ${{ github.event.client_payload.branch || github.head_ref || github.ref_name }}
          fetch-depth: 0

      # Extract messages (project-specific)
      - name: Extract messages
        run: |
          python manage.py makemessages
          python manage.py concat_po_files

      # Run Localhero.ai translation
      - uses: localheroai/localhero-action@v1
        with:
          api-key: ${{ secrets.LOCALHERO_API_KEY }}

      # Compile messages (project-specific)
      - name: Compile messages
        run: python manage.py compilemessages
```

## Skip Translation 🚧

The action automatically skips translation when:

- **PR has skip label**: Add `skip-translation` label to any PR
- **PR is a draft**: Draft PRs are skipped
- **Bot auto-sync**: Prevents infinite loops from bot commits

### Custom Skip Labels

```yaml
- uses: localheroai/localhero-action@v1
  with:
    api-key: ${{ secrets.LOCALHERO_API_KEY }}
    skip-labels: 'skip-translation,wip,no-i18n'
```

## Commands ⚙️

| Command | Description |
|---------|-------------|
| `ci` | Auto-detects context: uses `--changed-only` on PRs, full translation on main |
| `translate` | Translate missing keys in your i18n files |
| `push` | Push local translations to Localhero.ai |
| `pull` | Pull translations from Localhero.ai |

## GitHub Integration 🔗

For the best experience, connect your repository to Localhero.ai via the GitHub App:

1. Go to your project in [Localhero.ai](https://localhero.ai)
2. Open **Project Settings** → **Connect to GitHub**
3. Install the Localhero.ai GitHub App

This enables:
- Automatic commits to your PRs
- Create PRs directly from the Localhero.ai web UI
- Sync translations between your repo and Localhero.ai

## Support 💬

- **Documentation**: [localhero.ai/docs](https://localhero.ai/docs)
- **CLI Tool**: [@localheroai/cli](https://www.npmjs.com/package/@localheroai/cli)
- **Email**: hi@localhero.ai

## License 📄

MIT License - see [LICENSE](LICENSE) for details.
