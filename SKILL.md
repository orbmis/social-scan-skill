---
name: social-scan-bd
description: Run a cross-channel BD signal scan across Reddit, X, and Telegram using social-scan.sh. Use when you need fast sourcing of recent opportunities, noisy-keyword triage, or a daily scouting snapshot for grants/RFP/contributor/payout/agreement operations in Web3 or agent ecosystems.
---

Run the bundled scripts to collect recent social signals and output a concise feed.

## Run

Portable (recommended):

```bash
bash scripts/social-scan-portable.sh "<query>" <hours>
```

Original (legacy, path-bound):

```bash
bash scripts/social-scan.sh "<query>" <hours>
```

Use defaults when not provided:
- Query default: `grants OR RFP OR partnership OR contributor OR milestone OR payout OR agreement OR DAO ops`
- Hours default: `24`

## What it does

- Pull Reddit results via `skills/reddit-readonly/scripts/reddit-readonly.mjs`
- Pull X results via official X recent-search API
- Pull Telegram high-signal messages via `scripts/telegram-group-scan.sh` (last 4h)
- Render a readable summary with links and source-by-source status

## Environment requirements

Ensure these are available on the target instance:

- `jq`, `curl`, `node`, `timeout`
- `skills/reddit-readonly/scripts/reddit-readonly.mjs`
- `scripts/telegram-group-scan.sh`
- X token in either:
  - `~/.config/social-scan/.env` (`X_BEARER_TOKEN=...`), or
  - `~/.config/social-scan/x-bearer-token.txt`

Read full setup + dependency instructions in `references/SETUP.md`.

## Notes for reuse in other OpenClaw instances

- Update hardcoded paths in `scripts/social-scan.sh` if workspace layout differs.
- Keep output as a first-pass feed; perform scoring/ranking in downstream prompts or jobs.
- Use narrower intent-heavy queries plus exclusion terms to reduce keyword collisions.
