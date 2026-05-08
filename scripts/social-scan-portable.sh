#!/usr/bin/env bash
set -euo pipefail

# social-scan-portable.sh
# Portable Reddit + X + Telegram-group scan for OpenClaw instances.
# Usage:
#   ./scripts/social-scan-portable.sh "topic" [hours]

TOPIC="${1:-}"
HOURS="${2:-24}"

if [[ -z "$TOPIC" ]]; then
  TOPIC="grants OR RFP OR partnership OR contributor OR milestone OR payout OR agreement OR DAO ops"
  echo "[social-scan] No topic provided; using default BD query." >&2
fi

if ! [[ "$HOURS" =~ ^[0-9]+$ ]]; then
  echo "[social-scan] Invalid hours value '$HOURS'; defaulting to 24." >&2
  HOURS=24
fi

# Resolve workspace root:
# 1) OPENCLAW_WORKSPACE env var (recommended)
# 2) /home/*/.openclaw/workspace that contains required scripts
if [[ -n "${OPENCLAW_WORKSPACE:-}" ]]; then
  WORKDIR="$OPENCLAW_WORKSPACE"
else
  WORKDIR=""
  for p in \
    "$HOME/.openclaw/workspace" \
    "/home/clawdbot/.openclaw/workspace" \
    "/root/.openclaw/workspace"
  do
    if [[ -d "$p" ]]; then
      WORKDIR="$p"
      break
    fi
  done
fi

if [[ -z "$WORKDIR" || ! -d "$WORKDIR" ]]; then
  echo "[social-scan] Could not resolve OpenClaw workspace. Set OPENCLAW_WORKSPACE." >&2
  exit 1
fi

REDDIT_SCRIPT="$WORKDIR/skills/reddit-readonly/scripts/reddit-readonly.mjs"
TELEGRAM_SCAN_SCRIPT="$WORKDIR/scripts/telegram-group-scan.sh"
X_ENV_FILE="${SOCIAL_SCAN_ENV_FILE:-$HOME/.config/social-scan/.env}"
X_TOKEN_FILE="${X_BEARER_TOKEN_FILE:-$HOME/.config/social-scan/x-bearer-token.txt}"

if [[ ! -f "$REDDIT_SCRIPT" ]]; then
  echo "Missing reddit-readonly script at: $REDDIT_SCRIPT" >&2
  exit 1
fi

if [[ -f "$X_ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$X_ENV_FILE"
  set +a
fi

if [[ -f "$X_TOKEN_FILE" ]]; then
  X_BEARER_TOKEN="$(tr -d '\r\n' < "$X_TOKEN_FILE")"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
REDDIT_JSON="$TMP_DIR/reddit.json"
X_JSON="$TMP_DIR/x.json"

if timeout 45s node "$REDDIT_SCRIPT" search all "$TOPIC" --limit 12 > "$REDDIT_JSON"; then
  :
else
  echo '{"ok":false,"error":{"message":"reddit-readonly failed or timed out"}}' > "$REDDIT_JSON"
fi

if [[ -n "${X_BEARER_TOKEN:-}" ]]; then
  START_TIME=$(date -u -d "$HOURS hours ago" +"%Y-%m-%dT%H:%M:%SZ")
  X_QUERY="(${TOPIC}) lang:en -is:retweet"

  curl -s --max-time 120 --get 'https://api.x.com/2/tweets/search/recent' \
    -H "Authorization: Bearer ${X_BEARER_TOKEN}" \
    --data-urlencode "query=${X_QUERY}" \
    --data-urlencode "start_time=${START_TIME}" \
    --data-urlencode "max_results=20" \
    --data-urlencode 'tweet.fields=created_at,author_id,public_metrics,text' \
    --data-urlencode 'expansions=author_id' \
    --data-urlencode 'user.fields=username,name' \
    > "$X_JSON" || echo '{"error":"x_api_request_failed"}' > "$X_JSON"
else
  echo '{"error":"X_BEARER_TOKEN not set"}' > "$X_JSON"
fi

printf "Topic: %s\n" "$TOPIC"
printf "Window: last %sh\n\n" "$HOURS"

echo "Reddit (top matches):"
if jq -e '.ok == true' "$REDDIT_JSON" >/dev/null 2>&1; then
  jq -r '.data.posts[:6][] | "- [r/\(.subreddit)] \(.title)\n  \(.permalink)"' "$REDDIT_JSON"
else
  echo "- Reddit unavailable"
fi

echo
echo "X (top matches):"
if jq -e '.error or .errors' "$X_JSON" >/dev/null 2>&1; then
  if jq -e '.errors' "$X_JSON" >/dev/null 2>&1; then
    jq -r '.errors[] | "- X API error: " + (.detail // (.title // "unknown"))' "$X_JSON"
  else
    jq -r '"- " + (.error|tostring)' "$X_JSON"
  fi
else
  jq -r '
    def usersById: ( .includes.users // [] | map({key: .id, value: .}) | from_entries );
    (usersById) as $u
    | ( .data // [] )[:6]
    | if length == 0 then
        "- X returned no matching posts"
      else
        .[]
        | "- [@\(($u[.author_id].username // "unknown"))] "
          + ((.text // "") | gsub("\n"; " ") | .[0:160])
          + "\n  https://x.com/\(($u[.author_id].username // "unknown"))/status/\(.id)"
      end
  ' "$X_JSON"
fi

echo
echo "Telegram groups (high-signal, last 4h):"
if [[ -x "$TELEGRAM_SCAN_SCRIPT" ]]; then
  "$TELEGRAM_SCAN_SCRIPT" 4 || echo "- Telegram scan unavailable"
else
  echo "- Telegram scan script missing"
fi
