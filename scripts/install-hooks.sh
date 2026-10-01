#!/usr/bin/env bash
#
# install-hooks.sh — point git at the versioned hooks in githooks/.
#
# Usage:
#   scripts/install-hooks.sh            install the pre-commit hook (idempotent)
#   scripts/install-hooks.sh --status   report whether the hook is currently
#                                       active; exit 0 if it is, 1 if not
#                                       (handy for scripting)
#
# Sets core.hooksPath for this repository only (never global), so other
# checkouts are unaffected until they run this too.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

HOOKS_PATH="githooks"

hook_active() {
  [ "$(git config --local core.hooksPath 2>/dev/null || true)" = "$HOOKS_PATH" ] \
    && [ -x "$HOOKS_PATH/pre-commit" ]
}

case "${1:-}" in
  --status)
    if hook_active; then
      echo "pre-commit hook: ACTIVE — commits in this repo run $HOOKS_PATH/pre-commit (scripts/verify-pbxproj.py)"
      exit 0
    fi
    echo "pre-commit hook: NOT ACTIVE — run scripts/install-hooks.sh to enable it"
    exit 1
    ;;
  "")
    ;;
  *)
    echo "usage: scripts/install-hooks.sh [--status]" >&2
    exit 2
    ;;
esac

chmod +x "$HOOKS_PATH/pre-commit"
git config --local core.hooksPath "$HOOKS_PATH"

echo "✅ pre-commit hook installed."
echo "   Every commit now runs $HOOKS_PATH/pre-commit (scripts/verify-pbxproj.py),"
echo "   which blocks pbxproj drift before it reaches CI."
echo "   Check anytime with: scripts/install-hooks.sh --status"
echo "   Bypass a single commit with: git commit --no-verify"
