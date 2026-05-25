# Bidscube SDK — Deployment Guide for Flutter

This document explains how to prepare, version, test, and **release** the Bidscube Flutter plugin from **GitHub** (git tags + GitHub Releases). The package uses `publish_to: "none"` and is **not** published to pub.dev.

Checklist (high level)
- [ ] Update `pubspec.yaml` version and metadata
- [ ] Update `CHANGELOG.md` / release notes
- [ ] Run static analysis, formatting, and tests
- [ ] Build example app(s) for target platforms (Android / iOS as applicable)
- [ ] Commit and tag the release in git
- [ ] Push the tag — CI creates a **GitHub Release** (see `.github/workflows/release.yml`)
- [ ] Tell consumers to bump the `git` dependency `ref:` to the new tag

Prerequisites
- Dart and Flutter SDK installed and on PATH. Use the same SDK versions the project supports.
- If building iOS example, macOS with Xcode and CocoaPods is required.
- Git configured with push access to the repository.

Git remotes (important)
- **`origin`** — typically `https://github.com/...` (e.g. GitHub Desktop). HTTPS push from some terminals may require extra credential setup.
- **`github-ssh`** — `git@github.com:BidsCube/bidscube-sdk-flutter.git`. **Use this remote for pushes and tags from the CLI** when SSH keys are configured: `git push github-ssh master` and `git push github-ssh vX.Y.Z`.
- If `github-ssh` is missing locally, add it once:  
  `git remote add github-ssh git@github.com:BidsCube/bidscube-sdk-flutter.git`

How consumers depend on this package
- Add a **git** dependency with `ref:` set to a **tag** (recommended):

```yaml
dependencies:
  bidscube_sdk_flutter:
    git:
      url: https://github.com/BidsCube/bidscube-sdk-flutter.git
      ref: v1.2.2
```

- For private mirrors or SSH-only access, change `url` to a clone URL that works on the machine running `flutter pub get`.

Quick notes on commands
- Use `flutter pub publish --dry-run` from the repo root to validate the package layout before tagging (publishing to pub.dev is disabled via `publish_to: none`).

1) Update version and metadata
- Open `pubspec.yaml`.
- Bump the `version:` field. Follow pub version format: MAJOR.MINOR.PATCH+BUILD (build number is optional).
  - Example: `version: 1.2.3` -> `version: 1.2.4` if you're releasing a patch.
- Update other metadata if needed (homepage, repository, environment constraints).

PowerShell example:

```powershell
# show current version
Select-String -Path pubspec.yaml -Pattern "^version:" -Context 0,0

# open in your editor of choice (example uses code)
code pubspec.yaml
```

2) Update CHANGELOG and release notes
- Add an entry for the new version at the top of `CHANGELOG.md` using the "Keep a Changelog" style (recommended).
- Include short, accurate notes about what's changed (bug fixes, features, breaking changes).

3) Run preflight checks (static analysis, tests, formatting)
- Run package get, analyze, and tests. Fix any issues before tagging.

PowerShell commands:

```powershell
# fetch dependencies
flutter pub get

# run static analysis
flutter analyze

# run tests
flutter test

# optional: format codebase
dart format .
```

4) Build example app(s)
- Ensure example builds cleanly for the platforms you support.
- Android build (works on any OS with Android SDK):

```powershell
cd example
flutter pub get
flutter build apk --release
# or build appbundle
flutter build appbundle --release
cd ..
```

- iOS build (macOS required):

```powershell
cd example
flutter pub get
flutter build ios --release
cd ..
```

If you cannot build iOS (not on macOS), at minimum run a code analysis and test; note that you should still ensure CI covers macOS/iOS builds.

5) Dry-run package layout (recommended)
- Catches layout / pubspec issues without uploading anywhere.

```powershell
# from repository root
flutter pub publish --dry-run
```

Fix any issues reported by the dry-run (missing assets, invalid YAML, license, etc.).

6) Commit, tag, and push
- Commit changes to `pubspec.yaml`, `CHANGELOG.md`, and any other updated files.
- Create an annotated git tag for the release and push commits + tags.

PowerShell example:

```powershell
# stage changes
git add pubspec.yaml CHANGELOG.md

# create a commit
git commit -m "chore(release): bump version to x.y.z" # replace with the actual version

# create annotated tag
git tag -a vX.Y.Z -m "Release vX.Y.Z" # replace with actual version

# push commits and tag (use github-ssh from CLI, not origin, unless you prefer HTTPS)
git push github-ssh HEAD
git push github-ssh vX.Y.Z
# If you moved an existing tag to a new commit:
# git push github-ssh vX.Y.Z --force-with-lease
```

7) GitHub Release (automated)
- Pushing a tag matching `v*` triggers `.github/workflows/release.yml`: tests/analyze/dry-run, then a **GitHub Release** for that tag.
- Release notes include a copy-pastable `git` dependency snippet.

8) Post-release tasks
- Confirm the new release appears under **GitHub → Releases**.
- Update any internal docs or apps to point `ref:` at the new tag.

9) Optional: publishing to pub.dev later
- Remove or change `publish_to: "none"` in `pubspec.yaml`, configure [automated publishing](https://dart.dev/tools/pub/automated-publishing), add a separate workflow if desired. This is not part of the default flow for this repository.

Preflight checklist (detailed)
- [ ] pubspec version updated
- [ ] CHANGELOG.md updated
- [ ] All tests pass: `flutter test` (and platform tests if any)
- [ ] `flutter analyze` returns no new issues
- [ ] Example app builds for Android
- [ ] If applicable, example app builds for iOS (CI/macOS)
- [ ] `flutter pub publish --dry-run` succeeds
- [ ] Commit and push with annotated tag

Troubleshooting
- Invalid or missing files reported by dry-run: verify `pubspec.yaml` `assets:` and `publish_to:` settings.
- Missing README or LICENSE: keep both files in the repo root.
- **GitHub Release job fails with permissions:** ensure the workflow has `contents: write` on the release job (see `release.yml`). In org settings, allow `GITHUB_TOKEN` to create releases for this repo, or use a PAT stored as a secret and pass it to `softprops/action-gh-release` via the `token` input (advanced).

References
- Publishing packages (if you ever use pub.dev): https://dart.dev/tools/pub/publishing
- Automated publishing (GitHub + pub.dev): https://dart.dev/tools/pub/automated-publishing
