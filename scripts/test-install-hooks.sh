#!/usr/bin/env bash
#
# test-install-hooks.sh — self-test for scripts/install-hooks.sh.
#
# Builds a throwaway git repo in a temp dir, copies the installer (and the
# versioned hook) in, and exercises the documented lifecycle:
#
#   1. fresh repo          -> --status exits 1 ("NOT ACTIVE")
#   2. unknown argument    -> usage on stderr, exit 2
#   3. install             -> success message, repo-local core.hooksPath,
#                             hook executable
#   4. after install       -> --status exits 0 ("ACTIVE")
#   5. rerun (idempotence) -> still ACTIVE, exit 0
#   6. unset core.hooksPath -> back to "NOT ACTIVE", exit 1
#   7. integration         -> git commit actually invokes the hook (blocked,
#                             because the throwaway repo has no project files
#                             for verify-pbxproj.py to validate)
#
# Exit 0 = all checks passed, 1 = at least one failed. Run in CI by the
# free-Ubuntu "changes" job, right after the pbxproj verifier gate.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$SCRIPT_DIR/install-hooks.sh"
HOOK="$SCRIPT_DIR/../githooks/pre-commit"

PASS=0
FAIL=0
TMP=""
OUT=""
RC=0

cleanup() { [ -n "$TMP" ] && rm -rf "$TMP"; }
trap cleanup EXIT

pass() { echo "  ok: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

# Runs the installer inside the throwaway repo, capturing output and exit code.
run_installer() {
  OUT="$(cd "$TMP" && "$TMP/scripts/install-hooks.sh" "$@" 2>&1)"
  RC=$?
}

echo "test-install-hooks: building throwaway repo"

TMP="$(mktemp -d)"
mkdir -p "$TMP/scripts" "$TMP/githooks"
cp "$INSTALLER" "$TMP/scripts/"
cp "$HOOK" "$TMP/githooks/"
chmod +x "$TMP/githooks/pre-commit"
git -C "$TMP" init --quiet
git -C "$TMP" -c user.email=test@example.com -c user.name=test commit \
  --quiet --allow-empty -m init

echo "test-install-hooks: running checks"

# 1. Fresh repo: hook not active yet.
run_installer --status
if [ "$RC" -eq 1 ] && [[ "$OUT" == *"NOT ACTIVE"* ]]; then
  pass "--status on fresh clone exits 1 (NOT ACTIVE)"
else
  fail "--status on fresh clone: exit=$RC out=$OUT"
fi

# 2. Unknown argument: usage + exit 2.
run_installer --bogus
if [ "$RC" -eq 2 ] && [[ "$OUT" == *"usage:"* ]]; then
  pass "unknown argument exits 2 with usage"
else
  fail "unknown argument: exit=$RC out=$OUT"
fi

# 3. Install: success message, repo-local config, executable hook.
run_installer
HOOKS_PATH_CFG="$(git -C "$TMP" config --local core.hooksPath || true)"
if [ "$RC" -eq 0 ] \
  && [[ "$OUT" == *"installed"* ]] \
  && [ "$HOOKS_PATH_CFG" = "githooks" ] \
  && [ -x "$TMP/githooks/pre-commit" ]; then
  pass "install writes repo-local core.hooksPath and succeeds"
else
  fail "install: exit=$RC config=$HOOKS_PATH_CFG out=$OUT"
fi

# 4. Status after install: ACTIVE, exit 0.
run_installer --status
if [ "$RC" -eq 0 ] && [[ "$OUT" != *"NOT ACTIVE"* ]]; then
  pass "--status after install exits 0 (ACTIVE)"
else
  fail "--status after install: exit=$RC out=$OUT"
fi

# 5. Idempotent rerun: still fine.
run_installer
if [ "$RC" -eq 0 ]; then
  pass "rerun is idempotent (exit 0)"
else
  fail "rerun: exit=$RC out=$OUT"
fi

# 6. Uninstalled again: back to NOT ACTIVE.
git -C "$TMP" config --local --unset core.hooksPath
run_installer --status
if [ "$RC" -eq 1 ] && [[ "$OUT" == *"NOT ACTIVE"* ]]; then
  pass "--status after unset exits 1 (NOT ACTIVE)"
else
  fail "--status after unset: exit=$RC out=$OUT"
fi

# 7. Integration: a commit must actually execute the hook. Reinstall first
#    (check 6 uninstalled the hook), then commit. The throwaway repo lacks
#    scripts/verify-pbxproj.py, so the hook blocks the commit — the point is
#    that git RUNS it at all once the installer has configured core.hooksPath.
run_installer
COMMIT_OUT="$(git -C "$TMP" -c user.email=test@example.com -c user.name=test \
  commit --allow-empty -m hook-invocation-test 2>&1)"
COMMIT_RC=$?
if [ "$COMMIT_RC" -ne 0 ] && [[ "$COMMIT_OUT" == *"pre-commit"* ]]; then
  pass "commit invokes githooks/pre-commit (blocked in throwaway repo)"
else
  fail "commit did not run the hook: rc=$COMMIT_RC out=$COMMIT_OUT"
fi

echo
echo "test-install-hooks: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
