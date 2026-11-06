PROJECT = QuickStyles.xcodeproj
SCHEME = QuickStyles
DERIVED = build
XCODEBUILD = xcodebuild -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED) -destination 'platform=macOS'

.PHONY: project build run install notarize dmg publish clean

# The Xcode project is generated from project.yml and isn't checked in.
project:
	@xcodegen generate --quiet

# Build output is filtered to errors, warnings in our code, and the result
# line, but the exit status is xcodebuild's.
build: project
	@mkdir -p $(DERIVED)
	@$(XCODEBUILD) -configuration Debug build > $(DERIVED)/last-build.log 2>&1; status=$$?; \
	grep -E "error:|warning:.*quick-styles/(App|Extension)/|BUILD (SUCCEEDED|FAILED)" $(DERIVED)/last-build.log | sort -u; \
	exit $$status

run: build
	@pkill -x "Quick Styles" || true
	open "$(DERIVED)/Build/Products/Debug/Quick Styles.app"

# Release build copied into /Applications.
install: project
	@mkdir -p $(DERIVED)
	@$(XCODEBUILD) -configuration Release build > $(DERIVED)/last-release.log 2>&1; status=$$?; \
	grep -E "error:|BUILD (SUCCEEDED|FAILED)" $(DERIVED)/last-release.log | sort -u; \
	exit $$status
	@pkill -x "Quick Styles" || true
	@rm -rf "/Applications/Quick Styles.app"
	cp -R "$(DERIVED)/Build/Products/Release/Quick Styles.app" /Applications/
	@echo "Installed /Applications/Quick Styles.app"

# Signed with Developer ID and notarized, in build/notarized/. Needs fastlane/.env.
notarize:
	@scripts/notarize.sh

# Unsigned disk image of the local Release build, for a look at the window.
dmg: install
	@scripts/dmg.sh "/Applications/Quick Styles.app"

# Ship a new version through Sparkle and GitHub Releases:
#   make publish NOTES=notes/1.1.md [VERSION=1.1]
publish:
	@NOTES="$(NOTES)" VERSION="$(VERSION)" scripts/publish.sh

clean:
	rm -rf $(DERIVED)
