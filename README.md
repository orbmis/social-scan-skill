# social-scan

Portable OpenClaw skill for fast cross-channel BD signal scans.

It collects recent signals from:
- **Reddit** (via `reddit-readonly`)
- **X** (official recent-search API)
- **Telegram groups** (via `telegram-group-scan.sh`)

Use it to quickly source potential opportunities, triage noisy keyword matches, and produce a first-pass scouting snapshot.

---

## Folder structure

```text
social-scan-bd/
├── SKILL.md
├── README.md
├── references/
│   └── SETUP.md
└── scripts/
    ├── social-scan-portable.sh   # recommended
    └── social-scan.sh            # legacy path-bound variant
```

---

## What this skill does

The script:
1. Accepts a query + time window.
2. Pulls top matches from Reddit and X.
3. Pulls high-signal Telegram group messages from a recent window.
4. Prints a concise feed with links and source status.

It is designed as a **collection layer** (first pass), not a final ranking/qualification engine.

---

## Requirements

Host dependencies:
- `bash`
- `node`
- `jq`
- `curl`
- `timeout` (from coreutils)

Ubuntu/Debian:

```bash
sudo apt-get update
sudo apt-get install -y jq curl coreutils
```

OpenClaw resources expected:
- `skills/reddit-readonly/scripts/reddit-readonly.mjs`
- `scripts/telegram-group-scan.sh`

If your workspace is non-standard, set:

```bash
export OPENCLAW_WORKSPACE="/path/to/.openclaw/workspace"
```

---

## How to run

Recommended (portable):

```bash
bash scripts/social-scan-portable.sh "grants OR RFP OR DAO operations" 24
```

Defaults (if omitted):
- Query: `grants OR RFP OR partnership OR contributor OR milestone OR payout OR agreement OR DAO ops`
- Hours: `24`

---

## X API setup (official recent search)

The script calls:
- `https://api.x.com/2/tweets/search/recent`

### 1) Get an X Bearer Token

From your X developer app/project, obtain a bearer token with access to v2 recent search.

### 2) Provide token to the script (choose one)

**Option A — env file (recommended):**

```bash
mkdir -p ~/.config/social-scan
cat > ~/.config/social-scan/.env << 'EOF'
X_BEARER_TOKEN=YOUR_X_BEARER_TOKEN_HERE
EOF
```

**Option B — token file:**

```bash
mkdir -p ~/.config/social-scan
printf 'YOUR_X_BEARER_TOKEN_HERE\n' > ~/.config/social-scan/x-bearer-token.txt
```

### 3) Optional custom paths

```bash
export SOCIAL_SCAN_ENV_FILE="/custom/path/.env"
export X_BEARER_TOKEN_FILE="/custom/path/x-bearer-token.txt"
```

### 4) Validate quickly

Run:

```bash
bash scripts/social-scan-portable.sh "DAO operations" 24
```

If X auth fails, output will include an X API error line.

---

## Telegram dependency notes

This skill does **not** call OpenClaw `message` tool directly.
It depends on `telegram-group-scan.sh` for reading configured groups. If Telegram output is unavailable:
- verify script exists,
- verify it is executable,
- verify that instance has Telegram scan access configured.

---

## Troubleshooting

- **"Could not resolve OpenClaw workspace"**
  - Set `OPENCLAW_WORKSPACE` explicitly.
- **"Missing reddit-readonly script"**
  - Install or sync the `reddit-readonly` skill in that instance.
- **X returns auth error / no data**
  - Recheck bearer token and project access to recent search endpoint.
- **Telegram scan unavailable**
  - Check `scripts/telegram-group-scan.sh` presence, permissions, and config.

---

## Suggested usage pattern

- Use broad query for discovery.
- Then iterate with stricter intent phrases + negative filters to reduce collisions.
- Apply scoring/qualification in your downstream prompt or automation logic.
