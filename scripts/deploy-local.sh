#!/usr/bin/env bash
#
# deploy-local.sh — rebuild LangSwitcher and swap it into /Applications in one
# command, then relaunch it. No Xcode needed (swiftc only).
#
# What it does:
#   1. Builds the full app binary with swiftc (all Sources).
#   2. Quits the running instance (graceful osascript, then kill as fallback).
#   3. Backs the old binary up OUTSIDE the bundle — a stray file inside
#      Contents/MacOS/ breaks the code signature (learned the hard way).
#   4. Copies the new binary in and re-signs the bundle ad-hoc.
#   5. Verifies the signature, launches the app, and confirms the process.
#
# Usage:
#   scripts/deploy-local.sh              # full deploy
#   scripts/deploy-local.sh --dry-run    # build + verify only, no app changes
#   scripts/deploy-local.sh --rollback   # restore the backup from /tmp
#
# After every real deploy you MUST re-approve TCC permissions by hand:
#   System Settings → Privacy & Security → Accessibility and Input Monitoring
#   → toggle LangSwitcher (remove + re-add if the toggle won't stick).
# The hotkey and text replacement stay inert until you do.
#
# Rollback: the previous binary is kept at /tmp/LangSwitcher.old.bak.
# NOTE: /tmp is wiped on reboot — copy it somewhere permanent if you want to
# keep the old binary longer than this session.

set -euo pipefail

APP_NAME="LangSwitcher"
APP_BUNDLE="/Applications/${APP_NAME}.app"
BINARY="${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
BACKUP="/tmp/${APP_NAME}.old.bak"
BUILD_DIR="/tmp/lsbuild"
NEW_BINARY="${BUILD_DIR}/${APP_NAME}"

DRY_RUN=0
ROLLBACK=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --rollback) ROLLBACK=1 ;;
    *)
      echo "usage: $0 [--dry-run | --rollback]" >&2
      exit 2
      ;;
  esac
done

say() { printf '==> %s\n' "$*"; }

if [[ "$ROLLBACK" == 1 ]]; then
  if [[ ! -f "$BACKUP" ]]; then
    echo "error: no backup at $BACKUP (already used, or /tmp was wiped)" >&2
    exit 1
  fi
  say "Stopping running instance"
  osascript -e "quit app \"${APP_NAME}\"" 2>/dev/null || true
  sleep 2
  pkill -x "$APP_NAME" 2>/dev/null || true
  say "Restoring $BACKUP → $BINARY"
  cp "$BACKUP" "$BINARY"
  say "Re-signing ad-hoc"
  codesign --force --sign - "$APP_BUNDLE"
  codesign --verify --deep --strict "$APP_BUNDLE"
  say "Launching"
  open -a "$APP_NAME"
  sleep 5
  pgrep -x "$APP_NAME" >/dev/null && say "Rollback done — running as PID $(pgrep -x "$APP_NAME")"
  exit 0
fi

# --- Sanity checks ----------------------------------------------------------
[[ -d "$APP_BUNDLE" ]] || { echo "error: $APP_BUNDLE not found" >&2; exit 1; }
[[ -f "LangSwitcher/Sources/App/AppDelegate.swift" ]] || {
  echo "error: run from the repo root" >&2
  exit 1
}

# --- 1. Build ---------------------------------------------------------------
say "Building full binary → $NEW_BINARY"
mkdir -p "$BUILD_DIR"
SDK="$(xcrun --show-sdk-path)"
# shellcheck disable=SC2046
swiftc -swift-version 5 -O \
  -target arm64-apple-macosx13.0 -sdk "$SDK" \
  -o "$NEW_BINARY" \
  $(find LangSwitcher/Sources -name '*.swift')

# --- 2. Dry-run exits here --------------------------------------------------
if [[ "$DRY_RUN" == 1 ]]; then
  say "Dry run: build OK ($(du -h "$NEW_BINARY" | cut -f1)); app untouched"
  say "Signature of the currently installed binary (unchanged):"
  codesign --verify "$APP_BUNDLE" && echo "    current bundle still verifies"
  exit 0
fi

# --- 3. Stop the running instance -------------------------------------------
say "Stopping running instance"
osascript -e "quit app \"${APP_NAME}\"" 2>/dev/null || true
sleep 2
if pgrep -x "$APP_NAME" >/dev/null; then
  pkill -x "$APP_NAME" 2>/dev/null || true
  sleep 2
fi
if pgrep -x "$APP_NAME" >/dev/null; then
  pkill -9 -x "$APP_NAME" 2>/dev/null || true
  sleep 1
fi

# --- 4. Backup (outside the bundle!), swap, re-sign --------------------------
say "Backing up old binary → $BACKUP"
cp -p "$BINARY" "$BACKUP"
say "Swapping in new binary"
cp "$NEW_BINARY" "$BINARY"
say "Re-signing ad-hoc"
codesign --force --sign - "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

# --- 5. Launch and verify ----------------------------------------------------
say "Launching"
open -a "$APP_NAME"
sleep 5
PID="$(pgrep -x "$APP_NAME" || true)"
if [[ -z "$PID" ]]; then
  echo "error: app did not start — check ~/Library/Logs/DiagnosticReports" >&2
  echo "       rollback: $0 --rollback" >&2
  exit 1
fi
say "Deployed — running as PID $PID"
say "REMINDER: re-approve Accessibility + Input Monitoring in System Settings"
echo "         (the hotkey stays inert until you do). Rollback: $0 --rollback"
