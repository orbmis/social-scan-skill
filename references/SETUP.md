# social-scan-bd portable setup

## Purpose
Use `scripts/social-scan-portable.sh` to collect a fast cross-channel signal snapshot from:
- Reddit (via `reddit-readonly`)
- X recent search API
- Telegram groups (high-signal scan)

## Dependencies
Install on the host running OpenClaw:

- `bash`
- `node` (for reddit-readonly script)
- `jq`
- `curl`
- `coreutils` `timeout` command

On Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y jq curl coreutils
```

## Required OpenClaw resources
The target instance must have:

1. OpenClaw workspace (usually `~/.openclaw/workspace`)
2. `reddit-readonly` skill script at:
   - `$OPENCLAW_WORKSPACE/skills/reddit-readonly/scripts/reddit-readonly.mjs`
3. Telegram group scan script at:
   - `$OPENCLAW_WORKSPACE/scripts/telegram-group-scan.sh`

If your workspace path is non-standard, set:

```bash
export OPENCLAW_WORKSPACE="/path/to/.openclaw/workspace"
```

## X API auth
Provide bearer token via either:

Option A (env file):
- `~/.config/social-scan/.env` with:

```bash
X_BEARER_TOKEN=your_token_here
```

Option B (token file):
- `~/.config/social-scan/x-bearer-token.txt`

Optional overrides:

```bash
export SOCIAL_SCAN_ENV_FILE="/custom/path/.env"
export X_BEARER_TOKEN_FILE="/custom/path/x-bearer-token.txt"
```

## Telegram requirement
This script does **not** call OpenClaw's `message` tool directly.
It relies on `telegram-group-scan.sh`, which must already be configured to read Telegram group data on that instance.

## Run

```bash
bash scripts/social-scan-portable.sh "grants OR RFP OR DAO operations" 24
```

If no args are provided, defaults are used.
