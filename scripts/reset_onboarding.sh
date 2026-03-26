#!/usr/bin/env zsh
set -euo pipefail

APP_NAME="NotchFlow"
BUNDLE_ID="com.notchflow.app"
ONBOARDING_KEY="PermissionsSetupCompleted"
LAUNCH_AFTER_RESET=0

for arg in "$@"; do
  if [[ "$arg" == "--launch" ]]; then
    LAUNCH_AFTER_RESET=1
  else
    BUNDLE_ID="$arg"
  fi
done

echo "Resetting onboarding state for $APP_NAME ($BUNDLE_ID)..."

# Ensure app is not running while resetting state.
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

# Clear onboarding completion key for bundled and legacy domains.
defaults delete "$BUNDLE_ID" "$ONBOARDING_KEY" >/dev/null 2>&1 || true
defaults delete "$APP_NAME" "$ONBOARDING_KEY" >/dev/null 2>&1 || true

# Reset Apple Events automation permission prompts.
tccutil reset AppleEvents "$BUNDLE_ID" >/dev/null 2>&1 || true

echo "Done. Launch $APP_NAME to run setup from the beginning."

if [[ $LAUNCH_AFTER_RESET -eq 1 ]]; then
  echo "Launching $APP_NAME..."
  open -a "$APP_NAME"
fi
