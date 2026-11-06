# Quick Styles

A free, open source Safari extension for the Mac that lets you add your own CSS to any website.

Click the Quick Styles button in Safari's toolbar, type some CSS, and the page updates as you type. Next time you visit that site, your styles are already there. That's the whole app.

## Features

- **Per-site styles.** CSS you write applies to the whole site you're on (`www.` is ignored, so `www.example.com` and `example.com` share styles).
- **All-sites styles.** A second tab in the popup holds CSS that applies everywhere.
- **Live preview.** Changes apply as you type. No save button.
- **On/off switch** for each site, so you can compare with the original page.
- **Manage all styles.** One page lists every site you've styled, with search, editing, delete, and export/import to a JSON file for backups.
- **No accounts, no tracking, no network.** Your CSS is stored by Safari on your Mac and never leaves it.

## Install

1. Download `QuickStyles.dmg` from the [latest release](https://github.com/mattbirchler/quick-styles/releases/latest) and drag Quick Styles to Applications.
2. Open Quick Styles and click **Open Safari Extension Settings**.
3. Turn on Quick Styles, then allow it on all websites so your styles load automatically.

Quick Styles keeps itself up to date with [Sparkle](https://sparkle-project.org). You can also choose **Quick Styles > Check for Updates** in the app.

Requires macOS 14 Sonoma or later.

## Building

You need Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`). The Xcode project is generated from `project.yml`.

```bash
make build   # Debug build
make run     # build and open the app
```

To try a local build in Safari, turn on **Safari > Settings > Advanced > Show features for web developers**, then **Develop > Developer Settings > Allow unsigned extensions**.

Releases are covered in [RELEASING.md](RELEASING.md).

## How it works

The extension is a plain Manifest V3 web extension in `Extension/Resources`:

- `content.js` runs on every page, reads the styles for that site from `browser.storage.local`, and adds them in a `<style>` element at the end of the page so they win over the site's own CSS. It listens for storage changes, which is how the live preview works.
- `popup.html/js` is the toolbar editor.
- `options.html/js` is the Manage all styles page.

The Mac app in `App/` exists because Safari extensions ship inside an app. It shows whether the extension is on and handles updates.

## License

MIT. See [LICENSE](LICENSE).
