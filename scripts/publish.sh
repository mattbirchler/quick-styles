#!/bin/zsh
# Ships a new version of Quick Styles to everyone who runs it:
#
#   make publish NOTES=notes/1.1.md [VERSION=1.1]
#
# 1. Bumps the build number (and the version, if given) in a commit
#    named "<version> build <number>".
# 2. Builds, signs with Developer ID, and notarizes (scripts/notarize.sh).
# 3. Signs the zip with the Quick Styles Sparkle key and puts it, plus the
#    disk image, in a GitHub release on this repo with the notes.
# 4. Adds the release to appcast.xml and pushes it. The push is the moment
#    people see the update.
#
# NOTES is a short Markdown file written for people: what changed and why
# they'd care. It shows in Sparkle's update window and on the release page.
#
# DRY_RUN=1 does everything except the commits, the upload, and the push,
# and leaves the feed it would publish in build/publish/appcast.xml.
set -euo pipefail
cd "$(dirname "$0")/.."

REPO=mattbirchler/quick-styles
FEED=appcast.xml
WORK=build/publish
DRY_RUN=${DRY_RUN:-0}

fail() { echo "$1" >&2; exit 1; }

[[ -n "${NOTES:-}" && -s "$NOTES" ]] || fail "Write release notes for people first, then run: make publish NOTES=path/to/notes.md"
NOTES=$(cd "$(dirname "$NOTES")" && pwd)/$(basename "$NOTES")

if [[ "$DRY_RUN" != 1 ]]; then
    # Sparkle reads the feed from raw.githubusercontent.com and downloads
    # from GitHub Releases, and neither works for a private repo.
    [[ "$(gh repo view "$REPO" --json visibility -q .visibility)" == PUBLIC ]] \
        || fail "$REPO is private, so nobody could download the update. Make it public first."
    [[ "$(git branch --show-current)" == main ]] || fail "Publish from main."
    [[ -z "$(git status --porcelain)" ]] || fail "Commit or stash your changes first."
    git fetch -q origin main
    [[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || fail "main isn't in step with origin/main."
fi

scripts/sparkle-tools.sh >/dev/null

# The next build number is one past both the project and the live feed, so
# Sparkle always sees it as newer.
rm -rf "$WORK" && mkdir -p "$WORK"
CURRENT=$(python3 scripts/version.py get)
CURRENT_VERSION=${CURRENT% *}
CURRENT_BUILD=${CURRENT#* }
FEED_BUILD=$(grep -o '<sparkle:version>[0-9]*</sparkle:version>' "$FEED" | grep -o '[0-9]*' | sort -n | tail -1 || true)
BUILD=$(( (CURRENT_BUILD > ${FEED_BUILD:-0} ? CURRENT_BUILD : ${FEED_BUILD:-0}) + 1 ))
VERSION=${VERSION:-$CURRENT_VERSION}
TAG="v$VERSION-$BUILD"
echo "Publishing Quick Styles $VERSION build $BUILD"

cp project.yml "$WORK/project.yml.before"
cp "$FEED" "$WORK/appcast.xml.before"
python3 scripts/version.py set "$VERSION" "$BUILD"
# A dry run puts the project and the feed back the way they were.
restore() {
    if [[ "$DRY_RUN" == 1 ]]; then
        cp "$WORK/project.yml.before" project.yml
        cp "$WORK/appcast.xml.before" "$FEED"
    fi
}
trap restore EXIT
if [[ "$DRY_RUN" != 1 ]]; then
    git commit -q -am "$VERSION build $BUILD"
    echo "Committed \"$VERSION build $BUILD\" (not pushed until the release is up)"
fi

ZIP=$(scripts/notarize.sh | tail -1)
[[ -f "$ZIP" ]] || fail "No notarized zip."
DMG="${ZIP%.zip}.dmg"
[[ -f "$DMG" ]] || fail "No disk image next to the zip."

# Signature and size for Sparkle, like: sparkle:edSignature="..." length="..."
SIGNATURE=$(vendor/sparkle/bin/sign_update --account quick-styles "$ZIP")
[[ "$SIGNATURE" == *edSignature* ]] || fail "Couldn't sign the update: $SIGNATURE"
ZIP_URL="https://github.com/$REPO/releases/download/$TAG/$(basename "$ZIP")"

python3 scripts/appcast.py "$FEED" "$VERSION" "$BUILD" "$ZIP_URL" "$SIGNATURE" "$NOTES"

if [[ "$DRY_RUN" == 1 ]]; then
    cp "$FEED" "$WORK/appcast.xml"
    echo "Dry run done. Zip: $ZIP  Feed: $WORK/appcast.xml"
    exit 0
fi

# The downloads go up before the feed points at them, so the feed never
# points at a missing file. A copy named plain QuickStyles.dmg gives every
# release the same download address:
#   https://github.com/$REPO/releases/latest/download/QuickStyles.dmg
LATEST_DMG="$WORK/QuickStyles.dmg"
cp "$DMG" "$LATEST_DMG"
git tag "$TAG"
git push -q origin main "$TAG"
gh release create "$TAG" "$DMG" "$LATEST_DMG" "$ZIP" --repo "$REPO" --title "Quick Styles $VERSION" --notes-file "$NOTES"
git add "$FEED"
git commit -q -m "release: $VERSION build $BUILD"
git push -q origin main
echo "Published Quick Styles $VERSION build $BUILD. Macs pick it up within a day, or right away with Check for Updates."
