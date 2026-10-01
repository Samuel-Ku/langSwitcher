#!/usr/bin/env bash
#
# test-auto-ci-dispatch.sh — self-test for scripts/auto-ci-dispatch.sh.
#
# Runs the poller against a stubbed gh (no network) inside a throwaway repo
# that CONTAINS a copy of the poller, so REPO_ROOT, origin/main and the state
# file all resolve inside the sandbox — it can never dispatch real workflows
# or touch the real poller's state:
#
#   1. unknown argument        -> usage on stderr, exit 2
#   2. no state file           -> dispatches, records SHA in state
#   3. state up to date        -> "no new commits", no second dispatch
#   4. state wiped, run exists -> records and skips, no re-dispatch
#   5. new commit              -> dispatches again, state follows HEAD
#   6. dispatch failure        -> does not record; retries next poll
#   7. retry after failure     -> dispatch succeeds and records
#   8. corrupted state         -> treated as unseen; run list vetoes the
#                                 dispatch, HEAD gets recorded
#
# Exit 0 = all checks passed, 1 = at least one failed. Run in CI by the
# free-Ubuntu "changes" job, right after the install-hooks self-test.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0
TMP=""
STUB_BIN=""

cleanup() {
  [ -n "$STUB_BIN" ] && rm -rf "$STUB_BIN"
  [ -n "$TMP" ] && rm -rf "$TMP"
}
trap cleanup EXIT

pass() { echo "  ok: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "test-auto-ci-dispatch: building stub environment"

# Throwaway repo; the poller is copied INSIDE so its REPO_ROOT (derived from
# the script's own path), origin/main and the state file all resolve inside
# the sandbox, never against the real repo.
TMP="$(mktemp -d)"
mkdir -p "$TMP/scripts"
cp "$SCRIPT_DIR/auto-ci-dispatch.sh" "$TMP/scripts/"
git -C "$TMP" init --quiet

# The poller resolves HEAD via `git rev-parse origin/main`, so the sandbox
# carries a remote-tracking ref that advances with every test commit.
advance() {
  git -C "$TMP" -c user.email=test@example.com -c user.name=test \
    commit --quiet --allow-empty -m "$1"
  git -C "$TMP" update-ref refs/remotes/origin/main HEAD
  git -C "$TMP" rev-parse HEAD
}

SHA2="$(advance second)"

# Stub gh: records every invocation, answers `run list` from runs.log, and
# exits with STUB_DISPATCH_RC for `workflow run`. MUST be executable — if it
# were not, find_gh() would silently fall through to a real gh.
STUB_BIN="$(mktemp -d)"
cat > "$STUB_BIN/gh" <<'STUB'
#!/usr/bin/env bash
LOG_DIR="$(dirname "$0")"
printf '%s\n' "$*" >> "$LOG_DIR/dispatches.log"
case "$1 $2" in
  "workflow run")
    exit "${STUB_DISPATCH_RC:-0}" ;;
  "run list")
    if [ -f "$LOG_DIR/runs.log" ]; then cat "$LOG_DIR/runs.log"; fi
    exit 0 ;;
  *)
    exit 0 ;;
esac
STUB
chmod +x "$STUB_BIN/gh"

# Poller invocation: sandbox repo, isolated TMPDIR (state/log), stub gh first
# in PATH so find_gh() picks the stub via command -v.
poll() {
  (cd "$TMP" && TMPDIR="$TMP" PATH="$STUB_BIN:$PATH" \
    ./scripts/auto-ci-dispatch.sh check > "$TMP/out.txt" 2>&1)
  echo $?
}

# Same, but the stub gh fails `workflow run` with the given exit code
# (simulating a GitHub API outage).
poll_failing() {
  (cd "$TMP" && STUB_DISPATCH_RC="$1" TMPDIR="$TMP" PATH="$STUB_BIN:$PATH" \
    ./scripts/auto-ci-dispatch.sh check > "$TMP/out.txt" 2>&1)
  echo $?
}

# Dispatches recorded so far (via the stub).
dispatch_count() {
  [ -f "$STUB_BIN/dispatches.log" ] && grep -c "workflow run" "$STUB_BIN/dispatches.log" || echo 0
}

fresh() {
  rm -f "$STUB_BIN/dispatches.log" "$STUB_BIN/runs.log" "$TMP/langswitcher-auto-ci.state"
}

echo "test-auto-ci-dispatch: running checks"

# --- 1. Unknown argument -> usage + exit 2.
OUT="$(TMPDIR="$TMP" PATH="$STUB_BIN:$PATH" "$TMP/scripts/auto-ci-dispatch.sh" --bogus 2>&1)"
RC=$?
if [ "$RC" -eq 2 ] && [[ "$OUT" == *"usage:"* ]]; then
  pass "unknown argument exits 2 with usage"
