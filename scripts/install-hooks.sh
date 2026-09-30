#!/usr/bin/env bash
#
# install-hooks.sh — point git at the versioned hooks in githooks/.
#
# Idempotent: safe to run again any time. Sets core.hooksPath for this
# repository only (never global), so other checkouts are unaffected until
# they run this too.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
chmod +x githooks/pre-commit
git config core.hooksPath githooks
echo "hooks installed: commits in this repo now run githooks/pre-commit"
