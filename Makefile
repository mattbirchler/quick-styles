PROJECT = QuickStyles.xcodeproj
SCHEME = QuickStyles
DERIVED = build
LSREGISTER = /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
INSTALLED = /Applications/Quick Styles.app
XCODEBUILD = xcodebuild -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED) -destination 'platform=macOS'

.PHONY: project build run install unregister-builds notarize dmg publish clean

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

# Release build copied into /Applications. Afterwards the /Applications copy
# is the only one Safari knows about (see unregister-builds).
install: project
	@mkdir -p $(DERIVED)
	@$(XCODEBUILD) -configuration Release build > $(DERIVED)/last-release.log 2>&1; status=$$?; \
	grep -E "error:|BUILD (SUCCEEDED|FAILED)" $(DERIVED)/last-release.log | sort -u; \
	exit $$status
	@pkill -x "Quick Styles" || true
	@rm -rf "$(INSTALLED)"
	cp -R "$(DERIVED)/Build/Products/Release/Quick Styles.app" /Applications/
	@echo "Installed $(INSTALLED)"
	@$(MAKE) --no-print-directory unregister-builds

# Every copy of the app under build/ registers its own Safari extension, so
# Safari lists Quick Styles more than once. Delete the Debug and Release
# builds (app and loose extension), unregister everything else under build/ (notarized release files
# stay on disk), and leave /Applications as the only registered copy.
unregister-builds:
	@pkill -x "Quick Styles" || true
	@find "$(DERIVED)" -type d -prune \( -name "Quick Styles.app" -o -name "Quick Styles Extension.appex" \) 2>/dev/null | while IFS= read -r bundle; do \
		case "$$bundle" in *.app) pluginkit -r "$$bundle/Contents/PlugIns/Quick Styles Extension.appex" 2>/dev/null || true ;; \
		*) pluginkit -r "$$bundle" 2>/dev/null || true ;; esac; \
		$(LSREGISTER) -u "$$bundle" 2>/dev/null || true; \
	done
	@for config in Debug Release; do \
		rm -rf "$(DERIVED)/Build/Products/$$config/Quick Styles.app" "$(DERIVED)/Build/Products/$$config/Quick Styles Extension.appex"; \
	done
	@if [ -d "$(INSTALLED)" ]; then \
		$(LSREGISTER) -f "$(INSTALLED)"; \
		open -g "$(INSTALLED)"; \
		echo "Only $(INSTALLED) is registered with Safari"; \
	else \
		echo "Removed build copies. Nothing is installed in /Applications; run make install."; \
	fi

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