else
  fail "unknown argument: rc=$RC out=$OUT"
fi

fresh

# --- 2. No state file: poller dispatches and records HEAD.
RC=$(poll)
if [ "$RC" -eq 0 ] \
  && [ "$(dispatch_count)" -eq 1 ] \
  && [ "$(cat "$TMP/langswitcher-auto-ci.state")" = "$SHA2" ]; then
  pass "first poll dispatches and records HEAD"
else
  fail "first poll: rc=$RC dispatches=$(dispatch_count) state=$(cat "$TMP/langswitcher-auto-ci.state" 2>/dev/null)"
fi

# --- 3. Same HEAD again: no new commits, no second dispatch.
RC=$(poll)
if [ "$RC" -eq 0 ] \
  && [ "$(dispatch_count)" -eq 1 ] \
  && grep -q "no new commits" "$TMP/out.txt"; then
  pass "second poll is a no-op (idempotent)"
else
  fail "second poll: rc=$RC dispatches=$(dispatch_count) out=$(cat "$TMP/out.txt")"
fi

# --- 4. State wiped, run already exists on GitHub: record and skip.
rm -f "$TMP/langswitcher-auto-ci.state"
printf '%s\n' "$SHA2" > "$STUB_BIN/runs.log"
RC=$(poll)
if [ "$RC" -eq 0 ] \
  && [ "$(dispatch_count)" -eq 1 ] \
  && grep -q "run already exists" "$TMP/out.txt" \
  && [ "$(cat "$TMP/langswitcher-auto-ci.state")" = "$SHA2" ]; then
  pass "state wipe + existing run -> records and skips (no double dispatch)"
else
  fail "state wipe: rc=$RC dispatches=$(dispatch_count) out=$(cat "$TMP/out.txt")"
fi

# --- 5. New commit arrives: dispatches again, state follows HEAD.
rm -f "$STUB_BIN/runs.log"
SHA3="$(advance third)"
RC=$(poll)
if [ "$RC" -eq 0 ] \
  && [ "$(dispatch_count)" -eq 2 ] \
  && [ "$(cat "$TMP/langswitcher-auto-ci.state")" = "$SHA3" ]; then
  pass "new commit -> dispatches and state follows HEAD"
else
  fail "new commit: rc=$RC dispatches=$(dispatch_count) state=$(cat "$TMP/langswitcher-auto-ci.state" 2>/dev/null)"
fi

# --- 6. Dispatch fails: state keeps the last good value (SHA3), so the
#        poller will retry the new commit on the next poll.
SHA4="$(advance fourth)"
RC=$(poll_failing 1)
if [ "$RC" -eq 0 ] \
  && [ "$(dispatch_count)" -eq 3 ] \
  && grep -q "dispatch failed" "$TMP/out.txt" \
  && [ "$(cat "$TMP/langswitcher-auto-ci.state")" = "$SHA3" ]; then
  pass "failed dispatch -> last good state kept (will retry)"
else
  fail "failed dispatch: rc=$RC dispatches=$(dispatch_count) state=$(cat "$TMP/langswitcher-auto-ci.state" 2>/dev/null || echo none)"
fi

# --- 7. Retry after failure: succeeds and records.
RC=$(poll)
if [ "$RC" -eq 0 ] \
  && [ "$(dispatch_count)" -eq 4 ] \
  && [ "$(cat "$TMP/langswitcher-auto-ci.state")" = "$SHA4" ]; then
  pass "retry after failure -> dispatch succeeds and records"
else
  fail "retry: rc=$RC dispatches=$(dispatch_count) state=$(cat "$TMP/langswitcher-auto-ci.state" 2>/dev/null)"
fi

# --- 8. Corrupted state: treated as unseen, but the run-list veto stops the
#        double dispatch and HEAD gets recorded.
echo "garbage" > "$TMP/langswitcher-auto-ci.state"
printf '%s\n' "$SHA4" > "$STUB_BIN/runs.log"
RC=$(poll)
if [ "$RC" -eq 0 ] \
  && [ "$(dispatch_count)" -eq 4 ] \
  && grep -q "run already exists" "$TMP/out.txt" \
  && [ "$(cat "$TMP/langswitcher-auto-ci.state")" = "$SHA4" ]; then
  pass "corrupted state -> run-list veto, no dispatch, HEAD recorded"
else
  fail "corrupted state: rc=$RC dispatches=$(dispatch_count) out=$(cat "$TMP/out.txt")"
fi

echo
echo "test-auto-ci-dispatch: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
