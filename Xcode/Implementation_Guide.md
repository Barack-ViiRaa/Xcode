# ViiRaa iOS App - Implementation Guide

## Overview

This document provides step-by-step instructions for setting up and deploying the ViiRaa iOS application based on the [Product Requirements Document](Product%20Requirements%20Document.md) and [Software Development Documentation](Software%20Development%20Documentation.md).

---

## Table of Contents

1. [Project Setup](#project-setup)
2. [Xcode Project Creation](#xcode-project-creation)
3. [Dependencies Installation](#dependencies-installation)
4. [Configuration](#configuration)
5. [Development Workflow](#development-workflow)
6. [Testing](#testing)
7. [TestFlight Deployment](#testflight-deployment)
8. [App Store Submission](#app-store-submission)

---

## Project Setup

### Prerequisites Checklist

- [ ] macOS 13.0+ (Ventura or later)
- [ ] Xcode 14.0+ installed
- [ ] Apple Developer Account (Individual or Organization)
- [ ] Supabase project credentials
- [ ] PostHog account and API key
- [ ] Git installed

### Initial Setup

1. **Clone or Download the Project**

   The iOS app source code has been generated in the `ViiRaaApp/` directory with the following structure:

   ```
   ViiRaaApp/
   ├── ViiRaaApp/
   │   ├── App/
   │   ├── Core/
   │   ├── Features/
   │   ├── Services/
   │   ├── Models/
   │   ├── Utilities/
   │   └── Resources/
   ├── Package.swift
   ├── README.md
   └── .gitignore
   ```

---

## Xcode Project Creation

Since we've generated the Swift source files, you now need to create an Xcode project to build and run the app.

### Step 1: Create New Xcode Project

1. Open Xcode
2. Select **File > New > Project**
3. Choose **iOS > App**
4. Click **Next**

### Step 2: Configure Project Settings

Fill in the following details:

| Field | Value |
|-------|-------|
| **Product Name** | ViiRaaApp |
| **Team** | Select your Apple Developer Team |
| **Organization Identifier** | com.viiraa (or your organization) |
| **Bundle Identifier** | com.viiraa.app |
| **Interface** | SwiftUI |
| **Language** | Swift |
| **Use Core Data** | Unchecked |
| **Include Tests** | Checked |

Click **Next** and save the project to the parent directory of `ViiRaaApp/`.

### Step 3: Replace Generated Files

1. Delete the default generated files in Xcode:
   - `ViiRaaApp.swift` (default one)
   - `ContentView.swift`
   - Any other generated files

2. **Add Existing Files** to Xcode:
   - Right-click on `ViiRaaApp` folder in Project Navigator
   - Select **Add Files to "ViiRaaApp"...**
   - Navigate to the generated `ViiRaaApp/ViiRaaApp/` directory
   - Select all folders (App, Core, Features, Services, Models, Utilities, Resources)
   - Check **Copy items if needed**
   - Check **Create groups**
   - Click **Add**

### Step 4: Configure Info.plist

1. In Project Navigator, select the project (top level)
2. Select the **ViiRaaApp** target
3. Go to **Info** tab
4. Right-click in the list and select **Open As > Source Code**
5. Replace the contents with the generated `Info.plist` from `ViiRaaApp/ViiRaaApp/Resources/Info.plist`

### Step 5: Configure Build Settings

1. Select **ViiRaaApp** target
2. Go to **Build Settings** tab
3. Search for **iOS Deployment Target**
4. Set to **iOS 14.0**

---

## Dependencies Installation

### Option 1: Swift Package Manager (Recommended)

1. In Xcode, select **File > Add Packages...**

2. **Add Supabase Swift SDK:**
   - Enter URL: `https://github.com/supabase/supabase-swift.git`
   - Dependency Rule: **Up to Next Major Version** - `2.0.0`
   - Click **Add Package**
   - Select **Supabase** library
   - Click **Add Package**

3. **Add PostHog iOS SDK:**
   - Select **File > Add Packages...** again
   - Enter URL: `https://github.com/PostHog/posthog-ios.git`
   - Dependency Rule: **Up to Next Major Version** - `3.0.0`
   - Click **Add Package**
   - Select **PostHog** library
   - Click **Add Package**

4. **Verify Dependencies:**
   - In Project Navigator, expand **Package Dependencies**
   - You should see:
     - `supabase-swift`
     - `posthog-ios`

### Option 2: CocoaPods (Alternative)

1. **Install CocoaPods:**

   ```bash
   sudo gem install cocoapods
   ```

2. **Create Podfile:**

   In the project directory, create a file named `Podfile`:

   ```ruby
   platform :ios, '14.0'
   use_frameworks!

   target 'ViiRaaApp' do
     pod 'Supabase', '~> 2.0'
     pod 'PostHog', '~> 3.0'
   end
   ```

3. **Install Pods:**

   ```bash
   cd ViiRaaApp
   pod install
   ```

4. **Open Workspace:**

   ```bash
   open ViiRaaApp.xcworkspace
   ```

   **Important:** Always use `.xcworkspace` (not `.xcodeproj`) when using CocoaPods.

---

## Configuration

### Step 1: Update Constants

1. Open `ViiRaaApp/Utilities/Constants.swift`

2. Replace placeholder values with your actual credentials:

   ```swift
   // Supabase Configuration
   static let supabaseURL = "https://efwiicipqhurfcpczmnw.supabase.co"
   static let supabaseAnonKey = "YOUR_ACTUAL_SUPABASE_ANON_KEY"

   // PostHog Configuration
   static let posthogAPIKey = "YOUR_ACTUAL_POSTHOG_API_KEY"
   static let posthogHost = "https://us.posthog.com"
   ```

### Step 2: Get Supabase Credentials

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project: `efwiicipqhurfcpczmnw`
3. Navigate to **Settings > API**
4. Copy:
   - **URL**: This is your `supabaseURL`
   - **anon public**: This is your `supabaseAnonKey`

### Step 3: Get PostHog API Key

1. Go to [PostHog Dashboard](https://us.posthog.com/project/224201)
2. Navigate to **Settings > Project**
3. Copy **Project API Key**

### Step 4: Configure Code Signing

1. In Xcode, select **ViiRaaApp** target
2. Go to **Signing & Capabilities** tab
3. **Team**: Select your Apple Developer Team
4. **Bundle Identifier**: Verify it's `com.viiraa.app` (or your custom identifier)
5. Xcode should automatically provision a signing certificate

### Step 5: Configure Capabilities

1. Still in **Signing & Capabilities** tab
2. Click **+ Capability**
3. Add the following (for Phase 2):
   - **HealthKit**
   - **Background Modes**
     - Check: **Background fetch**
     - Check: **Background processing**

---

## Development Workflow

### Running the App

1. **Select a Simulator or Device:**
   - In Xcode toolbar, click the device selector
   - Choose an iOS Simulator (e.g., iPhone 15 Pro)
   - Or connect a physical iOS device

2. **Build and Run:**
   - Press `Cmd + R`
   - Or click the **Play** button in Xcode toolbar

3. **First Launch:**
   - App will display the authentication screen
   - Test sign-up and sign-in functionality
   - After authentication, dashboard should load in WebView

### Debugging WebView

1. **Enable Safari Web Inspector:**
   - Run app on simulator or device
   - Open Safari on Mac
   - In Safari menu: **Develop > [Your Device/Simulator] > localhost**
   - Inspect console, network requests, and DOM

2. **Check JavaScript Bridge:**
   - In Safari Web Inspector Console, test:
     ```javascript
     window.webkit.messageHandlers.nativeApp.postMessage({
       type: 'analytics',
       payload: {
         name: 'test_event',
         properties: { test: true }
       }
     });
     ```

### Common Development Tasks

#### Sign Out Flow

**Important**: Sign out is handled entirely by the web dashboard, not native iOS.

1. User signs out within the web dashboard interface
2. Web dashboard sends "logout" message to iOS app via JavaScript bridge:
   ```javascript
   window.webkit.messageHandlers.nativeApp.postMessage({
     type: 'logout'
   });
   ```
3. iOS app receives message and calls `AuthManager.shared.signOut()`
4. User is returned to login screen

**No native iOS sign out button** - this simplifies the architecture and prevents redundancy.

#### Refresh WebView

```swift
// In app, navigate to Dashboard
// Tap refresh button in navigation bar
```

#### Session Sharing Between iOS and Web

**Critical Implementation**: To prevent double login, the iOS app must inject the complete Supabase session into the WebView's localStorage.

**Implementation Steps**:

1. User authenticates via iOS native login
2. iOS app receives full Supabase session from Supabase Swift SDK
3. Session is injected into WebView at two points:
   - Before page load (via `WKUserScript`)
   - After page load (via `evaluateJavaScript`)
4. Session data includes:
   - `access_token`: JWT access token
   - `refresh_token`: Refresh token
   - `expires_in`: Expiration time
   - `token_type`: Token type ("bearer")
   - `user`: User object (id, email, aud, role)
5. Stored in localStorage with key: `sb-{project-id}-auth-token`
6. Web dashboard automatically recognizes session and shows authenticated content

**Code Example**:
```swift
private func injectSession(webView: WKWebView, session: Session) {
    let script = """
    const sessionData = {
        access_token: '\(session.accessToken)',
        refresh_token: '\(session.refreshToken)',
        expires_in: \(session.expiresIn),
        token_type: '\(session.tokenType)',
        user: {
            id: '\(session.user.id)',
            email: '\(session.user.email)',
            aud: 'authenticated',
            role: 'authenticated'
        }
    };
    localStorage.setItem('sb-efwiicipqhurfcpczmnw-auth-token',
                         JSON.stringify(sessionData));
    """
    webView.evaluateJavaScript(script)
}
```

#### Clear Keychain (Fresh Start)

1. Open **Xcode > Debug > Delete All Breakpoints**
2. Stop app
3. Delete app from simulator/device
4. Clean Build Folder: `Cmd + Shift + K`
5. Rebuild and run

---

## Testing

### Manual Testing Checklist

Test the following flows:

#### Authentication
- [ ] Sign up with email/password
- [ ] Sign in with email/password
- [ ] Sign in with Google OAuth
- [ ] Error handling for invalid credentials
- [ ] Session persists after app restart
- [ ] **Single Sign-On**: After iOS login, web dashboard automatically authenticates (no second login prompt)
- [ ] Session is properly injected into WebView localStorage
- [ ] Sign out via web dashboard clears both web and iOS sessions

#### Dashboard
- [ ] Dashboard WebView loads successfully
- [ ] User can scroll and interact with dashboard
- [ ] Analytics events are tracked (check PostHog dashboard)
- [ ] Menu button opens options
- [ ] Refresh button reloads WebView

#### Navigation
- [ ] Tab bar navigation works (Dashboard ↔ Chat)
- [ ] Chat placeholder screen displays correctly

#### Edge Cases
- [ ] App handles no internet connection gracefully
- [ ] App handles Supabase API errors
- [ ] WebView handles navigation errors
- [ ] Authentication token refresh works

### Unit Testing

Run unit tests in Xcode:

```bash
Cmd + U
```

### UI Testing

To add UI tests:

1. In Project Navigator, right-click on `ViiRaaAppUITests`
2. Select **New File > UI Test Case Class**
3. Implement test cases based on checklist above

---

## TestFlight Deployment

### Phase 1: Internal Testing (No App Review Required)

#### Step 1: Prepare for Archive

1. **Update Version Number:**
   - Select **ViiRaaApp** target
   - Go to **General** tab
   - Set **Version**: `1.0.0`
   - Set **Build**: `1`

2. **Set Build Configuration to Release:**
   - In Xcode toolbar, select **Any iOS Device (arm64)**

#### Step 2: Archive the App

1. In Xcode menu: **Product > Archive**
2. Wait for archive to complete (may take several minutes)
3. Organizer window will open automatically

**Troubleshooting Archive Build Errors:**

If you encounter "No profiles for 'com.viiraa.app' were found" error:

1. **Solution A: Automatic Provisioning (Recommended)**
   - In Xcode, select your project target
   - Go to **Signing & Capabilities** tab
   - Ensure **Automatically manage signing** is checked
   - Select your Team (should show your Apple ID)
   - Clean Build Folder: **Product → Clean Build Folder** (⇧⌘K)
   - Try archiving again

2. **Solution B: Manual Profile Creation**
   - Go to [Apple Developer](https://developer.apple.com/account)
   - Navigate to **Certificates, Identifiers & Profiles**
   - Create App ID if not exists:
     - Click **Identifiers** → **+**
     - Select **App IDs** → Continue
     - Select **App** → Continue
     - Bundle ID: `com.viiraa.app`
     - Capabilities: Select **HealthKit**
   - Create Provisioning Profile:
     - Click **Profiles** → **+**
     - Select **App Store** (for distribution)
     - Select your App ID
     - Select your distribution certificate
     - Download and double-click to install

3. **Solution C: Fix Code Signing in project.pbxproj**
   - The project has been configured with:
     ```
     CODE_SIGN_IDENTITY = "Apple Development";
     "CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Developer";
     CODE_SIGN_STYLE = Automatic;
     ```
   - This ensures proper signing for both Debug and Release configurations

**Note about "No devices" warning:**
- This warning is normal for App Store distribution
- You only need registered devices for Development/Ad Hoc builds
- For TestFlight and App Store, no device registration is required

#### Step 3: Validate Archive

1. In Organizer, select your archive
2. Click **Validate App**
3. Select your distribution certificate and provisioning profile
4. Click **Validate**
5. Fix any errors or warnings

#### Step 4: Distribute to App Store Connect

1. Click **Distribute App**
2. Select **App Store Connect**
3. Select **Upload**
4. Follow the prompts to sign and upload
5. Wait for upload to complete (may take 10-30 minutes)

#### Step 5: Configure TestFlight in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps > ViiRaa > TestFlight**
3. Wait for build to appear (may take a few minutes after upload)
4. Select your build
5. **Provide Export Compliance Information:**
   - Does your app use encryption? **Yes**
   - Does it qualify for exemption? **Yes** (for HTTPS only)
6. Once processed, build status will show **Ready to Test**

#### Step 6: Add Internal Testers

1. In TestFlight tab, go to **Internal Testing**
2. Click **+ (plus icon)** to create a new group
3. Name the group: "Internal Team"
4. Add testers by email:
   - Development team (5 members)
   - Product team (3 members)
   - QA team (2 members)
5. Click **Add Build to Test** and select your build
6. Optionally provide **What to Test** instructions:

   ```
   Phase 1 MVP Testing:

   Please test the following:
   - Sign up and sign in functionality
   - Dashboard loading and interaction
   - Tab navigation (Dashboard ↔ Chat)
   - Session persistence (close and reopen app)
   - Sign out functionality

   Known Issues:
   - Chat tab is placeholder (Phase 2)

   Report bugs in Slack #ios-testing channel.
   ```

7. Click **Start Testing**

#### Step 7: Testers Install the App

1. Testers receive an email invitation
2. Install **TestFlight** app from App Store (if not already installed)
3. Open invitation email on iOS device
4. Tap **View in TestFlight**
5. Tap **Accept** and **Install**

---

## App Store Submission

### Phase 2: Public Release (Requires App Review)

**Prerequisites:**
- [ ] Phase 1 TestFlight testing completed successfully
- [ ] All critical bugs fixed
- [ ] HealthKit integration implemented and tested
- [ ] Privacy policy URL ready
- [ ] App Store screenshots prepared
- [ ] App Store description written
- [ ] Support URL and marketing URL ready

#### Step 1: Prepare App Store Materials

1. **Screenshots (Required Sizes):**
   - iPhone 6.5" (1284 x 2778 pixels) - 3-10 screenshots
   - iPhone 5.5" (1242 x 2208 pixels) - 3-10 screenshots
   - iPad 12.9" (2048 x 2732 pixels) - 3-10 screenshots

   **Tip**: Use Xcode Simulator to capture screenshots:
   - Run app on different simulators
   - Press `Cmd + S` to save screenshot

2. **App Icon:**
   - 1024 x 1024 pixels PNG (no transparency)
   - Placed in `Assets.xcassets/AppIcon.appiconset/`

3. **App Preview Video (Optional):**
   - Up to 30 seconds
   - Same dimensions as screenshots

#### Step 2: Create App Store Listing

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps > ViiRaa**
3. Click **+ (plus icon)** next to **iOS App**

**App Information:**

| Field | Value |
|-------|-------|
| **Name** | ViiRaa |
| **Subtitle** | From Weight Control, To Body Intelligence |
| **Category** | Health & Fitness |
| **Secondary Category** | Lifestyle (optional) |

**Privacy:**
- Privacy Policy URL: `https://www.viiraa.com/ViiRaa_Privacy_Policy_Notice_US_20250808.pdf`

**Pricing:**
- Price: **Free**

#### Step 3: Prepare Version Information

1. Click on **1.0 Prepare for Submission**

**Description:**

```
ViiRaa helps you master your metabolism through continuous glucose monitoring (CGM) and personalized coaching.

KEY FEATURES:

• Personalized Dashboard
Access your health metrics, glucose insights, and progress tracking all in one place.

• Apple HealthKit Integration
Seamlessly sync your CGM data, weight, and activity from Apple Health for comprehensive tracking.

• AI-Powered Coaching
Get real-time guidance from miniViiRaa, your personal AI health coach (coming soon).

• Bootcamp Programs
Join guided 14-day programs to master glucose control and optimize your metabolism.

• Community Support
Connect with others on the same journey and share your progress.

ABOUT VIIRAA:

ViiRaa transforms weight control into body intelligence. We believe understanding your glucose responses is the key to sustainable health and energy optimization.

Whether you're looking to lose weight, improve energy, manage prediabetes, or optimize performance, ViiRaa provides the data and coaching you need to succeed.

SUBSCRIPTIONS:

ViiRaa offers bootcamp programs with pricing displayed at checkout. Programs include CGM sensors, coaching, and community support.

HEALTH DATA:

ViiRaa integrates with Apple Health to:
- Read glucose data from compatible CGM devices
- Track weight and body composition changes
- Monitor activity and fitness data

Your health data is never shared with third parties and remains private.
```

**Keywords** (separated by commas, max 100 characters):

```
glucose,cgm,health,metabolism,weight loss,diabetes,prediabetes,fitness,wellness,coaching
```

**Support URL:**
- `https://viiraa.com/support` (or create a support page)

**Marketing URL:**
- `https://viiraa.com`

#### Step 4: Upload Screenshots

1. In **App Store > 1.0 Prepare for Submission**
2. Scroll to **App Previews and Screenshots**
3. Upload screenshots for each device size
4. Drag to reorder (first screenshot is most important)

#### Step 5: Build Selection

1. Scroll to **Build** section
2. Click **+ (plus icon)**
3. Select your TestFlight build
4. Click **Done**

#### Step 6: Age Rating

1. Scroll to **Age Rating**
2. Click **Edit**
3. Answer questionnaire (should result in 4+ rating)
4. Save

#### Step 7: App Review Information

Provide contact info and demo account:

**Contact Information:**
- First Name: [Your Name]
- Last Name: [Your Name]
- Phone Number: [Your Phone]
- Email: dev@viiraa.com

**Demo Account:**
- Username: dev@viiraa.com
- Password: [Provide secure password]

**Notes:**

```
ViiRaa is a health and wellness application that combines web-based content delivery with native iOS functionality:

1. Apple HealthKit Integration:
   - Reads CGM (glucose) data from Health app
   - Reads weight and activity data
   - Provides personalized insights based on health metrics

2. Native iOS Features:
   - Secure Keychain-based authentication
   - Native tab navigation
   - JavaScript bridge for seamless web integration

3. Web Content Integration:
   - Dashboard uses WKWebView for rapid feature updates
   - Ensures consistency across platforms
   - Enables real-time data synchronization

The app provides genuine value to iOS users through HealthKit integration, enabling comprehensive health tracking not possible through a web browser alone.

TESTING INSTRUCTIONS:
1. Sign in with provided demo account
2. Grant HealthKit permissions when prompted
3. Dashboard will load with demo data
4. Navigate between Dashboard and Chat tabs
5. Check Settings menu for additional options

Please note: Full HealthKit functionality requires connected CGM device. Demo account has simulated data for review purposes.
```

#### Step 8: Export Compliance

1. Scroll to **Export Compliance**
2. Answer questions:
   - **Is your app designed to use cryptography?** Yes
   - **Does your app qualify for exemption?** Yes (HTTPS only)

#### Step 9: Submit for Review

1. Review all information for accuracy
2. Click **Add for Review** (top right)
3. Click **Submit for Review**
4. Confirm submission

#### Step 10: Review Process

- **Review Time**: Typically 24-48 hours
- **Status Updates**: Check App Store Connect for status changes
- **Possible Outcomes:**
  - **Approved**: App is ready to release
  - **Rejected**: Review team provides feedback; address issues and resubmit
  - **In Review**: Under active review
  - **Pending Developer Release**: Approved, waiting for manual release

#### Step 11: Release

Once approved:

1. **Manual Release:**
   - Click **Release This Version**
   - App goes live within 24 hours

2. **Automatic Release:**
   - Configure in **Version Release** settings
   - App releases immediately upon approval

---

## Post-Launch

### Monitor App Performance

1. **Crash Reporting:**
   - Xcode > Organizer > Crashes
   - Monitor for crashes and address critical issues

2. **Analytics:**
   - Check PostHog dashboard for user engagement
   - Track key metrics: DAU, session duration, retention

3. **App Store Reviews:**
   - Respond to user reviews within 48 hours
   - Address common complaints in updates

4. **User Feedback:**
   - Monitor support email (support@viiraa.com)
   - Create Slack channel for user feedback

### Update Cycle

**Bug Fixes**: Release within 1 week for critical issues
**Minor Updates**: Bi-weekly or monthly
**Major Updates**: Quarterly with new features

---

## Troubleshooting

### Build Errors

#### Supabase SDK Issues

**Error: "'Client' is not a member type of class 'SupabaseClient'"**
- **Cause**: Naming conflict between custom class and SDK type
- **Solution**:
  1. Rename your custom class from `SupabaseClient` to `SupabaseManager`
  2. Update all references: `SupabaseClient.shared` → `SupabaseManager.shared`
  3. Use `SupabaseClient` (from SDK) as the property type

**Error: "Cannot find type 'DatabaseClient' in scope"**
- **Cause**: Incorrect type name for database client
- **Solution**: Use `PostgrestClient` instead of `DatabaseClient`

**Error: "Extra arguments at positions #2, #3 in call" (Supabase initialization)**
- **Cause**: Using deprecated initialization API
- **Solution**: Simplify initialization to:
  ```swift
  client = SupabaseClient(
      supabaseURL: url,
      supabaseKey: Constants.supabaseAnonKey
  )
  ```

**Error: "Cannot find type 'AuthState' in scope"**
- **Cause**: Supabase v2.x changed auth state enum
- **Solution**: Replace `AuthState` with `AuthChangeEvent`:
  ```swift
  // Old
  case .signedIn(let session):

  // New
  case .signedIn, .tokenRefreshed, .initialSession:
  ```

**Error: "Cannot convert value of type 'TimeInterval' to expected argument type 'Int'"**
- **Cause**: Session `expiresIn` is now Double in Supabase v2.x
- **Solution**: Cast to Int when needed: `Int(supabaseSession.expiresIn)`

**Error: "Cannot convert value of type 'Auth.User' to expected argument type 'User'"**
- **Cause**: Supabase's Auth.User differs from custom User model
- **Solution**: Create conversion helper:
  ```swift
  private func convertUser(_ authUser: Auth.User) -> User {
      return User(
          id: authUser.id.uuidString,
          email: authUser.email ?? "",
          createdAt: authUser.createdAt,
          lastSignInAt: authUser.lastSignInAt,
          userMetadata: nil
      )
  }
  ```

#### PostHog SDK Issues

**Error: "Cannot find type 'PHGPostHog' in scope"**
- **Cause**: Using deprecated Objective-C SDK references
- **Solution**: Update to Swift SDK:
  ```swift
  // Old (Objective-C)
  PHGPostHog.setup(with: configuration)
  posthog?.capture(event)

  // New (Swift)
  PostHogSDK.shared.setup(config)
  PostHogSDK.shared.capture(event, properties: properties)
  ```

**Error: "Value of type 'PostHogConfig' has no member 'captureDeepLinks'"**
- **Cause**: Config option not supported in Swift SDK
- **Solution**: Remove the `captureDeepLinks` line from configuration

#### Swift Concurrency Issues

**Error: "Type 'AnalyticsManager' does not conform to protocol 'ObservableObject'"**
- **Cause**: `@MainActor` on class requires explicit `objectWillChange` publisher
- **Solution**: Add nonisolated publisher:
  ```swift
  @MainActor
  class AnalyticsManager: ObservableObject {
      nonisolated let objectWillChange = ObservableObjectPublisher()
      // ... rest of class
  }
  ```
- **Note**: Remember to import `Combine`

#### Project Configuration Issues

**Error: "Build input file cannot be found: '/251015-Xcode/251015-Xcode/Resources/Info.plist'"**
- **Cause**: Incorrect absolute path in project configuration
- **Solution**:
  1. Open `project.pbxproj` in text editor
  2. Find `INFOPLIST_FILE` entries
  3. Change from `/251015-Xcode/251015-Xcode/Resources/Info.plist`
  4. To relative path: `"251015-Xcode/Resources/Info.plist"`

**Error: "Cannot find 'UIApplication' in scope"**
- **Cause**: Missing UIKit import in AuthManager
- **Solution**: Add `import UIKit` at top of AuthManager.swift

#### General Swift Package Manager Issues

**Error: "No such module 'Supabase'" or "No such module 'PostHog'"**
- **Solution**:
  1. Verify dependencies in File > Project Settings > Package Dependencies
  2. Try: File > Packages > Reset Package Caches
  3. Clean build folder: Cmd + Shift + K
  4. Rebuild: Cmd + B

**Error: "Code signing failed"**
- **Solution**:
  - Check provisioning profiles in Signing & Capabilities
  - Verify Apple Developer account is active
  - Ensure bundle identifier matches provisioning profile

### Runtime Errors

**Error: "Supabase connection failed"**
- Check `Constants.supabaseURL` and `Constants.supabaseAnonKey`
- Verify network connectivity
- Check App Transport Security settings in Info.plist

**Error: "WebView not loading"**
- Use Safari Web Inspector to debug
- Check dashboard URL is correct
- Verify auth token is being injected

**Error: Authentication fails with valid credentials**
- Verify Supabase project credentials are correct
- Check that auth is enabled in Supabase dashboard
- Ensure email confirmation is disabled for testing

### TestFlight Issues

**Build not appearing in TestFlight:**
- Wait 10-30 minutes after upload
- Check for email from Apple about export compliance

**Testers cannot install:**
- Verify tester email is correct
- Check tester has TestFlight app installed
- Ensure build status is "Ready to Test"

### Quick Fix Reference

| Error Message | Quick Fix |
|--------------|-----------|
| 'Client' is not a member type | Rename class to `SupabaseManager` |
| Cannot find type 'DatabaseClient' | Use `PostgrestClient` |
| Cannot find type 'PHGPostHog' | Use `PostHogSDK.shared` |
| Cannot find type 'AuthState' | Use `AuthChangeEvent` |
| Type does not conform to 'ObservableObject' | Add `nonisolated let objectWillChange` |
| TimeInterval vs Int mismatch | Cast with `Int(value)` |
| Build input file cannot be found | Fix path in project.pbxproj |
| Cannot find 'UIApplication' | Add `import UIKit` |

---

## Next Steps

### Phase 2: HealthKit Integration - ✅ COMPLETED

**Implementation Date**: 2025-10-21

The following HealthKit features have been fully implemented:

1. ✅ HealthKit authorization and permission management
2. ✅ CGM data reading (blood glucose)
3. ✅ Weight tracking
4. ✅ Activity data integration (steps, active energy, exercise minutes)
5. ✅ Native glucose data display view with:
   - Latest reading card with color-coded range indicators
   - Statistics dashboard (average, time-in-range, min/max, std deviation)
   - Interactive glucose trend chart (iOS 16+)
   - Recent readings list with timestamps
   - Multi-timeframe support (today, week, month)
6. ✅ Glucose data models with range classification
7. ✅ Analytics integration for glucose data loading events

**Files Implemented**:
- `Services/HealthKit/HealthKitManager.swift`
- `Services/HealthKit/HealthDataModels.swift`
- `Features/HealthKit/GlucoseView.swift`
- `Core/Navigation/MainTabView.swift` (updated with Glucose tab)

**Navigation**: The glucose view is accessible via the "Glucose" tab (middle tab with drop icon) in the main navigation.

### Phase 3: Chat Integration

Implement miniViiRaa AI coach chat functionality:

1. Evaluate Mattermost or alternative chat platform
2. Create WebView-based chat interface
3. Integrate with existing Telegram dependency
4. Enable push notifications

---

## Resources

- [Product Requirements Document](Product%20Requirements%20Document.md)
- [Software Development Documentation](Software%20Development%20Documentation.md)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Supabase Swift SDK](https://github.com/supabase/supabase-swift)
- [PostHog iOS SDK](https://posthog.com/docs/libraries/ios)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

**Document Version**: 1.1
**Last Updated**: 2025-10-15
**Status**: Ready for Implementation

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-10-14 | Initial implementation guide |
| 1.1 | 2025-10-15 | Added comprehensive build error troubleshooting section with SDK-specific fixes |
