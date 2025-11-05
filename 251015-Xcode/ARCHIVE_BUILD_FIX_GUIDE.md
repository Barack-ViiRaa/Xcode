# iOS App Archive Build Fix Guide

## Date: October 27, 2025

## Issues Fixed

### ✅ 1. Invalid Bundle Identifier
**Problem**: `com.viiraa.-51015-Xcode` was invalid (contained dash after dot)
**Solution**: Changed to `com.viiraa.app`
**File**: `251015-Xcode.xcodeproj/project.pbxproj`

### ✅ 2. Invalid TARGETED_DEVICE_FAMILY
**Problem**: Value was `"1,iPhone"` which is invalid
**Solution**: Changed to `"1,2"` (iPhone and iPad support)
**File**: `251015-Xcode.xcodeproj/project.pbxproj`

### ✅ 3. Deprecated javaScriptEnabled
**Problem**: `configuration.preferences.javaScriptEnabled` deprecated in iOS 14.0
**Solution**: Changed to `configuration.defaultWebpagePreferences.allowsContentJavaScript`
**File**: `251015-Xcode/Core/WebView/DashboardWebView.swift`

### ✅ 4. Deprecated onChange
**Problem**: `onChange(of:perform:)` deprecated in iOS 17.0
**Solution**: Updated to use zero-parameter closure syntax
**File**: `251015-Xcode/Features/HealthKit/GlucoseView.swift`

## Remaining Setup Required in Xcode

### 1. Provisioning Profile Setup

Since you're getting the "No profiles for 'com.viiraa.app'" error, you need to:

1. **Open Xcode Project**
   ```bash
   open 251015-Xcode.xcodeproj
   ```

2. **Select Project Target**
   - Click on `251015-Xcode` project in navigator
   - Select the `251015-Xcode` target

3. **Configure Signing & Capabilities**
   - Go to "Signing & Capabilities" tab
   - Ensure "Automatically manage signing" is checked ✓
   - Select your Development Team (934S9W736Z)
   - Bundle Identifier should now be: `com.viiraa.app`

4. **Register App ID (if needed)**
   - Xcode should automatically create the App ID
   - If not, go to https://developer.apple.com/account
   - Navigate to Certificates, Identifiers & Profiles
   - Create new App ID with identifier: `com.viiraa.app`

### 2. Device Registration (Optional for Development)

The error "Your team has no devices" means you haven't registered any devices. This is OK for App Store distribution, but if you want to test on a real device:

1. **Connect an iPhone/iPad via USB**
2. **Trust the Computer** on your device
3. **Xcode will register it automatically**

OR manually add at https://developer.apple.com/account:
- Go to Devices
- Add device UDID

### 3. Archive Build Steps

After fixing the above:

1. **Select Generic iOS Device**
   - In Xcode toolbar, select "Any iOS Device (arm64)" as destination

2. **Clean Build Folder**
   ```
   Product → Clean Build Folder (⇧⌘K)
   ```

3. **Archive**
   ```
   Product → Archive
   ```

4. **Wait for Archive to Complete**
   - This may take 5-10 minutes
   - Check for any errors in build log

5. **Distribute App**
   - Organizer window will open automatically
   - Click "Distribute App"
   - Choose distribution method:
     - App Store Connect (for TestFlight/App Store)
     - Ad Hoc (for specific devices)
     - Development (for testing)

## Build Settings Summary

```
Bundle Identifier: com.viiraa.app
Team ID: 934S9W736Z
Code Signing: Automatic
Targeted Device Family: iPhone, iPad (1,2)
Minimum iOS Version: 14.0
```

## TestFlight Submission

Once archive succeeds:

1. **Upload to App Store Connect**
   - In Organizer → Distribute App
   - Select "App Store Connect"
   - Choose "Upload"

2. **Configure in App Store Connect**
   - Go to https://appstoreconnect.apple.com
   - Select your app
   - Go to TestFlight tab
   - Add internal testers (Lei: zl.stone1992@gmail.com)

## Common Issues & Solutions

### Issue: "No account for team"
**Solution**: Sign in to Xcode with your Apple ID
- Xcode → Settings → Accounts → Add Apple ID

### Issue: "Provisioning profile doesn't match"
**Solution**:
- Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- In Xcode: Product → Clean Build Folder
- Re-download profiles: Xcode → Settings → Accounts → Download Manual Profiles

### Issue: "Code signing identity not found"
**Solution**:
- Ensure you have a valid Apple Developer account
- Check that automatic signing is enabled
- Verify team selection is correct

## Verification

To verify all fixes are applied:

```bash
# Check bundle identifier
grep "PRODUCT_BUNDLE_IDENTIFIER" 251015-Xcode.xcodeproj/project.pbxproj
# Should show: com.viiraa.app

# Check device family
grep "TARGETED_DEVICE_FAMILY" 251015-Xcode.xcodeproj/project.pbxproj
# Should show: "1,2"

# Build for testing (not archive)
xcodebuild -project 251015-Xcode.xcodeproj -scheme 251015-Xcode -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Next Steps

1. ✅ Code fixes are complete
2. ⏳ Complete Xcode signing configuration
3. ⏳ Archive the app
4. ⏳ Upload to TestFlight
5. ⏳ Submit to App Store

---

**All code-level issues have been fixed. The remaining steps require configuration in Xcode's UI for code signing and provisioning profiles.**