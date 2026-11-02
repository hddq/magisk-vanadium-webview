# Vanadium SystemWebView — Magisk Module

![Build Status](https://github.com/hddq/magisk-vanadium-webview/actions/workflows/build.yml/badge.svg)
![Latest Release](https://img.shields.io/github/v/release/hddq/magisk-vanadium-webview)
![Downloads](https://img.shields.io/github/downloads/hddq/magisk-vanadium-webview/total)

A Magisk module that adds [Vanadium WebView](https://github.com/grapheneos/vanadium) as a selectable provider alongside the existing Android WebView.

## Requirements
- arm64-v8a architecture
- Magisk v20.4+
- Android 14 (API 34) or newer

## Features

- **Side-by-side provider** — keeps the existing Google WebView installed and adds Vanadium as a selectable provider
- **Automatic updates** — Magisk Manager detects new versions via `updateJson`
- **Zero-touch CI/CD** — GitHub Actions checks the Vanadium WebView APK on GrapheneOS's default branch every 24 hours

## Installation

### From GitHub Releases (recommended)

1. Download the latest `VanadiumSystemWebView-*.zip` from [Releases](../../releases)
2. Open **Magisk Manager** → Modules → Install from storage
3. Select the downloaded zip
4. Reboot

### Auto-updates

Once installed, Magisk Manager will automatically detect new versions in the **Modules** tab. Just tap "Update" when prompted.

## Module Structure

```
module/
├── META-INF/
│   └── com/google/android/
│       ├── update-binary        # Magisk installer bootstrap
│       └── updater-script       # Required placeholder
├── system/
│   ├── app/
│   │   ├── webview/
│   │   │   └── webview.apk
│   │   └── VanadiumConfig/
│   │       └── VanadiumConfig.apk
│   └── product/overlay/
│       └── VanadiumWebViewProviderOverlay.apk
├── module.prop                  # Module metadata + updateJson
├── customize.sh                 # Install-time script
└── post-fs-data.sh              # Early boot SELinux context
```

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/build.yml`):

1. Runs on a 24-hour schedule (04:00 UTC daily) + manual dispatch
2. Queries GitLab for the latest commit that changed either `prebuilt/arm64-multilib/VanadiumWebView.apk` or `prebuilt/VanadiumConfig.apk` on the repository's default branch (HEAD)
3. Checks whether a GitHub Release already exists for that source commit; if it does, exits without downloading the APKs
4. If the APK changed:
   - Downloads the arm64 multi-ABI APK from that exact commit, so it can be installed on arm64 ROMs that also support 32-bit apps
   - Downloads the matching Vanadium Config APK
   - Builds and signs the framework resource overlay for the release; it supplies the supported Google/AOSP providers plus Vanadium
   - Reads its version name and minimum Android API level
   - Creates a release tag from the APK version and source commit
   - Patches `module.prop` in the release ZIP with the module version and versionCode
   - Packages the Magisk module zip
   - Updates `update.json` for Magisk Manager auto-updates
   - Publishes a GitHub Release with the zip attached
   - Commits the refreshed `update.json` to this repository for Magisk Manager
5. If a release for the source commit already exists, exits cleanly

Vanadium Config is a data-only package with Vanadium feature flags and content-filter lists. It is not required for Android to load the WebView; without it, Vanadium falls back to Chromium's standard filter lists. The module includes the matching config APK so those Vanadium-specific settings are available.

Before running the workflow, configure the repository secrets `VANADIUM_OVERLAY_KEYSTORE_B64` and `VANADIUM_OVERLAY_KEYSTORE_PASSWORD`. Create a PKCS12 keystore once, then put its base64 output and password in those secrets:

```sh
keytool -genkeypair -noprompt -storetype PKCS12 \
  -keystore vanadium-overlay.p12 -storepass 'choose-a-password' \
  -keypass 'choose-a-password' -alias vanadium-webview-overlay \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Vanadium WebView Overlay, O=Vanadium WebView Module"
base64 -w0 vanadium-overlay.p12
```

Keep the same keystore for future releases so Android sees the overlay as the same package. The workflow puts the generated overlay only in the release ZIP; it does not commit APKs to the repository.

The framework overlay registers Vanadium alongside the Google/AOSP provider entries shipped in this module without changing the selected provider. After flashing and rebooting, choose **Vanadium WebView** under **Developer options → WebView implementation**. Vanadium currently requires Android 14 or newer.
