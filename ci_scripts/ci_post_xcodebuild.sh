#!/bin/sh

# Xcode Cloud runs this after every xcodebuild action.
#
# When the action produced a signed archive headed for TestFlight, write the
# "What to Test" notes so each build says which branch it came from and what
# changed. Builds from different feature branches all land in the same
# TestFlight app, so without this they are indistinguishable to a tester.
#
# Xcode Cloud picks the notes up from TestFlight/WhatToTest.<locale>.txt next
# to the .xcodeproj. This script must never fail the build, so every step is
# best-effort and it always exits 0.

if [ -z "$CI_APP_STORE_SIGNED_APP_PATH" ] || [ ! -d "$CI_APP_STORE_SIGNED_APP_PATH" ]; then
    echo "No signed app for distribution; skipping TestFlight notes."
    exit 0
fi

REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
NOTES_DIR="$REPO_ROOT/TestFlight"
NOTES_FILE="$NOTES_DIR/WhatToTest.en-US.txt"

mkdir -p "$NOTES_DIR" || exit 0

# Xcode Cloud clones shallow; fetch a little history so the log has content.
git -C "$REPO_ROOT" fetch --deepen 10 >/dev/null 2>&1

{
    echo "Branch: ${CI_BRANCH:-${CI_PULL_REQUEST_SOURCE_BRANCH:-unknown}}"
    echo "Build: ${CI_BUILD_NUMBER:-unknown}"
    echo
    echo "Recent changes:"
    git -C "$REPO_ROOT" log -8 --no-merges --pretty=format:"- %s" 2>/dev/null
    echo
} > "$NOTES_FILE" 2>/dev/null

echo "Wrote TestFlight notes to $NOTES_FILE"
exit 0
