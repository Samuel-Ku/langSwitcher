#!/usr/bin/env bash
#
# auto-ci-dispatch.sh — make CI run automatically on every push to this fork.
#
# Root cause it works around: this repository is a fork whose workflows have
# never been enabled for automatic triggers (every run in its history is
# workflow_dispatch; pushes land — PushEvents are visible in the events API —
# but GitHub drops on.push/on.schedule for forks until someone clicks
# "I understand my workflows, go ahead and enable them" on the Actions tab).
# That flag has no REST API, so while it cannot be clicked programmatically,
# dispatches still work. This poller turns new pushes into dispatches.
#
# The PERMANENT fix is one manual click, once:
#   1. Open https://github.com/Samuel-Ku/langSwitcher/actions (signed in)
#   2. If a banner says workflows need enabling, click "I understand my
#      workflows, go ahead and enable them."
#   3. Stop and uninstall this poller; CI will then run on push natively.
#
# How it works:
#   - Every POLL_SECONDS it asks GitHub for the latest SHA on origin/main.
#   - If it differs from the last-seen SHA (state file) AND that SHA has no
#     run for HEAD SHA yet, it dispatches "Build & Release" and records it.
#   - Idempotent: crashes/restarts never double-dispatch the same commit.
#
# Install:   scripts/auto-ci-dispatch.sh install
# Uninstall: scripts/auto-ci-dispatch.sh uninstall
# Run once:  scripts/auto-ci-dispatch.sh check   (for cron/launchd users)
# Status:    scripts/auto-ci-dispatch.sh status  (or --status)

set -euo pipefail

REPO="Samuel-Ku/langSwitcher"
BRANCH="main"
WORKFLOW="Build & Release"
STATE="${TMPDIR:-/tmp}/langswitcher-auto-ci.state"
LOG="${TMPDIR:-/tmp}/langswitcher-auto-ci.log"
POLL_SECONDS=60
# LaunchAgents run from / — locate the repo from the script's own path.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# launchd's PATH is minimal (/usr/bin:/bin:...) and may not contain gh.
find_gh() {
  if command -v gh >/dev/null 2>&1; then command -v gh; return; fi
  local candidate
  for candidate in /usr/local/bin/gh /opt/homebrew/bin/gh "$HOME/.local/bin/gh"; do
    [[ -x "$candidate" ]] && { echo "$candidate"; return; }
  done
  echo "gh"  # last resort: let it fail visibly in the log
}
GH_BIN="$(find_gh)"

say() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*"; }

latest_sha() {
  git -C "$REPO_ROOT" rev-parse "origin/${BRANCH}"
}

dispatch_if_needed() {
  local sha
  sha="$(latest_sha)"
  local last=""
  [[ -f "$STATE" ]] && last="$(cat "$STATE" 2>/dev/null || true)"

  if [[ "$sha" == "$last" ]]; then
    say "no new commits ($sha)"
    return 0
  fi

  # Has this commit already got a run? (covers the state file being wiped.)
  if "$GH_BIN" run list --repo "$REPO" --branch "$BRANCH" --limit 5 \
       --json headSha,status --jq '.[] | .headSha' | grep -q "^${sha}"; then
    say "run already exists for $sha — recording and skipping"
    echo "$sha" > "$STATE"
    return 0
  fi

  say "new commit $sha — dispatching ${WORKFLOW}"
  if "$GH_BIN" workflow run "$WORKFLOW" --repo "$REPO" --ref "$BRANCH"; then
    echo "$sha" > "$STATE"
    say "dispatched; state updated"
  else
    say "dispatch failed (will retry next poll)"
  fi
}

install() {
  local dir="$HOME/Library/LaunchAgents"
  local plist="$dir/com.langswitcher.auto-ci.plist"
  mkdir -p "$dir"
  cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.langswitcher.auto-ci</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(command -v bash)</string>
        <string>$PWD/scripts/auto-ci-dispatch.sh</string>
        <string>check</string>
    </array>
    <key>StartInterval</key><integer>$POLL_SECONDS</integer>
    <key>StandardOutPath</key><string>$LOG</string>
    <key>StandardErrorPath</key><string>$LOG</string>
</dict>
</plist>
PLIST
  launchctl unload "$plist" 2>/dev/null || true
  launchctl load "$plist"
  say "installed LaunchAgent $plist (poll every ${POLL_SECONDS}s, log: $LOG)"
  dispatch_if_needed
}

uninstall() {
  local plist="$HOME/Library/LaunchAgents/com.langswitcher.auto-ci.plist"
  launchctl unload "$plist" 2>/dev/null || true
  rm -f "$plist"
  say "uninstalled (state/log left in place: $STATE, $LOG)"
}

# Read-only report: is the LaunchAgent loaded, when did it last dispatch?
status() {
  local plist="$HOME/Library/LaunchAgents/com.langswitcher.auto-ci.plist"
  local loaded=false
  launchctl print "gui/$(id -u)/com.langswitcher.auto-ci" >/dev/null 2>&1 && loaded=true

  echo "LaunchAgent:"
  echo "  plist:      $plist $([ -f "$plist" ] && echo '(present)' || echo '(missing)')"
  if $loaded; then
    echo "  loaded:     yes (running every ${POLL_SECONDS}s)"
    echo "  log:        $LOG"
  else
    echo "  loaded:     NO — poller is not active; install with: $0 install"
  fi

  echo "Dispatch state:"
  if [[ -f "$STATE" ]]; then
    local last_shas="$(cat "$STATE" 2>/dev/null | sort -u)"
    if [[ -n "$last_shas" ]]; then
      local s
      for s in $last_shas; do
        local ts="$(git -C "$REPO_ROOT" log -1 --format=%cs "$s" 2>/dev/null || echo '?')"
        echo "  last seen:  $s (committed $ts)"
      done
    else
      echo "  state file: $STATE (empty)"
    fi
  else
    echo "  state file: $STATE (missing — poller has not recorded anything yet)"
  fi

  if [[ -f "$LOG" ]]; then
    echo "  last log:   $(tail -n 1 "$LOG" 2>/dev/null)"
  else
    echo "  log:        $LOG (missing)"
  fi

  echo "Recent runs (latest dispatch):"
  if command -v "$GH_BIN" >/dev/null 2>&1; then
    local line
    while IFS= read -r line; do
      echo "  $line"
    done < <("$GH_BIN" run list --repo "$REPO" --branch "$BRANCH" --limit 3 \
              --json databaseId,event,status,headSha,createdAt \
              --jq '.[] | "run \(.databaseId) \(.event) \(.status) for \(.headSha[0:7]) at \(.createdAt)"' 2>/dev/null) || true
  else
    echo "  gh not found — cannot query runs"
  fi

  $loaded
}

case "${1:-}" in
  install)  install ;;
  uninstall) uninstall ;;
  check)    dispatch_if_needed ;;
  status|--status) status ;;
  *)
    echo "usage: $0 {install|uninstall|check|status}" >&2
    echo "  install    register a LaunchAgent that polls every ${POLL_SECONDS}s" >&2
    echo "  uninstall  remove the LaunchAgent" >&2
    echo "  check      run one poll (idempotent)" >&2
    echo "  status     report agent load state, last dispatch, recent runs" >&2
    exit 2
    ;;
esac
