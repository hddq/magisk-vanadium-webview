#!/system/bin/sh
# Vanadium SystemWebView — post-fs-data.sh
# Runs at post-fs-data mode (before Zygote starts).
# Sets SELinux context early so the WebView APK is ready before apps launch.

MODDIR="${0%/*}"
WEBVIEW_APK="$MODDIR/system/app/webview/webview.apk"
CONFIG_APK="$MODDIR/system/app/VanadiumConfig/VanadiumConfig.apk"
OVERLAY_APK="$MODDIR/system/product/overlay/VanadiumWebViewProviderOverlay.apk"

for APK_PATH in "$WEBVIEW_APK" "$CONFIG_APK" "$OVERLAY_APK"; do
    if [ -f "$APK_PATH" ]; then
        chcon u:object_r:system_file:s0 "$APK_PATH" 2>/dev/null || true
    fi
done
