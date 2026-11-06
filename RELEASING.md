# Releasing Quick Styles

Quick Styles ships outside the App Store, from this repo's GitHub Releases.
Running copies find out about updates through Sparkle, which reads
`appcast.xml` on `main` (via raw.githubusercontent.com).

**The repo has to be public before the first release.** Sparkle and
people downloading the app can't reach releases or files in a private repo,
so `make publish` refuses to run while it's private:

```bash
gh repo edit mattbirchler/quick-styles --visibility public --accept-visibility-change-consequences
```

## Shipping a version

1. Write release notes for people in a Markdown file (for example
   `notes/1.1.md`): what changed and why they'd care. Headings, bullets,
   and paragraphs are supported. They show in Sparkle's update window and
   on the GitHub release.
2. From a clean `main` that matches `origin/main`:

   ```bash
   make publish NOTES=notes/1.1.md VERSION=1.1
   ```

   Leave `VERSION` off to keep the current version and only bump the build.

That one command:

- picks the next build number (one past both `project.yml` and the live
  feed) and commits it as `1.1 build 6`;
- archives a Release build, exports it signed with Developer ID, has Apple
  notarize it, staples the ticket, zips it, and builds a notarized disk
  image (`scripts/notarize.sh`, `scripts/dmg.sh`);
- signs the zip with the Quick Styles Sparkle key (keychain account
  `quick-styles`);
- tags the version commit `v1.1-6`, pushes, and creates the GitHub release
  with the disk image, a `QuickStyles.dmg` copy (so
  `releases/latest/download/QuickStyles.dmg` always works), the zip, and
  your notes;
- adds the version to `appcast.xml`, commits `release: 1.1 build 6`, and
  pushes. This push is the moment users see the update.

`DRY_RUN=1 make publish NOTES=...` does everything except the commits, the
upload, and the push, and leaves the feed it would publish in
`build/publish/appcast.xml`. It works while the repo is still private, so
run it before the first real release.

## One-time setup

- **Notarization credentials.** `fastlane/.env` (gitignored) holds the
  team's App Store Connect API key: `ASC_KEY_ID`, `ASC_ISSUER_ID`, and
  `ASC_KEY_PATH`. It's the same key Dict uses.
- **Sparkle key.** The private signing key lives in the login keychain
  under the account `quick-styles`; the public half is in `App/Info.plist`
  as `SUPublicEDKey`. Back the private key up (1Password) with:

  ```bash
  scripts/sparkle-tools.sh
  vendor/sparkle/bin/generate_keys --account quick-styles -x ~/Desktop/quick-styles-sparkle-key.txt
  ```

  then delete the file. On a new Mac, import it with
  `generate_keys --account quick-styles -f quick-styles-sparkle-key.txt`.
  Without this key no future update can be signed.
- **Tools.** XcodeGen (`brew install xcodegen`). `scripts/sparkle-tools.sh`
  fetches Sparkle's `sign_update` into `vendor/sparkle` (gitignored), and
  `scripts/dmg.sh` installs dmgbuild into `vendor/dmgbuild`. Both run
  automatically.

## If something goes wrong

- **Notarization rejected.** The script prints Apple's log. Fix, then rerun
  `make publish` (`git reset --soft HEAD~1` first to drop the version
  commit from the failed run, if you like).
- **Release created but the push failed.** Run `git push origin main`.
- **Sparkle says the update can't be verified.** The zip was signed with a
  different key than the `SUPublicEDKey` people have. Don't rotate keys;
  restore the backed-up private key.
