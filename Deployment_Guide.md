# ViiRaa iOS App - Deployment Guide

**Version:** 1.7
**Last Updated:** December 16, 2025
**Document Owner:** Development Team

## 1. Overview

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
   - [App Privacy and Data Collection Disclosure](#91-app-privacy-and-data-collection-disclosure)
   - [Phase 2: Public Release](#92-phase-2-public-release-requires-app-review)
     - [Content Rights Documentation](#927-step-7-content-rights-documentation)
   - [Post-Launch](#93-post-launch)
9. [Junction SDK Integration](#junction-sdk-integration)

---

## 2. Project Setup

### 2.1. Prerequisites Checklist

- [ ] macOS 13.0+ (Ventura or later)
- [ ] Xcode 14.0+ installed
- [ ] Apple Developer Account (Individual or Organization)
- [ ] Supabase project credentials
- [ ] PostHog account and API key
- [ ] Git installed

### 2.2. Initial Setup

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

## 3. Xcode Project Creation

Since we've generated the Swift source files, you now need to create an Xcode project to build and run the app.

### 3.1. Step 1: Create New Xcode Project

1. Open Xcode
2. Select **File > New > Project**
3. Choose **iOS > App**
4. Click **Next**

### 3.2. Step 2: Configure Project Settings

Fill in the following details:

| Field                             | Value                             |
| --------------------------------- | --------------------------------- |
| **Product Name**            | ViiRaaApp                         |
| **Team**                    | Select your Apple Developer Team  |
| **Organization Identifier** | com.viiraa (or your organization) |
| **Bundle Identifier**       | com.viiraa.app                    |
| **Interface**               | SwiftUI                           |
| **Language**                | Swift                             |
| **Use Core Data**           | Unchecked                         |
| **Include Tests**           | Checked                           |

Click **Next** and save the project to the parent directory of `ViiRaaApp/`.

### 3.3. Step 3: Replace Generated Files

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

### 3.4. Step 4: Configure Info.plist

1. In Project Navigator, select the project (top level)
2. Select the **ViiRaaApp** target
3. Go to **Info** tab
4. Right-click in the list and select **Open As > Source Code**
5. Replace the contents with the generated `Info.plist` from `ViiRaaApp/ViiRaaApp/Resources/Info.plist`

### 3.5. Step 5: Configure Build Settings

1. Select **ViiRaaApp** target
2. Go to **Build Settings** tab
3. Search for **iOS Deployment Target**
4. Set to **iOS 14.0**

---

## 4. Dependencies Installation

### 4.1. Option 1: Swift Package Manager (Recommended)

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

### 4.2. Option 2: CocoaPods (Alternative)

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

## 5. Configuration

### 5.1. Step 1: Update Constants

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

### 5.2. Step 2: Get Supabase Credentials

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project: `efwiicipqhurfcpczmnw`
3. Navigate to **Settings > API**
4. Copy:
   - **URL**: This is your `supabaseURL`
   - **anon public**: This is your `supabaseAnonKey`

### 5.3. Step 3: Get PostHog API Key

1. Go to [PostHog Dashboard](https://us.posthog.com/project/224201)
2. Navigate to **Settings > Project**
3. Copy **Project API Key**

### 5.4. Step 4: Configure Code Signing

1. In Xcode, select **ViiRaaApp** target
2. Go to **Signing & Capabilities** tab
3. **Team**: Select your Apple Developer Team
4. **Bundle Identifier**: Verify it's `com.viiraa.app` (or your custom identifier)
5. Xcode should automatically provision a signing certificate

### 5.5. Step 5: Configure Capabilities

1. Still in **Signing & Capabilities** tab
2. Click **+ Capability**
3. Add the following (for Phase 2):
   - **HealthKit**
   - **Background Modes**
     - Check: **Background fetch**
     - Check: **Background processing**

---

## 6. Development Workflow

### 6.1. Version Control and Git Workflow

**Branch Strategy:**

The project uses a branch-based development workflow to ensure code quality and facilitate team collaboration.

**Development Branch:**
- Repository: https://github.com/Barack-ViiRaa/Xcode/tree/Development
- All active development work should be committed to the `development` branch
- The `development` branch serves as the integration branch for ongoing features

**Commit Best Practices:**

1. **Make Bite-Size Commits:**
   - Commit small, logical units of work frequently
   - Each commit should represent a single, focused change
   - This makes it easier for team members to review changes and track differences
   - Examples of good bite-size commits:
     - "Add glucose data fetching to HealthKitManager"
     - "Fix authentication error handling in AuthManager"
     - "Update UI layout for settings screen"

2. **Commit Message Guidelines:**
   - Use clear, descriptive commit messages
   - Start with a verb in present tense (Add, Fix, Update, Remove)
   - Keep the first line under 50 characters
   - Add detailed description if needed in subsequent lines

3. **Before Committing:**
   - Review your changes: `git diff`
   - Stage specific files: `git add <file>`
   - Commit with message: `git commit -m "Your descriptive message"`
   - Push to development branch: `git push origin development`

4. **Benefits of Bite-Size Commits:**
   - Easier code review for team members
   - Simplified debugging when issues arise
   - Better tracking of project history
   - Easier to revert specific changes if needed

**Example Workflow:**

```bash
# Make sure you're on the development branch
git checkout development

# Pull latest changes
git pull origin development

# Make your changes to the code
# ...

# Review what changed
git status
git diff

# Stage and commit specific changes
git add Xcode/Services/HealthKit/HealthKitManager.swift
git commit -m "Add glucose trend calculation to HealthKitManager"

# Push to development branch
git push origin development
```

### 6.2. Running the App

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

### 6.3. Debugging WebView

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

### 6.4. Common Development Tasks

#### 6.4.1. Sign Out Flow

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

#### 6.4.2. Refresh WebView

```swift
// In app, navigate to Dashboard
// Tap refresh button in navigation bar
```

#### 6.4.3. Session Sharing Between iOS and Web

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

#### 6.4.4. Clear Keychain (Fresh Start)

1. Open **Xcode > Debug > Delete All Breakpoints**
2. Stop app
3. Delete app from simulator/device
4. Clean Build Folder: `Cmd + Shift + K`
5. Rebuild and run

---

## 7. Testing

### 7.1. Manual Testing Checklist

Test the following flows:

#### 7.1.1. Authentication

- [ ] Sign up with email/password
- [ ] Sign in with email/password
- [ ] Sign in with Google OAuth
- [ ] Error handling for invalid credentials
- [ ] Session persists after app restart
- [ ] **Single Sign-On**: After iOS login, web dashboard automatically authenticates (no second login prompt)
- [ ] Session is properly injected into WebView localStorage
- [ ] Sign out via web dashboard clears both web and iOS sessions

#### 7.1.2. Dashboard

- [ ] Dashboard WebView loads successfully
- [ ] User can scroll and interact with dashboard
- [ ] Analytics events are tracked (check PostHog dashboard)
- [ ] Menu button opens options
- [ ] Refresh button reloads WebView

#### 7.1.3. Navigation

- [ ] Tab bar navigation works (Dashboard ↔ Chat)
- [ ] Chat placeholder screen displays correctly

#### 7.1.4. Edge Cases

- [ ] App handles no internet connection gracefully
- [ ] App handles Supabase API errors
- [ ] WebView handles navigation errors
- [ ] Authentication token refresh works

### 7.2. Unit Testing

Run unit tests in Xcode:

```bash
Cmd + U
```

### 7.3. UI Testing

To add UI tests:

1. In Project Navigator, right-click on `ViiRaaAppUITests`
2. Select **New File > UI Test Case Class**
3. Implement test cases based on checklist above

---

## 8. TestFlight Deployment

### 8.1. Phase 1: Internal Testing (No App Review Required)

#### 8.1.1. Step 1: Prepare for Archive

1. **Update Version Number:**

   - Select **ViiRaaApp** target
   - Go to **General** tab
   - Set **Version**: `1.0.0`
   - Set **Build**: `1`
2. **Set Build Configuration to Release:**

   - In Xcode toolbar, select **Any iOS Device (arm64)**

#### 8.1.2. Step 2: Archive the App

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

#### 8.1.3. Step 3: Validate Archive

1. In Organizer, select your archive
2. Click **Validate App**
3. Select your distribution certificate and provisioning profile
4. Click **Validate**
5. Fix any errors or warnings

#### 8.1.4. Step 4: Distribute to App Store Connect

1. Click **Distribute App**
2. Select **App Store Connect**
3. Select **Upload**
4. Follow the prompts to sign and upload
5. Wait for upload to complete (may take 10-30 minutes)

#### 8.1.5. Step 5: Configure TestFlight in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps > ViiRaa > TestFlight**
3. Wait for build to appear (may take a few minutes after upload)
4. Select your build
5. **Provide Export Compliance Information:**
   - Does your app use encryption? **Yes**
   - Does it qualify for exemption? **Yes** (for HTTPS only)
6. Once processed, build status will show **Ready to Test**

#### 8.1.6. Step 6: Add Internal Testers

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

#### 8.1.7. Step 7: Testers Install the App

1. Testers receive an email invitation
2. Install **TestFlight** app from App Store (if not already installed)
3. Open invitation email on iOS device
4. Tap **View in TestFlight**
5. Tap **Accept** and **Install**

---

## 9. App Store Submission

### 9.1. App Privacy and Data Collection Disclosure

As part of App Store submission, you must disclose all data collection practices. This section helps you answer Apple's data collection questionnaire accurately.

#### 9.1.1. Do You Collect Data from This App?

**Answer: Yes, we collect data from this app**

ViiRaa collects data for the following purposes:

- User authentication and account management
- Health data synchronization (via HealthKit)
- App analytics and performance monitoring
- Product functionality (glucose tracking, weight monitoring)

---

#### 9.1.2. Data Types Collected

Based on ViiRaa's functionality, the following data types are collected:

##### **Contact Info**

**✅ Email Address**

- **Purpose**: Account creation, authentication, and communication
- **Linked to User**: Yes
- **Used for Tracking**: No
- **Collection**: Required for sign-up and sign-in

**❌ Name** - Not collected
**❌ Phone Number** - Not collected
**❌ Physical Address** - Not collected
**❌ Other Contact Info** - Not collected

---

##### **Health & Fitness**

**✅ Health**

- **Data Collected**:
  - Blood glucose levels (from CGM devices via HealthKit)
  - Weight measurements
  - Body composition data (if available)
- **Purpose**: Core app functionality - glucose monitoring and metabolism tracking
- **Linked to User**: Yes
- **Used for Tracking**: No
- **Collection**: Required after HealthKit authorization

**✅ Fitness**

- **Data Collected**:
  - Steps (from HealthKit)
  - Active energy burned (from HealthKit)
  - Exercise minutes (from HealthKit)
- **Purpose**: Comprehensive health tracking and coaching
- **Linked to User**: Yes
- **Used for Tracking**: No
- **Collection**: Optional, requires HealthKit authorization

---

##### **Financial Info**

**❌ Payment Info** - Not directly collected

- Note: Payments are processed through Supabase/Stripe or in-app purchases. ViiRaa never has access to payment card numbers or bank accounts.

**❌ Credit Info** - Not collected
**❌ Other Financial Info** - Not collected

---

##### **Location**

**❌ Precise Location** - Not collected
**❌ Coarse Location** - Not collected

---

##### **Sensitive Info**

**❌ Sensitive Personal Data** - Not collected

- Note: While health data is sensitive, it's disclosed under "Health & Fitness" category, not this category.

---

##### **Contacts**

**❌ Contacts** - Not collected

- ViiRaa does not access the user's contact list or address book.

---

##### **User Content**

**❌ Emails or Text Messages** - Not collected
**❌ Photos or Videos** - Not collected
**❌ Audio Data** - Not collected
**❌ Gameplay Content** - Not applicable
**❌ Customer Support** - May be collected in future (optional disclosure)
**❌ Other User Content** - Not collected

---

##### **Browsing History**

**❌ Browsing History** - Not collected

- Note: The app uses WKWebView to display the dashboard, but does not track or log web browsing activity.

---

##### **Search History**

**❌ Search History** - Not collected

---

##### **Identifiers**

**✅ User ID**

- **Data Collected**: Supabase user ID (UUID)
- **Purpose**: Associate health data with user account
- **Linked to User**: Yes
- **Used for Tracking**: No
- **Collection**: Automatically created during sign-up

**✅ Device ID**

- **Data Collected**: Device identifier for analytics (PostHog anonymous ID)
- **Purpose**: App analytics, crash reporting, and performance monitoring
- **Linked to User**: No (anonymized)
- **Used for Tracking**: No
- **Collection**: Automatic, anonymous

**❌ Advertising Identifier (IDFA)** - Not collected

- ViiRaa does not use advertising identifiers.

---

##### **Purchases**

**✅ Purchase History**

- **Data Collected**: Bootcamp program purchases, subscription status
- **Purpose**: Product functionality, subscription management
- **Linked to User**: Yes
- **Used for Tracking**: No
- **Collection**: Only when user makes a purchase

---

##### **Usage Data**

**✅ Product Interaction**

- **Data Collected**:
  - App launches
  - Screen views (Dashboard, Chat, Settings)
  - Feature usage (glucose data views, sync events)
  - Button taps and user interactions
- **Purpose**: Analytics, product improvement, and feature optimization
- **Linked to User**: Yes (via PostHog)
- **Used for Tracking**: No
- **Collection**: Automatic

**❌ Advertising Data** - Not collected

- ViiRaa does not serve ads or collect advertising data.

**❌ Other Usage Data** - Not collected beyond what's listed above

---

##### **Diagnostics**

**✅ Crash Data**

- **Data Collected**: Crash logs, stack traces, device state at crash
- **Purpose**: Bug fixes, app stability improvements
- **Linked to User**: No (anonymized)
- **Used for Tracking**: No
- **Collection**: Automatic

**✅ Performance Data**

- **Data Collected**: App launch time, API response times, sync performance
- **Purpose**: Performance optimization
- **Linked to User**: No (anonymized)
- **Used for Tracking**: No
- **Collection**: Automatic via PostHog

**❌ Other Diagnostic Data** - Not collected

---

##### **Surroundings**

**❌ Environment Scanning** - Not collected

- ViiRaa does not use AR features.

---

##### **Body**

**❌ Hands** - Not collected
**❌ Head** - Not collected
**❌ Other Body Data** - Not collected

---

##### **Other Data**

**❌ Other Data Types** - Not collected

---

#### 9.1.3. Third-Party Partners and Data Sharing

ViiRaa uses the following third-party services that may collect data:

| Service                    | Purpose                  | Data Shared                          | Privacy Policy                                |
| -------------------------- | ------------------------ | ------------------------------------ | --------------------------------------------- |
| **Supabase**         | Authentication, database | Email, user ID, health data          | [Supabase Privacy](https://supabase.com/privacy) |
| **PostHog**          | Analytics                | Anonymous usage data, device info    | [PostHog Privacy](https://posthog.com/privacy)   |
| **Junction (Vital)** | HealthKit sync & ML      | Health data, user ID                 | [Vital Privacy](https://tryvital.io/privacy)     |
| **Apple HealthKit**  | Health data access       | None (data stays local or in iCloud) | [Apple Privacy](https://www.apple.com/privacy/)  |

**Important Notes**:

- Health data is encrypted in transit (TLS) and at rest (AES-256)
- ViiRaa has signed BAAs (Business Associate Agreements) with all health data processors
- No data is sold to third parties
- No data is used for advertising purposes

---

#### 9.1.4. Data Retention and Deletion

**User Control**:

- Users can request data deletion at any time via Settings > Account > Delete Account
- Deletion requests are processed within 30 days
- Health data can be deleted from HealthKit directly by the user

**Retention Policy**:

- Active user data: Retained while account is active
- Deleted account data: Removed within 30 days
- Analytics data: Aggregated and anonymized, retained for 2 years
- Crash logs: Retained for 90 days

---

#### 9.1.5. Completing Apple's Data Collection Form

When filling out the App Store Connect data collection questionnaire:

1. **Do you or your third-party partners collect data from this app?**

   - Select: **Yes, we collect data from this app**
2. **Select all data types collected:**

   - ✅ Contact Info → Email Address
   - ✅ Health & Fitness → Health (glucose, weight)
   - ✅ Health & Fitness → Fitness (steps, activity)
   - ✅ Identifiers → User ID
   - ✅ Identifiers → Device ID
   - ✅ Purchases → Purchase History
   - ✅ Usage Data → Product Interaction
   - ✅ Diagnostics → Crash Data
   - ✅ Diagnostics → Performance Data
3. **For each selected data type, indicate:**

   - **Used for Tracking?** → No (for all data types)
   - **Linked to User?** → Yes (except Device ID, Crash Data, Performance Data)
   - **Used for what purposes?**
     - Email: App Functionality, Account Management
     - Health/Fitness: App Functionality
     - User ID: App Functionality
     - Device ID: Analytics
     - Purchases: App Functionality
     - Usage Data: Analytics, Product Personalization
     - Diagnostics: App Functionality, Analytics
4. **Optional Disclosure Check:**

   - None of ViiRaa's data collection qualifies for optional disclosure because:
     - Health data is the primary app functionality (not optional)
     - Analytics is collected on an ongoing basis (not infrequent)
     - User consent is obtained once (not per-submission)

---

#### 9.1.6. Privacy Policy Requirements

Your privacy policy must include:

**Required Sections:**

- What data is collected and why
- How data is used
- Third-party services and data sharing
- User rights (access, deletion, correction)
- Data security measures
- Contact information for privacy inquiries
- HIPAA compliance statement
- Children's privacy (state app is 17+)

**Current Privacy Policy URL:**

- `https://www.viiraa.com/ViiRaa_Privacy_Policy_Notice_US_20250808.pdf`

**Action Items:**

- ✅ Ensure privacy policy includes all data types listed above
- ✅ Update policy date if changes are made
- ✅ Add PostHog analytics disclosure if missing
- ✅ Include Junction/Vital in third-party services section
- ✅ Specify data retention periods

---

#### 9.1.7. App Store Review Notes (Data Collection)

Include this in your App Review Information → Notes:

```
DATA COLLECTION AND PRIVACY:

ViiRaa collects the following data:

1. Health Data (via HealthKit):
   - Blood glucose levels from CGM devices
   - Weight and body composition
   - Activity data (steps, active energy, exercise)
   - Purpose: Core app functionality for glucose monitoring and metabolism tracking
   - User consent: Required via HealthKit authorization prompt

2. Account Information:
   - Email address for authentication
   - User ID (UUID) for data association
   - Purpose: Account management and data synchronization

3. Analytics Data (via PostHog):
   - App usage events (screen views, feature interactions)
   - Performance metrics (load times, crash reports)
   - Purpose: Product improvement and bug fixing
   - Anonymous: Device identifiers are anonymized

4. Purchase Data:
   - Bootcamp program purchases
   - Purpose: Subscription management

THIRD-PARTY SERVICES:
- Supabase (authentication, database) - BAA signed
- PostHog (analytics) - anonymized data
- Junction/Vital (HealthKit sync) - BAA signed

DATA SECURITY:
- All health data is HIPAA-compliant
- Encryption in transit (TLS 1.2+) and at rest (AES-256)
- No data sold to third parties
- No advertising or tracking

PRIVACY POLICY: https://www.viiraa.com/ViiRaa_Privacy_Policy_Notice_US_20250808.pdf
```

---

### 9.2. Phase 2: Public Release (Requires App Review)

**Prerequisites:**

- [ ] Phase 1 TestFlight testing completed successfully
- [ ] All critical bugs fixed
- [ ] HealthKit integration implemented and tested
- [ ] Privacy policy URL ready (including all data disclosures from section 9.1)
- [ ] App Store screenshots prepared
- [ ] App Store description written
- [ ] Support URL and marketing URL ready
- [ ] Data collection questionnaire completed in App Store Connect (see section 9.1.5)

#### 9.2.1. Step 1: Prepare App Store Materials

1. **Screenshots (Required Sizes):**

   As of 2025, Apple has simplified screenshot requirements:

   **iPhone (Required - Choose ONE):**

   - 6.5" display: 1242 x 2688 pixels (portrait) - for iPhone 11 Pro Max, XS Max, 14 Plus

   Note: App Store Connect automatically scales your screenshots to fit all other iPhone sizes (6.7", 6.3", 6.1", 5.5", etc.)

   **iPad:**

   - iPad 13" (6th gen): 2064 x 2752 pixels (portrait)

   **Requirements:**

   - Upload 1-10 screenshots per device size
   - Formats: .png, .jpg, or .jpeg
   - No transparency or rounded corners

   **Tip**: Use Xcode Simulator to capture screenshots:

   - Run app on simulators (iPhone 16 Pro Max for 6.9" or iPhone 14 Plus for 6.5")
   - Press `Cmd + S` to save screenshot
   - Screenshots automatically saved to Desktop
2. **App Icon:**

   - 1024 x 1024 pixels PNG (no transparency)
   - Placed in `Assets.xcassets/AppIcon.appiconset/`
3. **App Preview Video (Optional):**

   - Up to 30 seconds
   - Same dimensions as screenshots

#### 9.2.2. Step 2: Create App Store Listing

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps > ViiRaa**
3. Click **+ (plus icon)** next to **iOS App**

**App Information:**

| Field                        | Value                                     |
| ---------------------------- | ----------------------------------------- |
| **Name**               | ViiRaa                                    |
| **Subtitle**           | From Weight Control, To Body Intelligence |
| **Category**           | Health & Fitness                          |
| **Secondary Category** | Lifestyle (optional)                      |
| **Copyright**          | 2025 ViiRaa Inc.                          |

**Note on Copyright**: The copyright field must include the year the rights were obtained followed by the name of the person or entity that owns the exclusive rights to your app (for example, "2025 ViiRaa Inc." or "2025 John Doe"). Do not provide a URL.

**Privacy:**

- Privacy Policy URL: `https://www.viiraa.com/ViiRaa_Privacy_Policy_Notice_US_20250808.pdf`

**Pricing:**

- Price: **Free**

#### 9.2.3. Step 3: Prepare Version Information

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

**Promotional Text** (max 170 characters):

```
Master your metabolism with real-time glucose insights. Join the 14-day bootcamp and transform how you eat, move, and feel. Start your journey today!
```

**About Promotional Text:**

Promotional text appears above your app description on the App Store for customers with devices running iOS 11 or later, and macOS 10.13 or later. Key benefits:

- Update anytime without requiring a new app submission
- Perfect for announcing:
  - Limited-time offers or promotions
  - New features or updates
  - Seasonal bootcamp availability
  - Special events or challenges
- Appears prominently at the top of your App Store listing
- Max 170 characters (keep it concise and compelling)

**Example promotional text updates:**

```
Launch Week: Get 20% off your first bootcamp! Limited time offer.
```

```
New Feature: Apple Watch integration now available. Track glucose on your wrist!
```

```
Summer Bootcamp: Join 1000+ members mastering their metabolism this month.
```

**Support URL:**

- `https://viiraa.com/`

**Marketing URL:**

- `https://viiraa.com`

#### 9.2.4. Step 4: Upload Screenshots

1. In **App Store > 1.0 Prepare for Submission**
2. Scroll to **App Previews and Screenshots**
3. Upload screenshots for each device size
4. Drag to reorder (first screenshot is most important)

#### 9.2.5. Step 5: Build Selection

1. Scroll to **Build** section
2. Click **+ (plus icon)**
3. Select your TestFlight build
4. Click **Done**

#### 9.2.6. Step 6: Age Rating

Apple requires all apps to complete an Age Rating questionnaire to help users understand if your app contains any objectionable content. Based on your responses, an age rating will be assigned for each country or region based on their age suitability standards. The assigned age rating will appear on each country or region's App Store and be the same across all platforms in that country or region.

1. Scroll to **Age Rating** section in App Store Connect
2. Click **Edit**
3. Answer the following questionnaire:

**Age Rating Questionnaire for ViiRaa:**

| Question                                                   | ViiRaa Answer   | Explanation                                                     |
| ---------------------------------------------------------- | --------------- | --------------------------------------------------------------- |
| **Cartoon or Fantasy Violence**                      | None            | No violent content                                              |
| **Realistic Violence**                               | None            | No violent content                                              |
| **Prolonged Graphic or Sadistic Realistic Violence** | None            | No violent content                                              |
| **Profanity or Crude Humor**                         | None            | App does not contain profanity or crude humor                   |
| **Mature/Suggestive Themes**                         | None            | Health and wellness app without mature themes                   |
| **Horror/Fear Themes**                               | None            | No horror or fear content                                       |
| **Medical/Treatment Information**                    | Infrequent/Mild | App provides glucose monitoring and health coaching information |
| **Alcohol, Tobacco, or Drug Use or References**      | None            | No substance-related content                                    |
| **Simulated Gambling**                               | None            | No gambling features                                            |
| **Sexual Content or Nudity**                         | None            | No sexual content                                               |
| **Graphic Sexual Content and Nudity**                | None            | No sexual content                                               |
| **Unrestricted Web Access**                          | No              | WebView is restricted to viiraa.com domain only                 |
| **Contests**                                         | None            | No contest features in current version                          |

**Expected Age Rating**: **4+** (suitable for all ages)

**Note**: The "Infrequent/Mild Medical/Treatment Information" response is appropriate because ViiRaa:

- Provides glucose monitoring data (medical information)
- Offers health coaching and wellness guidance
- Does not provide medical diagnosis or treatment recommendations
- Focuses on lifestyle and metabolic health optimization

4. Click **Done** to save your responses
5. Verify the assigned age rating appears as **4+**

**Important Considerations**:

- If you add features in future versions that include contests, user-generated content, or social features, you must update the age rating
- The age rating may vary by region (e.g., 4+ in US, equivalent ratings in other countries)
- Changes to the age rating require a new app submission for review

**Learn More**: [App Store Age Ratings](https://developer.apple.com/help/app-store-connect/reference/age-ratings)

#### 9.2.7. Step 7: Content Rights Documentation

**What is Content Rights?**

Apple requires documentation that you have the legal rights to use any third-party content in your app, including:

- Images, icons, and graphics
- Text content, articles, and educational materials
- Videos and audio
- Data from third-party APIs
- Fonts and design assets
- User-generated content

**For ViiRaa, you must document:**

1. **Health Data Content:**

   - ✅ Glucose data: Sourced from user's own HealthKit (user owns their data)
   - ✅ Activity data: Sourced from user's own HealthKit (user owns their data)
   - ✅ Weight data: Sourced from user's own HealthKit (user owns their data)
2. **Third-Party Services:**

   - ✅ Junction/Vital: You have signed MSA and BAA (Business Associate Agreement)
   - ✅ Supabase: You have commercial license through paid account
   - ✅ PostHog: You have commercial license through paid account
   - ✅ Apple HealthKit: Licensed through Apple Developer Program
3. **UI/Design Assets:**

   - Document the source and rights for all images, icons, and graphics
   - Examples:
     - SF Symbols: Licensed through Apple Developer Program (free to use in apps)
     - Custom icons: Created in-house or purchased from [source]
     - Stock photos: Licensed from [stock photo service] or created in-house
     - App icon: Original work or licensed from designer
4. **Educational Content:**

   - Health coaching content: Created in-house by ViiRaa team
   - Nutritional information: Cite sources (e.g., USDA, peer-reviewed journals)
   - Medical disclaimers: Reviewed by legal counsel
5. **User-Generated Content:**

   - Terms of Service: Users grant ViiRaa limited license to display their content
   - Moderation policy: System in place to remove infringing content
   - DMCA compliance: Designated agent for copyright complaints

**How to Document Content Rights:**

Create a file: `Content_Rights_Declaration.md` with the following:

```markdown
# Content Rights Declaration - ViiRaa iOS App

## 1. User Health Data
All health data (glucose, weight, activity) is sourced from the user's own Apple HealthKit.
- Users own their data
- ViiRaa has permission through HealthKit authorization prompts
- Data usage complies with HIPAA and Apple's privacy guidelines

## 2. Third-Party Services (Licensed)
- Junction/Vital: MSA signed [date], BAA signed [date]
- Supabase: Commercial account (paid subscription)
- PostHog: Commercial account (paid subscription)
- Apple HealthKit: Apple Developer Program membership

## 3. UI Assets
- SF Symbols: Licensed through Apple Developer Program
- App Icon: [Original work by ViiRaa design team / Licensed from Designer Name]
- Custom Icons: [Created in-house / Licensed from IconSource]
- Screenshots: Captured from ViiRaa app (original work)

## 4. Educational Content
- All health coaching content: Original work by ViiRaa team
- Nutritional data: Cited from USDA FoodData Central (public domain)
- Medical information: Reviewed and approved by medical advisors
- Disclaimer: Not a substitute for professional medical advice

## 5. User-Generated Content
- Terms of Service: https://viiraa.com/terms
- Users grant ViiRaa license to display their content within the app
- Content moderation system in place
- DMCA agent: [Contact email]

## 6. Open Source Libraries
All open source dependencies comply with their respective licenses:
- Supabase Swift SDK: MIT License
- PostHog iOS SDK: MIT License
- [List any other dependencies]

---

Prepared by: [Your Name]
Date: [Current Date]
```

**In App Store Connect:**

When submitting, if asked about third-party content:

- ✅ Check "Yes, my app contains third-party content"
- Attach your `Content_Rights_Declaration.md` document
- Or summarize in the notes field:

```
CONTENT RIGHTS:

ViiRaa has the rights to all content in this app:
1. Health data is user's own data from HealthKit
2. Third-party services (Junction, Supabase, PostHog) are licensed via commercial agreements
3. All UI assets are either original work or properly licensed
4. Educational content is original or cited from public domain sources
5. User-generated content is covered by Terms of Service

Full documentation available upon request.
```

---

#### 9.2.8. Step 8: App Review Information

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

**Important**: Also include the data collection disclosure from section 9.1.7 in these notes.

#### 9.2.9. Step 9: Export Compliance

1. Scroll to **Export Compliance**
2. Answer questions:
   - **Is your app designed to use cryptography?** Yes
   - **Does your app qualify for exemption?** Yes (HTTPS only)

#### 9.2.10. Step 10: Submit for Review

1. Review all information for accuracy
2. Click **Add for Review** (top right)
3. Click **Submit for Review**
4. Confirm submission

#### 9.2.11. Step 11: Review Process

- **Review Time**: Typically 24-48 hours
- **Status Updates**: Check App Store Connect for status changes
- **Possible Outcomes:**
  - **Approved**: App is ready to release
  - **Rejected**: Review team provides feedback; address issues and resubmit
  - **In Review**: Under active review
  - **Pending Developer Release**: Approved, waiting for manual release

#### 9.2.12. Step 12: Release

Once approved:

1. **Manual Release:**

   - Click **Release This Version**
   - App goes live within 24 hours
2. **Automatic Release:**

   - Configure in **Version Release** settings
   - App releases immediately upon approval

---

### 9.3. Post-Launch

#### 9.3.1. Monitor App Performance

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

#### 9.3.2. Update Cycle

**Bug Fixes**: Release within 1 week for critical issues
**Minor Updates**: Bi-weekly or monthly
**Major Updates**: Quarterly with new features

---

## 10. Troubleshooting

### 10.1. Build Errors

#### 10.1.1. Supabase SDK Issues

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

#### 10.1.2. PostHog SDK Issues

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

#### 10.1.3. Swift Concurrency Issues

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

#### 10.1.4. Project Configuration Issues

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

#### 10.1.5. General Swift Package Manager Issues

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

### 10.2. Runtime Errors

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

### 10.3. TestFlight Issues

**Build not appearing in TestFlight:**

- Wait 10-30 minutes after upload
- Check for email from Apple about export compliance

**Testers cannot install:**

- Verify tester email is correct
- Check tester has TestFlight app installed
- Ensure build status is "Ready to Test"

### 10.4. Quick Fix Reference

| Error Message                               | Quick Fix                                |
| ------------------------------------------- | ---------------------------------------- |
| 'Client' is not a member type               | Rename class to `SupabaseManager`      |
| Cannot find type 'DatabaseClient'           | Use `PostgrestClient`                  |
| Cannot find type 'PHGPostHog'               | Use `PostHogSDK.shared`                |
| Cannot find type 'AuthState'                | Use `AuthChangeEvent`                  |
| Type does not conform to 'ObservableObject' | Add `nonisolated let objectWillChange` |
| TimeInterval vs Int mismatch                | Cast with `Int(value)`                 |
| Build input file cannot be found            | Fix path in project.pbxproj              |
| Cannot find 'UIApplication'                 | Add `import UIKit`                     |

---

## 11. Junction SDK Integration

This section provides step-by-step instructions for connecting the ViiRaa iOS app to Junction (formerly Vital) for bio data synchronization and ML training.

**Reference**: See [3rd_Party_Bio_Data_Integration_Report.md](3rd_Party_Bio_Data_Integration_Report.md) for detailed technical analysis.

### 11.1. Prerequisites for Testing with Sandbox

**For Development/Testing**: You can use Junction's Sandbox API Key which does NOT require MSA or BAA agreements.

Before starting Junction integration testing in Xcode, you only need:

- [X] Obtain Junction Sandbox API key (already available in `/Users/barack/Downloads/Xcode/Credentials.md`)
- [ ] Complete SDK integration steps below
- [ ] Test the integration in Xcode/Simulator or TestFlight

**Sandbox API Key Details:**

- Located in: [Credentials.md](Credentials.md)
- Updated: November 27th, 2025
- Shelf life: Only 1 week (requires periodic renewal)
- Dashboard: https://app.junction.com/ (login with `barack.liu@viiraa.com`)

**Important Limitations of Sandbox:**

- ⚠️ API keys expire after 1 week - check [Credentials.md](Credentials.md) for updated keys
- ⚠️ Data may be periodically wiped in sandbox environment
- ⚠️ Rate limits may be lower than production
- ⚠️ Not suitable for production use with real user data

---

### 11.1.1. For Production Deployment (Future)

When ready to deploy to production with real users, you will need to complete these prerequisites:

- [ ] Sign contract (MSA - Master Service Agreement) with Junction
- [ ] Sign BAA (Business Associate Agreement) with Junction for HIPAA compliance
- [ ] Obtain Junction Production API key from Junction dashboard
- [ ] Have cloud storage account ready for HIPAA-compliant storage (optional, if not using Junction's storage)

**Note**: The sections below (11.1.2 through 11.1.4) describe the production prerequisites. You can skip these for now and proceed directly to [Section 11.2](#112-after-all-mandatory-prerequisites-are-met) for testing with the Sandbox API Key.

---

#### 11.1.2. Prerequisite 1: Sign MSA (Master Service Agreement) with Junction (Production Only)

**Why is this necessary?**

The MSA is a legally binding contract that establishes the business relationship between ViiRaa and Junction. It defines:

- Service terms and conditions
- Pricing and payment terms
- Data ownership rights
- Liability and indemnification
- Termination conditions
- Support and SLA (Service Level Agreement) commitments

**What happens if you skip this?**

- ❌ **No API access**: Junction will not provide production API keys without a signed contract
- ❌ **No support**: You won't have access to technical support or customer success resources
- ❌ **Legal exposure**: Using the service without a contract exposes ViiRaa to legal risks
- ❌ **No SLA guarantees**: No uptime or performance guarantees for your users

**Step-by-step guidance:**

1. **Contact Junction Sales**

   - Visit [https://tryvital.io](https://tryvital.io)
   - Click "Contact Sales" or "Get Started"
   - Fill out the contact form with:
     - Company name: ViiRaa
     - Use case: Health data integration for glucose monitoring app
     - Expected users: [Your estimate]
     - Email: [Your business email]
2. **Schedule Discovery Call**

   - Junction will schedule a call to understand your needs
   - Prepare to discuss:
     - What health data you need (glucose, weight, activity)
     - Expected data volume
     - Timeline for integration
     - HIPAA compliance requirements
3. **Receive and Review MSA**

   - Junction will send the MSA document (typically PDF)
   - Review key sections:
     - Pricing structure (per-user, per-API call, or flat fee)
     - Data retention policies
     - Termination clauses
     - Liability caps
4. **Negotiate Terms (if needed)**

   - Request modifications if any terms are unacceptable
   - Common negotiation points:
     - Pricing tiers based on volume
     - Custom SLA requirements
     - Data deletion timelines
5. **Sign the MSA**

   - Use DocuSign or similar e-signature platform
   - Ensure authorized signatory signs (CEO, CTO, or authorized representative)
   - Keep a copy for your records

**Estimated timeline**: 1-2 weeks

---

#### 11.1.3. Prerequisite 2: Sign BAA (Business Associate Agreement) for HIPAA Compliance (Production Only)

**Why is this necessary?**

Under HIPAA (Health Insurance Portability and Accountability Act), any third party that handles Protected Health Information (PHI) on behalf of a healthcare entity must sign a BAA. This includes:

- Glucose readings (PHI)
- Weight data linked to identifiable users (PHI)
- Any health data that can be tied to an individual

The BAA legally obligates Junction to:

- Implement appropriate safeguards for PHI
- Report data breaches within required timeframes
- Ensure their subcontractors also comply with HIPAA
- Return or destroy PHI upon contract termination

**What happens if you skip this?**

- ❌ **HIPAA violation**: Processing PHI without a BAA is a direct HIPAA violation
- ❌ **Fines up to $1.5M per year**: HHS can impose significant civil penalties
- ❌ **Criminal penalties**: Willful neglect can result in criminal charges
- ❌ **Reputation damage**: Data breaches without proper agreements are public
- ❌ **User trust loss**: Users expect their health data to be protected
- ❌ **App Store issues**: Apple may reject or remove apps that violate privacy regulations

**Step-by-step guidance:**

1. **Request BAA from Junction**

   - During or after MSA negotiation, explicitly request the BAA
   - Email: "We require a signed BAA before processing any PHI through your platform"
   - Junction should have a standard BAA template ready
2. **Review BAA Key Provisions**

   - **Permitted uses and disclosures**: What Junction can do with PHI
   - **Safeguards**: Security measures Junction must implement
   - **Breach notification**: Timeline for reporting breaches (typically 60 days max)
   - **Subcontractors**: Requirements for Junction's vendors
   - **Termination**: What happens to PHI when contract ends
3. **Verify Junction's HIPAA Compliance**

   - Request their HIPAA compliance documentation
   - Ask for SOC 2 Type II report (security audit)
   - Confirm they have:
     - Encryption at rest (AES-256)
     - Encryption in transit (TLS 1.2+)
     - Access controls and audit logging
     - Incident response procedures
4. **Sign the BAA**

   - Sign before transmitting ANY health data
   - Both parties must sign
   - Date should be before any PHI is processed
5. **Store BAA Securely**

   - Keep signed copy in secure document storage
   - BAAs must be retained for 6 years after contract ends
   - Include in your HIPAA compliance documentation

**Estimated timeline**: Typically included with MSA process, 1-2 weeks

---

#### 11.1.4. Prerequisite 3: Obtain Junction Production API Key from Dashboard (Production Only)

**Why is this necessary?**

The API key is required to:

- Authenticate your app with Junction's servers
- Track your API usage for billing
- Ensure only authorized apps can access your data
- Enable Junction to enforce rate limits and security policies

**What happens if you skip this?**

- ❌ **SDK won't initialize**: The app will fail to connect to Junction
- ❌ **No data sync**: Health data cannot be transmitted to the cloud
- ❌ **Runtime errors**: App will throw configuration errors
- ❌ **Feature disabled**: Junction integration will be completely non-functional

**Step-by-step guidance:**

1. **Access Junction Dashboard**

   - After MSA/BAA signing, Junction will provide dashboard access
   - URL: [https://dashboard.tryvital.io](https://dashboard.tryvital.io)
   - Log in with credentials provided by Junction
2. **Navigate to API Keys Section**

   - Click on **Settings** or **API Keys** in the dashboard
   - You'll see options for different environments
3. **Generate Sandbox API Key (for development)**

   - Click "Create API Key" for **Sandbox** environment
   - Name it: "ViiRaa iOS Development"
   - Copy and save the key securely
   - Use this key during development and testing
4. **Generate Production API Key (for release)**

   - Click "Create API Key" for **Production** environment
   - Name it: "ViiRaa iOS Production"
   - Copy and save the key securely
   - **NEVER commit this key to source control**
5. **Configure API Key in ViiRaa App**

   - Open `Xcode/Utilities/Constants.swift`
   - Update the configuration:

   ```swift
   // For development/testing:
   static let junctionAPIKey = "sk_sandbox_xxxxxxxxxxxxxxxx"
   static let junctionEnvironment = "sandbox"

   // For production release:
   static let junctionAPIKey = "sk_live_xxxxxxxxxxxxxxxx"
   static let junctionEnvironment = "production"
   ```
6. **Secure the API Key**

   - Add `Constants.swift` to `.gitignore` if it contains real keys
   - Or use environment variables / Xcode configuration files
   - Consider using a secrets management solution for production

**API Key Format**: Junction API keys typically look like:

- Sandbox: `sk_sandbox_xxxxxxxxxxxxxxxxxxxx`
- Production: `sk_live_xxxxxxxxxxxxxxxxxxxx`

**Estimated timeline**: Same day (after MSA/BAA signed)

---

#### 11.1.5. Prerequisite 4: HIPAA-Compliant Cloud Storage (Optional, Production Only)

**Why is this necessary?**

While Junction provides cloud storage for synced health data, you may need your own HIPAA-compliant storage for:

- **ML model training**: Store historical data for training custom models
- **Data analytics**: Run queries and analysis on user health data
- **Backup/redundancy**: Maintain your own copy of critical health data
- **Custom processing**: Transform or aggregate data for specific features
- **Long-term retention**: Keep data beyond Junction's retention period

**What happens if you skip this?**

- ✅ **App still works**: Junction handles data storage by default
- ⚠️ **Limited ML capabilities**: Can't train models on your own infrastructure
- ⚠️ **Vendor dependency**: All data lives only on Junction's servers
- ⚠️ **Limited analytics**: Must use Junction's analytics or export data manually

**When you NEED your own storage:**

- Training custom ML models on user data
- Running complex analytics queries
- Regulatory requirements for data residency
- Need for data beyond Junction's retention period

**When you can SKIP this:**

- MVP/initial launch phase
- Using only Junction's built-in analytics
- No custom ML training planned
- Small user base (<1000 users)

**Step-by-step guidance (if needed):**

**Option A: AWS (Recommended for ML)**

1. **Create AWS Account**

   - Go to [https://aws.amazon.com](https://aws.amazon.com)
   - Sign up for an account
   - Enable MFA (Multi-Factor Authentication)
2. **Enable HIPAA-Eligible Services**

   - Sign AWS BAA in AWS Artifact console
   - Navigate to: AWS Console > Artifact > Agreements
   - Accept the AWS Business Associate Addendum
3. **Set Up HIPAA-Compliant Services**

   ```
   Recommended services:
   - S3 (storage) with encryption enabled
   - RDS PostgreSQL (database) with encryption
   - Lambda (serverless compute)
   - SageMaker (ML training)
   ```
4. **Configure Security**

   - Enable CloudTrail for audit logging
   - Set up VPC for network isolation
   - Enable encryption at rest for all services
   - Configure IAM roles with least-privilege access

**Option B: Google Cloud Platform**

1. **Create GCP Account**

   - Go to [https://cloud.google.com](https://cloud.google.com)
   - Sign up and create a project
2. **Sign GCP BAA**

   - Navigate to: Cloud Console > Security > Compliance
   - Accept the Google Cloud BAA
3. **Use HIPAA-Eligible Services**

   ```
   Recommended services:
   - Cloud Storage (storage)
   - Cloud SQL (database)
   - Vertex AI (ML training)
   ```

**Option C: Microsoft Azure**

1. **Create Azure Account**

   - Go to [https://azure.microsoft.com](https://azure.microsoft.com)
   - Sign up for an account
2. **Sign Azure BAA**

   - Available through Microsoft Volume Licensing
   - Or via Azure Portal compliance section
3. **Use HIPAA-Eligible Services**

   ```
   Recommended services:
   - Blob Storage (storage)
   - Azure SQL Database (database)
   - Azure Machine Learning (ML training)
   ```

**Estimated Cost (Monthly)**:

| Provider | Storage (1TB) | Database              | ML Training | Total |
| -------- | ------------- | --------------------- | ----------- | ----- |
| AWS      | ~$23 | ~$50   | ~$100-500 | ~$173-573 |             |       |
| GCP      | ~$20 | ~$50   | ~$100-500 | ~$170-570 |             |       |
| Azure    | ~$21 | ~$50   | ~$100-500 | ~$171-571 |             |       |

**Estimated timeline**: 1-2 days for basic setup

---

## 11.2. SDK Integration Steps (For Testing with Sandbox API Key)

**Quick Start for Testing in Xcode:**

You're ready to test the Junction integration using the Sandbox API Key! Follow these steps:

1. **Add Junction SDK** to your Xcode project via Swift Package Manager
2. **Configure the API Key** in `Constants.swift` using the sandbox key from [Credentials.md](Credentials.md)
3. **Update JunctionManager** to use real SDK calls (replace placeholders)
4. **Connect user** after authentication
5. **Test in Xcode/Simulator** or on a physical device
6. **Verify data** in the Junction Dashboard at https://app.junction.com/

**No MSA or BAA required for sandbox testing!** You can start integrating and testing immediately.

---

### 11.2.1. Step 1: Add Junction SDK via Swift Package Manager

1. In Xcode, select **File > Add Packages...**
2. Enter URL: `https://github.com/tryVital/vital-ios.git`
3. Dependency Rule: **Up to Next Major Version** - `1.0.0`
4. Click **Add Package**
5. Select the following libraries:

   - `VitalCore`
   - `VitalHealthKit`
6. Click **Add Package**
7. **Verify Dependencies:**

   - In Project Navigator, expand **Package Dependencies**
   - You should see `vital-ios` listed

### 11.2.2. Step 2: Configure Junction Sandbox API Key

1. Open `Xcode/Utilities/Constants.swift`
2. Update the Junction configuration with your Sandbox API key from [Credentials.md](Credentials.md):

   ```swift
   // Junction (Vital) SDK Configuration
   static let junctionAPIKey = "k_us_ppzw0ZYK-NeiBAF3qSNA5Fddg45-40bnDWFXAaKvZOM"  // Sandbox key from Credentials.md
   static let junctionEnvironment = "sandbox"  // Use "sandbox" for testing
   ```

   **Important**:

   - ⚠️ The sandbox API key expires after 1 week (updated Nov 27, 2025)
   - ⚠️ Check [Credentials.md](Credentials.md) for the latest key if you encounter authentication errors
   - ⚠️ For production deployment, change to `"production"` and use a production API key
3. Enable the Junction feature flag:

   ```swift
   // Feature Flags
   static let isJunctionEnabled = true  // Change from false to true
   ```

### 11.2.3. Step 3: Update JunctionManager with Real SDK Calls

1. Open `Xcode/Services/Junction/JunctionManager.swift`
2. Replace the placeholder code with actual VitalHealth SDK calls:

   ```swift
   import VitalCore
   import VitalHealthKit

   // In configure() method, replace:
   func configure(apiKey: String) {
       self.apiKey = apiKey

       // Real SDK initialization
       VitalClient.configure(apiKey: apiKey, environment: .production(.us))

       self.isConfigured = true
       print("🔗 Junction SDK configured")
       AnalyticsManager.shared.track(event: "junction_configured")
   }

   // In connectUser() method, replace:
   func connectUser(userId: String) async throws {
       guard isConfigured else {
           throw JunctionError.notConfigured
       }

       self.userId = userId

       // Real SDK user connection
       try await VitalClient.shared.signIn(userId: userId)

       self.isConnected = true
       print("👤 User connected to Junction: \(userId)")
       AnalyticsManager.shared.track(event: "junction_user_connected", properties: [
           "user_id": userId
       ])
   }

   // In requestHealthKitPermissions() method, replace:
   func requestHealthKitPermissions() async throws {
       guard isConfigured else {
           throw JunctionError.notConfigured
       }

       // Real SDK permission request
       try await VitalHealthKitClient.shared.ask(
           readPermissions: [.glucose, .weight, .steps, .activeEnergyBurned],
           writePermissions: []
       )

       print("✅ HealthKit permissions granted via Junction")
       AnalyticsManager.shared.track(event: "junction_healthkit_authorized")
   }

   // In syncHealthData() method, replace:
   func syncHealthData() async throws {
       guard isConfigured else {
           throw JunctionError.notConfigured
       }
       guard isConnected else {
           throw JunctionError.userNotConnected
       }

       syncStatus = .syncing
       syncError = nil

       do {
           // Real SDK sync call
           try await VitalHealthKitClient.shared.syncData()

           syncStatus = .success
           lastSyncDate = Date()
           print("✅ Health data synced to Junction cloud")
           AnalyticsManager.shared.track(event: "junction_sync_success")
       } catch {
           syncStatus = .failed
           let junctionError = JunctionError.syncFailed(error)
           syncError = junctionError
           print("❌ Junction sync failed: \(error.localizedDescription)")
           AnalyticsManager.shared.track(event: "junction_sync_failed", properties: [
               "error": error.localizedDescription
           ])
           throw junctionError
       }
   }
   ```

### 11.2.4. Step 4: Connect User After Authentication

1. Open `Xcode/Core/Authentication/AuthManager.swift`
2. After successful authentication, connect the user to Junction:

   ```swift
   // In your sign-in success handler, add:
   if Constants.isJunctionEnabled {
       Task {
           do {
               try await JunctionManager.shared.connectUser(userId: user.id)
               try await JunctionManager.shared.requestHealthKitPermissions()
               JunctionManager.shared.startAutomaticSync()
           } catch {
               print("Junction connection failed: \(error.localizedDescription)")
               // Non-blocking - app continues to work without Junction
           }
       }
   }
   ```
3. On sign-out, disconnect from Junction:

   ```swift
   // In your sign-out method, add:
   if Constants.isJunctionEnabled {
       JunctionManager.shared.disconnect()
   }
   ```

### 11.2.5. Step 5: Add Junction Status to Settings

To show Junction sync status in the Settings screen:

1. Open `Xcode/Features/Settings/SettingsView.swift`
2. Add Junction status section:

   ```swift
   @StateObject private var junctionManager = JunctionManager.shared

   // In the body, add a section:
   if Constants.isJunctionEnabled {
       Section("Data Sync") {
           HStack {
               Text("Junction Status")
               Spacer()
               Text(junctionManager.statusMessage)
                   .foregroundColor(.secondary)
           }

           if junctionManager.isReady {
               Button("Sync Now") {
                   Task {
                       try? await junctionManager.syncHealthData()
                   }
               }
               .disabled(junctionManager.syncStatus.isInProgress)
           }
       }
   }
   ```

### 11.2.6. Step 6: Test the Integration with Sandbox

#### 11.2.6.1. Xcode/Simulator Testing Checklist

- [ ] App builds successfully with VitalHealth SDK
- [ ] Junction SDK initializes on app launch (check Xcode console for "🔗 Junction SDK configured")
- [ ] User connects to Junction after sign-in
- [ ] HealthKit permissions are requested
- [ ] Manual sync works (check console for "✅ Health data synced")
- [ ] Automatic hourly sync is scheduled
- [ ] Sync status displays correctly in Settings
- [ ] Sign-out disconnects from Junction
- [ ] Analytics events are tracked in PostHog

**Testing in Xcode Simulator:**

1. Run the app in Xcode (⌘R)
2. **Open the Console pane to view logs:**
   - **Method 1**: Click the **Debug area** button in the top-right toolbar (icon looks like a panel at the bottom)
   - **Method 2**: Press **⌘⇧Y** (Command + Shift + Y) to toggle the debug area
   - **Method 3**: Go to menu **View → Debug Area → Show Debug Area**
   - **Method 4**: On the right bottom, there are 2 icons which impact the layout of console.
   - Once the debug area is open, you'll see the **Console** tab at the bottom of the Xcode window
   - If you see variables view instead, click the **Console** button on the right side of the debug area (looks like text lines)
   - **IMPORTANT - Verify Console Settings:**
     - Make sure the **Filter** field (bottom-left) is **empty** or cleared
     - Right-click in the console area and select **"Clear Console"** to start fresh
     - Look for the filter dropdown and ensure **"All Output"** is selected (not "Errors and Failures only")
3. Sign in with a test account
4. Navigate to Settings to trigger Junction sync
5. Watch for Junction-related console messages:
   - "🔗 Junction SDK configured" - confirms SDK initialization
   - "👤 User connected to Junction" - confirms user connection
   - "✅ Health data synced to Junction cloud" - confirms successful sync
   - "✅ HealthKit permissions granted via Junction" - confirms permissions

**Testing on Physical Device:**

1. Build and run on your iPhone/iPad
2. Use the actual HealthKit data from your device
3. Monitor logs in Xcode's console while device is connected

#### 11.2.6.2. Verify Data in Junction Sandbox Dashboard

1. Log into [Junction Dashboard](https://app.junction.com/)
   - Email: `barack.liu@viiraa.com`
   - Password: Available in [Credentials.md](Credentials.md)
   - Use Google Account SSO
2. Navigate to **Users** section and find your test user
3. Verify glucose and health data is being received
4. Check data timestamps to confirm sync is working

#### 11.2.6.3. Query Glucose Data via API (Alternative to Dashboard)

The Junction Dashboard UI may not display individual glucose values in the sandbox environment. To view actual glucose readings and values, use the Junction API directly.

**Understanding User IDs:**

Junction uses TWO different user identifiers:

| ID Type | Description | Where to Find | Used For |
|---------|-------------|---------------|----------|
| **Client User ID** | ViiRaa's internal user ID (UUID) | ViiRaa Settings → Cloud Sync section | Creating users in Junction, searching in Dashboard |
| **Junction User ID** | Junction's internal user ID (UUID) | Junction Dashboard → Users → Click user → Shows both IDs | API queries |

⚠️ **CRITICAL**: API endpoints require the **Junction user_id**, NOT the client_user_id!

**Steps to Query Glucose Data:**

1. **Find the Junction User ID** (not the Client User ID):
   - Open [Junction Dashboard](https://app.junction.com/)
   - Navigate to **Users** tab
   - Search for user by Client User ID (copy from ViiRaa Settings)
   - Click on the user
   - Copy the `user_id` field (the Junction internal ID, different from client_user_id)

2. **Query glucose data using curl** (replace `<JUNCTION_USER_ID>` with the ID from step 1):

```bash
# Basic query (returns minified JSON - hard to read)
curl -X GET "https://api.sandbox.tryvital.io/v2/timeseries/<JUNCTION_USER_ID>/glucose?start_date=2025-12-11&end_date=2025-12-18" \
  -H "x-vital-api-key: sk_us_Gb2bkO8kvbSw0-DtyUWedO26IvtkomiYRafF7RRHMus"
```

**Making the Output Readable:**

**Option 1: Use `jq` for formatted JSON (recommended)**

```bash
# Install jq (if not already installed)
brew install jq

# Query with pretty-printed output, one reading per line
curl -X GET "https://api.sandbox.tryvital.io/v2/timeseries/<JUNCTION_USER_ID>/glucose?start_date=2025-12-11&end_date=2025-12-18" \
  -H "x-vital-api-key: sk_us_Gb2bkO8kvbSw0-DtyUWedO26IvtkomiYRafF7RRHMus" \
  | jq '.[] | "\(.timestamp) | \(.value) \(.unit) | Type: \(.type)"'
```

**Example output:**
```
"2025-12-11T00:00:00+00:00 | 7.6 mmol/L | Type: automatic"
"2025-12-11T00:43:00+00:00 | 4.7 mmol/L | Type: automatic"
"2025-12-11T01:13:00+00:00 | 5.1 mmol/L | Type: automatic"
...
```

**Option 2: Use Python for formatted output**

```bash
# Save to Python script: format_glucose.py
curl -X GET "https://api.sandbox.tryvital.io/v2/timeseries/<JUNCTION_USER_ID>/glucose?start_date=2025-12-11&end_date=2025-12-18" \
  -H "x-vital-api-key: sk_us_Gb2bkO8kvbSw0-DtyUWedO26IvtkomiYRafF7RRHMus" \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(f'Total readings: {len(data)}\n')
print(f'{'Timestamp':<25} {'Value':<12} {'Type':<10}')
print('-' * 50)
for reading in data:
    print(f\"{reading['timestamp']:<25} {reading['value']:>6.1f} {reading['unit']:<5} {reading['type']:<10}\")
"
```

**Example output:**
```
Total readings: 456

Timestamp                 Value        Type
--------------------------------------------------
2025-12-11T00:00:00+00:00    7.6 mmol/L automatic
2025-12-11T00:43:00+00:00    4.7 mmol/L automatic
2025-12-11T01:13:00+00:00    5.1 mmol/L automatic
...
```

**Option 3: Save to CSV file**

```bash
curl -X GET "https://api.sandbox.tryvital.io/v2/timeseries/<JUNCTION_USER_ID>/glucose?start_date=2025-12-11&end_date=2025-12-18" \
  -H "x-vital-api-key: sk_us_Gb2bkO8kvbSw0-DtyUWedO26IvtkomiYRafF7RRHMus" \
  | jq -r '.[] | [.timestamp, .value, .unit, .type] | @csv' > glucose_data.csv

# Open in Excel or Numbers
open glucose_data.csv
```

**API Query Limitations:**

- **Sandbox/Trial accounts**: Can only query 7-day windows at a time
- **Production accounts**: Longer query windows available (contact Junction for limits)
- **Date format**: Use ISO 8601 format `YYYY-MM-DD` for start_date and end_date

**Converting Units:**

Junction returns glucose values in `mmol/L`. To convert to `mg/dL` (used in ViiRaa):

```bash
# Add conversion in jq query
curl -X GET "https://api.sandbox.tryvital.io/v2/timeseries/<JUNCTION_USER_ID>/glucose?start_date=2025-12-11&end_date=2025-12-18" \
  -H "x-vital-api-key: sk_us_Gb2bkO8kvbSw0-DtyUWedO26IvtkomiYRafF7RRHMus" \
  | jq '.[] | "\(.timestamp) | \(.value * 18.0182 | floor) mg/dL | Type: \(.type)"'
```

**Troubleshooting API Queries:**

| Error Message | Cause | Solution |
|---------------|-------|----------|
| `{"detail":"The user does not or no longer exists in this team"}` | Using client_user_id instead of Junction user_id | Use the Junction user_id from Dashboard |
| `{"detail":"GET requests to timeseries endpoints are limited to 7 days..."}` | Query window exceeds 7 days (sandbox limit) | Reduce date range to 7 days or less |
| `401 Unauthorized` | Invalid API key | Verify API key from Credentials.md |
| Empty array `[]` | No data in date range OR data hasn't synced yet | Check earlier date range, verify sync in Dashboard |

**Important Notes for Sandbox Testing:**

- ⚠️ Sandbox data may be wiped periodically - don't rely on data persistence
- ⚠️ If you see authentication errors, check if the API key has expired (1-week shelf life)
- ⚠️ Update the key in `Constants.swift` with the latest one from [Credentials.md](Credentials.md)

### 11.3. Important Notes

#### 11.3.1. 3-Hour Data Delay

**Critical**: Apple HealthKit enforces a minimum 3-hour data delay. This is a platform limitation, not a Junction limitation.

- ✅ **Acceptable for**: ML model training, historical analysis, trend reporting
- ❌ **Not suitable for**: Real-time alerts, immediate feedback

#### 11.3.2. Background Sync

Junction SDK handles automatic hourly sync. The app's `Info.plist` is already configured with:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.viiraa.app.junction-sync</string>
</array>

<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
</array>
```

#### 11.3.3. Error Handling

JunctionManager includes comprehensive error handling:

| Error                | Meaning                        | Recovery                         |
| -------------------- | ------------------------------ | -------------------------------- |
| `notConfigured`    | SDK not initialized            | Check API key in Constants.swift |
| `userNotConnected` | User not signed in to Junction | Re-authenticate user             |
| `permissionDenied` | HealthKit access denied        | Guide user to Settings           |
| `syncFailed`       | Network or server error        | Retry later                      |
| `invalidAPIKey`    | Wrong API key                  | Contact Junction support         |

### 11.4. Troubleshooting

#### 11.4.1. Junction SDK Build Errors

**Error: "No such module 'VitalCore'"**

- Solution: Reset package caches: **File > Packages > Reset Package Caches**
- Clean build folder: **Cmd + Shift + K**
- Rebuild: **Cmd + B**

**Error: "Cannot find type 'VitalClient' in scope"**

- Ensure you imported both modules:
  ```swift
  import VitalCore
  import VitalHealthKit
  ```

#### 11.4.2. Runtime Errors

**Error: "Junction SDK is not configured"**

- Verify `Constants.isJunctionEnabled = true`
- Check that `JunctionManager.shared.configure()` is called in `ViiRaaApp.setupApp()`

**Error: "User is not connected to Junction"**

- Ensure `connectUser()` is called after successful authentication
- Check that the user ID is valid (non-empty string)

**HealthKit permissions not appearing**

- Verify `NSHealthShareUsageDescription` is in Info.plist
- Check that HealthKit capability is enabled in Xcode

#### 11.4.3. Console Logs Not Appearing

If you don't see any console logs when running the app in Xcode:

**Solution 1: Check Console Filter**

- Look at the **Filter** text field at the bottom-left of the debug area
- Make sure it's **completely empty** - click the X to clear it
- Any text in this field will hide logs that don't match

**Solution 2: Verify Console Output Level**

- In the debug area, look for a filter icon or dropdown menu
- Ensure **"All Output"** is selected (not "Errors Only" or "Errors and Failures")
- You can also right-click in the console and check output settings

**Solution 3: Stop and Re-run the App**

- Stop the current run (⌘. or click the Stop button)
- Right-click in the console area and select **"Clear Console"**
- Run the app again (⌘R)
- Watch for the "🔗 Junction SDK configured" message immediately on launch

**Solution 4: Check Scheme Settings**

- Go to **Product → Scheme → Edit Scheme** (or ⌘<)
- Select **Run** in the left sidebar
- Click the **Options** tab
- Ensure **"Console"** is set to **"Target Output"** (not "None")

**Solution 5: Check OS_ACTIVITY_MODE**

- In **Product → Scheme → Edit Scheme** → **Run** → **Arguments** tab
- Check **Environment Variables**
- If `OS_ACTIVITY_MODE` is set to `disable`, either remove it or change to `default`
- This variable can suppress system logs

**Solution 6: Restart Xcode**

- Sometimes Xcode's console gets stuck
- Quit Xcode completely (⌘Q)
- Reopen the project
- Clean build folder (⌘⇧K) and rebuild (⌘B)

**What You Should See:**
When the app launches successfully, you should immediately see:

```
🔗 Junction SDK configured with sandbox environment
```

After signing in and going to Settings, you should see:

```
👤 User connected to Junction: [user-id]
✅ Health data synced to Junction cloud
```

---

### 11.9. Junction Sync Troubleshooting (Bug #21)

This section documents common issues with Junction data sync and how to diagnose them. Based on [Bug #21 Analysis](Learnings_From_Doing.md) and SDD Section 10.4.

#### 11.9.1. Symptom: Data Not Appearing in Junction Dashboard

**Problem**: Apple Health shows glucose data but Junction dashboard shows "No data" despite connection being "Connected".

**Quick Diagnosis**: Run the sync health check in your app:

```swift
// In your debug view or console
Task {
    let status = await JunctionManager.shared.performSyncHealthCheck()
    print("Sync Health: \(status)")
}
```

**Possible Status Results**:

| Status | Meaning | Action |
|--------|---------|--------|
| `✅ Healthy` | Data is syncing correctly | No action needed |
| `❌ VitalClient not signed in` | SDK not authenticated | Re-sign in the user |
| `⚠️ No glucose data in local HealthKit` | No source data | Add glucose data to Apple Health |
| `❌ Sync Failed - Local: X, Cloud: 0` | Data exists locally but not in cloud | See Root Causes below |

#### 11.9.2. Root Causes and Solutions

**Root Cause 1: Glucose Data Source Not Recognized (PRIMARY ISSUE)**

⚠️ **CRITICAL**: Junction only syncs glucose data from **recognized CGM device sources**, NOT manually-entered data.

| Data Source | Bundle ID | Junction Sync |
|-------------|-----------|---------------|
| Abbott Lingo CGM | `com.abbott.lingo` | ✅ Syncs |
| Dexcom CGM | `com.dexcom.*` | ✅ Syncs |
| FreeStyle Libre | `com.freestyle.*` | ✅ Syncs |
| Medtronic CGM | `com.medtronic.*` | ✅ Syncs |
| Manual entry in Apple Health | `com.apple.Health` | ❌ Does NOT sync |
| ViiRaa mock data | `com.viiraa.app` | ❌ Does NOT sync |

**How to Verify**:

In the ViiRaa app, go to **Settings > Cloud Sync > Troubleshooting** and tap **"Run Sync Diagnostic"**. Check the console output:

```
📋 Glucose data sources:
   - Health (com.apple.Health): 3 readings
⚠️ WARNING: No readings from recognized CGM sources!
```

**Solutions**:

1. **For Production**: Connect a real Abbott Lingo CGM device - it will write glucose data to HealthKit with `com.abbott.lingo` as the source
2. **For Testing on Simulator**: Junction won't sync test data - see section 11.9.8 for simulator limitations
3. **For Testing on Device**: Install ViiRaa on a physical iPhone with Abbott Lingo connected

**Root Cause 2: Dual Permission System Mismatch**

ViiRaa has TWO separate HealthKit permission flows:
- `HealthKitManager.requestAuthorization()` - Direct HealthKit access for app display
- `VitalHealthKitClient.shared.ask()` - Junction SDK access for cloud sync

If user granted permissions through one but not the other, data won't sync.

**Solution**: Ensure both systems have glucose permission. Check permission status:

```swift
// Check HealthKitManager permission
let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose)!
let hkStatus = HealthKitManager.shared.authorizationStatus(for: glucoseType)
print("HealthKit status: \(hkStatus.rawValue)")

// Check VitalClient status
let vitalStatus = await VitalClient.status
print("VitalClient signed in: \(vitalStatus.contains(.signedIn))")
```

**Root Cause 3: HealthKit Permission Denied**

The user may have denied glucose READ permission when iOS showed the HealthKit permission dialog.

**How to Verify**:

On the device, go to **iOS Settings > Privacy & Security > Health > ViiRaa** and check if **Blood Glucose** has a green toggle (ON).

**Solution**:

1. Delete the app completely from the device
2. Reinstall from Xcode
3. When the HealthKit permission dialog appears, **enable Blood Glucose** specifically
4. Users often skip this permission - emphasize it's required for glucose tracking

**Root Cause 4: 3-Hour HealthKit Delay (Recent Data Only)**

Apple HealthKit enforces a 3-hour delay for recent readings. This ONLY affects data < 3 hours old.

**Solution**:
- Historical data (> 3 hours old) should sync immediately
- If testing with fresh data, wait 3+ hours before checking Junction dashboard
- Add glucose readings with timestamps > 3 hours in the past for immediate testing

**Root Cause 5: False Success Indicators**

The app logs `📊 Event tracked: junction_sync_success` immediately after calling `syncData()`, but this doesn't verify data reached Junction's servers.

**Solution**: Use the new verification API:

```swift
// Sync with verification (recommended)
let success = try await JunctionManager.shared.syncHealthDataWithVerification()
if !success {
    print("⚠️ Sync initiated but data not verified in cloud")
}
```

Or tap **"Run Sync Diagnostic"** in Settings > Cloud Sync > Troubleshooting to get a comprehensive health check.

#### 11.9.3. Step-by-Step Debugging Procedure

1. **Check VitalClient Status**
   ```
   Logs should show: ✅ VitalClient already signed in
   ```

2. **Verify Junction User Connection**
   ```
   Logs should show: ✅ User connected to Junction: [uuid]
   ```

3. **Check Permission Status**
   ```
   Run: await JunctionManager.shared.logPermissionStatus()
   Logs should show: 📋 HealthKitManager glucose permission: 2 (granted)
   ```

4. **Trigger Manual Sync**
   ```swift
   try await JunctionManager.shared.syncHealthData()
   ```

5. **Verify Data in Cloud**
   ```swift
   let verified = await JunctionManager.shared.verifySyncSuccess()
   // Should print: ✅ Sync verification: X readings found
   ```

6. **Full Health Check**
   ```swift
   let status = await JunctionManager.shared.performSyncHealthCheck()
   print("Status: \(status)")
   ```

#### 11.9.4. Testing Recommendations

1. **Fresh Data Test**:
   - Add NEW glucose reading to Apple Health with timestamp > 3 hours old
   - Trigger manual sync
   - Wait 5 minutes for background upload
   - Check Junction dashboard

2. **Source Attribution Test**:
   - Open Apple Health > Browse > Blood Glucose > Show All Data
   - Tap on a reading to see its source
   - Note which app/device wrote the data

3. **Complete Flow Test**:
   ```swift
   // 1. Check local data exists
   let localData = try await HealthKitManager.shared.fetchGlucoseHistory(
       startDate: Date().addingTimeInterval(-30*24*60*60),
       endDate: Date()
   )
   print("Local readings: \(localData.count)")

   // 2. Trigger sync with verification
   let success = try await JunctionManager.shared.syncHealthDataWithVerification()

   // 3. Check status
   let status = await JunctionManager.shared.performSyncHealthCheck()
   print("Final status: \(status)")
   ```

#### 11.9.5. Junction Dashboard Verification

After syncing, verify data in Junction Dashboard:

1. Go to: `https://app.junction.com/team/[team-id]/sandbox/user/[user-id]/wearables`
2. Click on "Data Ingestion Status"
3. Check the "Historical Pull" and "Data Ingestion" tabs
4. Look for glucose data (should show dates and counts)

**Expected Result**: Historical data beyond 3 hours should appear within 5-10 minutes of sync.

#### 11.9.6. Key Learnings

| Lesson | Details |
|--------|---------|
| "Connected" ≠ "Syncing" | Junction showing "Connected" only means provider link exists, NOT that data is flowing |
| "Sync success" ≠ "Data delivered" | App logs success after calling `syncData()` but doesn't verify cloud delivery |
| Read-only ≠ Data source | App reading HealthKit doesn't mean Junction can sync - needs source data |
| Verify at destination | Always check Junction dashboard, not just app logs |

#### 11.9.7. Reference Files

- **Bug Analysis**: [Learnings_From_Doing.md Bug #21](Learnings_From_Doing.md)
- **SDD Documentation**: [Software_Development_Document.md Section 10.4](Software_Development_Document.md)
- **JunctionManager**: [JunctionManager.swift](Xcode/Services/Junction/JunctionManager.swift) - Lines 700-1100 for health check functions
- **HealthKitManager**: [HealthKitManager.swift](Xcode/Services/HealthKit/HealthKitManager.swift)
- **SettingsView**: [SettingsView.swift](Xcode/Features/Settings/SettingsView.swift) - Lines 187-238 for troubleshooting UI

#### 11.9.8. iOS Simulator Limitations for Junction Testing

⚠️ **CRITICAL**: iOS Simulator has fundamental limitations that prevent full Junction glucose sync testing.

| Feature | iOS Simulator | Physical iPhone |
|---------|---------------|-----------------|
| Connect to Bluetooth CGM (Abbott Lingo) | ❌ Not possible | ✅ Works |
| Receive real CGM data | ❌ Not possible | ✅ Works |
| Manually-entered glucose data | ✅ Can read | ❌ Junction won't sync |
| Mock data from ViiRaa | ✅ Can write | ❌ Junction won't sync |
| Test Junction sync with real CGM | ❌ Not possible | ✅ Works |
| Test UI flow and permissions | ✅ Works | ✅ Works |

**Why Simulator Testing is Limited**:

1. **No Bluetooth Support**: iOS Simulator cannot connect to physical Bluetooth devices like Abbott Lingo CGM
2. **Data Source Filtering**: Junction only syncs glucose data from recognized CGM device sources (e.g., `com.abbott.lingo`), NOT from:
   - Manual entries (`com.apple.Health`)
   - Mock data from ViiRaa (`com.viiraa.app`)
3. **Cannot Simulate Real CGM**: Even if you write mock glucose data in the simulator, it will have ViiRaa's bundle ID as the source, which Junction filters out

**What You CAN Test on Simulator**:

- ✅ UI flow for glucose data display
- ✅ HealthKit permission requests
- ✅ Junction SDK initialization
- ✅ Sync trigger mechanisms
- ✅ Error handling and logging
- ✅ Settings UI and debug tools

**What You CANNOT Test on Simulator**:

- ❌ Actual glucose data syncing to Junction
- ❌ Real CGM device integration
- ❌ Production data flow validation
- ❌ Data source verification by Junction

**Testing Workflow**:

```
Simulator Development → Physical Device Testing → Production
     ↓                          ↓                       ↓
  UI/UX testing          CGM integration test    Real user data
  Permission flow        Abbott Lingo data      Junction sync
  Debug features         Sync verification      ML training
```

**How to Test on Physical iPhone with Abbott Lingo**:

1. **Connect iPhone to Mac** via USB cable
2. **In Xcode**: Select your iPhone from the destination picker (Product > Destination > [Your iPhone])
3. **Build and Run** (⌘R) - ViiRaa will install on your physical device
4. **Wear Abbott Lingo CGM** - it will write glucose data to HealthKit automatically
5. **Open ViiRaa** - go to Settings > Cloud Sync > Sync Now
6. **Verify in Junction Dashboard**:
   - Go to Data Ingestion tab
   - Look for `glucose` row with sent count > 0
   - Data source will show: `Lingo (com.abbott.lingo)` ✅

**Mock Data Feature (For Simulator Testing Only)**:

ViiRaa includes a "Write Mock Glucose Data" button in Settings > Cloud Sync > Troubleshooting. This:
- ✅ Writes test glucose data to HealthKit simulator
- ✅ Useful for testing UI display and data reading
- ❌ Will NOT sync to Junction (wrong source bundle ID)
- ⚠️ Only use this for local testing, NOT for validating Junction sync

**Production Validation Checklist**:

- [ ] Test on physical iPhone with real Abbott Lingo CGM
- [ ] Verify glucose data appears in Apple Health from Lingo app
- [ ] Open ViiRaa and grant HealthKit permissions (including glucose)
- [ ] Trigger manual sync in ViiRaa Settings
- [ ] Wait 5-10 minutes for background upload
- [ ] Check Junction dashboard Data Ingestion tab for glucose with count > 0
- [ ] Verify data source is `com.abbott.lingo` in diagnostic logs

**Simulator Mock Data Console Output**:

When you tap "Write Mock Glucose Data (Test)" in the simulator, you'll see:

```
📝 Writing mock glucose data to HealthKit for testing...
⚠️  NOTE: This data will have ViiRaa as source, not a CGM device
⚠️  Junction may not sync data from non-CGM sources
   ✅ Saved: 95.0 mg/dL at [date]
   ✅ Saved: 110.0 mg/dL at [date]
   ✅ Saved: 125.0 mg/dL at [date]
📝 Wrote 5/5 mock glucose readings
🔄 Triggering sync to Junction...
📋 NEXT STEPS:
   1. Wait 5 minutes for sync to complete
   2. Check Junction dashboard Data Ingestion tab
   3. If glucose still doesn't appear, Junction likely filters by source
   4. Test on a REAL device with Abbott Lingo for production validation
```

---

## 12. Next Steps

### 12.1. Phase 2: HealthKit Integration - ✅ COMPLETED

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

### 12.2. Phase 3: Chat Integration

Implement miniViiRaa AI coach chat functionality:

1. Evaluate Mattermost or alternative chat platform
2. Create WebView-based chat interface
3. Integrate with existing Telegram dependency
4. Enable push notifications

---

## 13. Resources

- [Product Requirements Document](Product%20Requirements%20Document.md)
- [Software Development Documentation](Software%20Development%20Documentation.md)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Supabase Swift SDK](https://github.com/supabase/supabase-swift)
- [PostHog iOS SDK](https://posthog.com/docs/libraries/ios)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

**Document Version**: 1.4
**Last Updated**: 2025-12-02
**Status**: Ready for Implementation

## 14. Bluetooth Low Energy (BLE) Follow Mode Deployment

**Implementation Date**: December 2, 2025
**Feature**: Real-time glucose monitoring from Abbott Lingo sensors via Bluetooth Low Energy
**Reference**: [BLE_IMPLEMENTATION_SUMMARY.md](BLE_IMPLEMENTATION_SUMMARY.md)

### 14.1. Overview

BLE Follow Mode enables ViiRaa users to receive real-time glucose readings (1-5 minute latency) from Abbott Lingo CGM sensors via Bluetooth. This complements the existing Junction SDK integration (3-hour latency) by providing immediate feedback for user-facing features.

**Key Benefits**:

- ⚡ Real-time updates (1-5 min vs 3 hours)
- 📊 Trend indicators (↑↑, ↑, →, ↓, ↓↓)
- 🔋 Battery optimized scanning
- ✅ App Store compliant (Follower Mode approach)
- 🔒 HIPAA compliant data handling

### 14.2. Pre-Deployment Checklist

Before deploying BLE Follow Mode to production, complete these critical tasks:

#### 14.2.1. Code Completion ⚠️ CRITICAL

**1. Replace Placeholder BLE Protocol**

- **Location**: [Xcode/Services/Bluetooth/BLEFollowManager.swift:196-223](Xcode/Services/Bluetooth/BLEFollowManager.swift#L196-L223)
- **Status**: ❌ PLACEHOLDER - Must replace with actual Abbott Lingo BLE protocol
- **Required**:
  ```swift
  // Current placeholder Service UUID
  private let abbottServiceUUID = CBUUID(string: "FFF0")
  private let glucoseCharacteristicUUID = CBUUID(string: "FFF1")

  // Replace with actual Abbott UUIDs (contact Abbott or reference xDrip4iOS)
  ```
- **Resources**:
  - xDrip4iOS source: https://github.com/JohanDegraeve/xdripswift
  - Abbott Developer Support: abbott-developer-support@abbott.com
- **Priority**: CRITICAL - App will not work without correct UUIDs

**2. Implement Data Parsing**

- **Location**: [Xcode/Services/Bluetooth/BLEFollowManager.swift:196-223](Xcode/Services/Bluetooth/BLEFollowManager.swift#L196-L223)
- **Status**: ❌ PLACEHOLDER - Simplified example only
- **Required**: Implement actual glucose value extraction, timestamp parsing, and trend calculation
- **Priority**: CRITICAL

**3. Complete Analytics Integration**

- **Location**: [Xcode/Services/Bluetooth/BLEFollowManager.swift:234-237](Xcode/Services/Bluetooth/BLEFollowManager.swift#L234-L237)
- **Status**: ❌ PLACEHOLDER
- **Example**:
  ```swift
  private func trackGlucoseReading(_ reading: GlucoseReading) {
      AnalyticsManager.shared.track(event: "ble_glucose_reading_received", properties: [
          "value": reading.value,
          "has_trend": reading.trend != nil,
          "data_source": "ble_follow",
          "is_recent": reading.isRecent
      ])
  }
  ```
- **Priority**: HIGH

**4. Implement Junction Cross-Validation**

- **Location**: [Xcode/Services/Bluetooth/BLEFollowManager.swift:228-232](Xcode/Services/Bluetooth/BLEFollowManager.swift#L228-L232)
- **Status**: ❌ PLACEHOLDER
- **Purpose**: Verify BLE readings accuracy against Junction/HealthKit data
- **Priority**: MEDIUM

### 14.2A. Placeholder Implementation Guide

This section provides detailed, step-by-step instructions for completing each placeholder in the BLE Follow Mode implementation.

---

#### 14.2A.1. Discovering Abbott Lingo BLE Protocol

**Goal**: Find the actual Service UUIDs and Characteristic UUIDs used by Abbott Lingo sensors.

**Recommended Approach: Method 1 - xDrip4iOS Source Analysis (Fastest)**

1. **Clone xDrip4iOS repository:**

   ```bash
   cd ~/Desktop
   git clone https://github.com/JohanDegraeve/xdripswift.git
   cd xdripswift
   ```
2. **Search for Abbott/Libre BLE UUIDs:**

   ```bash
   # Search for CBUUID definitions
   grep -r "CBUUID" . --include="*.swift" | grep -i "libre\|abbott" > ~/Desktop/ble_uuids.txt

   # Search for characteristic definitions
   grep -r "Characteristic" . --include="*.swift" | grep -i "glucose" >> ~/Desktop/ble_uuids.txt

   # View results
   cat ~/Desktop/ble_uuids.txt
   ```
3. **Find Abbott-specific transmitter files:**

   ```bash
   # List all Libre-related files
   find . -name "*Libre*" -o -name "*Abbott*"

   # Common files to check:
   # - xdrip/BluetoothTransmitter/CGM/Libre/Libre2Transmitter.swift
   # - xdrip/BluetoothTransmitter/CGM/Libre/Libre3Transmitter.swift
   ```
4. **Extract UUIDs from source:**
   Open the relevant transmitter file and look for:

   ```swift
   // Example from xDrip4iOS (actual values will vary)
   static let serviceUUID = CBUUID(string: "FDE3")  // Abbott manufacturer ID
   static let glucoseCharacteristicUUID = CBUUID(string: "F001")
   static let commandCharacteristicUUID = CBUUID(string: "F002")
   ```
5. **Update BLEFollowManager.swift:**

   ```bash
   # Open the file
   open -a Xcode ~/Downloads/Xcode/Xcode/Services/Bluetooth/BLEFollowManager.swift
   ```

   Replace lines 60-61:

   ```swift
   // OLD (placeholder):
   private let abbottServiceUUID = CBUUID(string: "FFF0")
   private let glucoseCharacteristicUUID = CBUUID(string: "FFF1")

   // NEW (actual UUIDs from xDrip4iOS):
   private let abbottServiceUUID = CBUUID(string: "FDE3")  // Example
   private let glucoseCharacteristicUUID = CBUUID(string: "F001")  // Example
   ```

**Recommended Approach: Method 2 - BLE Scanner (Verification)**

Use this to verify the UUIDs you found in xDrip4iOS:

1. **Install LightBlue app:**

   - Open App Store on iPhone
   - Search "LightBlue Explorer"
   - Install (free)
2. **Prepare test environment:**

   - Ensure Abbott Lingo app is installed and running
   - Verify sensor is connected in Abbott app
   - Keep iPhone near sensor
3. **Scan for devices:**

   - Open LightBlue
   - Look for devices with strong RSSI (> -60 dBm)
   - Check for names containing "Abbott", "Lingo", "Libre" or unknown devices
4. **Inspect discovered device:**

   - Tap on the Abbott sensor
   - View "Services" section
   - Note all Service UUIDs
   - Expand each service to see Characteristics
   - Screenshot everything
5. **Verify against xDrip4iOS findings:**

   - Compare Service UUIDs
   - Compare Characteristic UUIDs
   - Look for characteristics with "Notify" or "Read" properties

**Fallback: Method 3 - Community Research**

If neither method works:

1. **Search GitHub:**

   ```
   "Abbott Lingo" BLE UUID site:github.com
   "Libre 3" bluetooth UUID site:github.com
   FreeStyle Libre characteristic UUID
   ```
2. **Check xDrip4iOS issues:**

   - Visit: https://github.com/JohanDegraeve/xdripswift/issues
   - Search: "Abbott Lingo" or "Libre 3"
   - Look for recent discussions about BLE implementation
3. **Join communities:**

   - NightScout Discord: https://discord.gg/nightscout
   - xDrip4iOS Gitter: https://gitter.im/xDrip4iOS/Lobby
   - Ask: "What BLE UUIDs does Abbott Lingo use?"

**Expected Result:**

You should find UUIDs in one of these formats:

```swift
// Short form (16-bit)
CBUUID(string: "FDE3")

// Long form (128-bit)
CBUUID(string: "0000FDE3-0000-1000-8000-00805F9B34FB")
```

**Estimated Time**: 1-2 hours

---

#### 14.2A.2. Implementing Glucose Data Parsing

**Goal**: Extract glucose value, timestamp, and trend from BLE data packets.

**Recommended Approach: Analyze xDrip4iOS Parsing Logic**

1. **Find data parsing code in xDrip4iOS:**

   ```bash
   cd ~/Desktop/xdripswift

   # Search for glucose parsing methods
   grep -r "parseGlucose\|extractGlucose" . --include="*.swift" -A 20

   # Search for byte array handling
   grep -r "Data\[.*\]" . --include="*.swift" | grep -i "glucose" -A 10
   ```
2. **Study the data structure:**
   Look for code like:

   ```swift
   // Example from xDrip4iOS (simplified)
   func parseGlucoseData(_ data: Data) -> Double? {
       let bytes = [UInt8](data)

       // Glucose is usually in first 2 bytes (little-endian)
       let rawValue = UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)

       // Convert to mg/dL (factor varies by sensor)
       return Double(rawValue) / 18.0
   }
   ```
3. **Implement in BLEFollowManager.swift:**

   **Replace `extractGlucoseValue()` method (line ~196-205):**

   ```swift
   private func extractGlucoseValue(from data: Data) -> Double? {
       // Minimum data length check
       guard data.count >= 4 else {
           print("[BLE DEBUG] Data too short: \(data.count) bytes")
           return nil
       }

       let bytes = [UInt8](data)

       // Log raw data for debugging
       print("[BLE DEBUG] Raw bytes: \(bytes.map { String(format: "%02X", $0) }.joined(separator: " "))")

       // Parse glucose value (bytes 0-1, little-endian)
       // Based on xDrip4iOS implementation
       let rawValue = UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)

       // Conversion factor (adjust based on Abbott spec)
       // Common factors: 18.0 (mmol/L to mg/dL), 10.0, 1.0
       let glucoseMgDl = Double(rawValue) / 18.0

       // Sanity check (glucose should be 40-400 mg/dL)
       guard glucoseMgDl >= 40 && glucoseMgDl <= 400 else {
           print("[BLE DEBUG] Out of range: \(glucoseMgDl) mg/dL")
           return nil
       }

       print("[BLE DEBUG] Parsed glucose: \(glucoseMgDl) mg/dL")
       return glucoseMgDl
   }
   ```

   **Replace `extractTimestamp()` method (line ~207-210):**

   ```swift
   private func extractTimestamp(from data: Data) -> Date? {
       // Option 1: Use current time (simplest)
       // Abbott sends real-time data, so current time is accurate
       return Date()

       // Option 2: Parse timestamp from packet (if available)
       // Uncomment if timestamp is in bytes 4-7:
       /*
       guard data.count >= 8 else { return Date() }
       let bytes = [UInt8](data)
       let timestamp = UInt32(bytes[4]) | (UInt32(bytes[5]) << 8) |
                      (UInt32(bytes[6]) << 16) | (UInt32(bytes[7]) << 24)
       return Date(timeIntervalSince1970: TimeInterval(timestamp))
       */
   }
   ```

   **Replace `extractTrend()` method (line ~212-223):**

   ```swift
   private func extractTrend(from data: Data) -> GlucoseReading.GlucoseTrend? {
       // Check if trend data is available
       guard data.count >= 5 else { return nil }

       let bytes = [UInt8](data)
       let trendByte = bytes[4]  // Adjust index based on actual format

       // Map trend byte to trend enum
       // These mappings are based on common CGM protocols
       // Verify with actual Abbott data
       switch trendByte {
       case 1, 0x01:
           return .rapidlyFalling  // ↓↓ (< -2 mg/dL/min)
       case 2, 0x02:
           return .falling         // ↓  (-2 to -1 mg/dL/min)
       case 3, 0x03:
           return .stable          // →  (-1 to +1 mg/dL/min)
       case 4, 0x04:
           return .rising          // ↑  (+1 to +2 mg/dL/min)
       case 5, 0x05:
           return .rapidlyRising   // ↑↑ (> +2 mg/dL/min)
       default:
           print("[BLE DEBUG] Unknown trend byte: \(trendByte)")
           return .stable  // Default to stable if unknown
       }
   }
   ```
4. **Add debug logging:**

   In `processGlucoseData()` method, add:

   ```swift
   private func processGlucoseData(_ data: Data, from peripheral: CBPeripheral) {
       // Add at the beginning
       print("[BLE DEBUG] ========================================")
       print("[BLE DEBUG] Received data from: \(peripheral.name ?? "Unknown")")
       print("[BLE DEBUG] Data length: \(data.count) bytes")
       print("[BLE DEBUG] Raw hex: \(data.map { String(format: "%02X", $0) }.joined(separator: " "))")

       // ... rest of existing code ...

       // After successful parsing
       print("[BLE DEBUG] ✅ Parsed reading: \(reading.value) mg/dL, trend: \(reading.trend?.symbol ?? "?")")
       print("[BLE DEBUG] ========================================")
   }
   ```
5. **Test and refine:**

   ```bash
   # Build and run on physical device
   xcodebuild -project Xcode.xcodeproj -scheme Xcode -destination 'id=YOUR-DEVICE-UDID' build

   # Monitor console logs
   xcrun devicectl device info logs --device YOUR-DEVICE-UDID --style=stream | grep "BLE DEBUG"
   ```

**Alternative: Iterative Discovery Approach**

If you can't find exact parsing logic:

1. **Capture raw data packets:**

   ```swift
   // In didUpdateValueFor characteristic method, log everything:
   print("RAW DATA [\(data.count) bytes]: \(data.map { String(format: "%02X", $0) })")
   ```
2. **Compare with Abbott app:**

   - Note glucose value in Abbott app: e.g., 120 mg/dL
   - Check console log for corresponding packet
   - Manually calculate which bytes = 120
3. **Experiment with conversion factors:**

   ```swift
   let factors = [1.0, 10.0, 18.0, 18.018]
   for factor in factors {
       let value = Double(rawValue) / factor
       print("Factor \(factor): \(value) mg/dL")
   }
   // Compare output to Abbott app reading
   ```

**Estimated Time**: 2-4 hours

---

#### 14.2A.3. Complete Analytics Integration

**Goal**: Track BLE Follow Mode usage and performance metrics.

**Recommended Approach: Wire Up AnalyticsManager**

1. **Open BLEFollowManager.swift:**

   ```bash
   open -a Xcode ~/Downloads/Xcode/Xcode/Services/Bluetooth/BLEFollowManager.swift
   ```
2. **Replace `trackGlucoseReading()` method (line ~234-237):**

   ```swift
   private func trackGlucoseReading(_ reading: GlucoseReading) {
       AnalyticsManager.shared.track(
           event: "ble_glucose_reading_received",
           properties: [
               "value": reading.value,
               "has_trend": reading.trend != nil,
               "trend": reading.trend?.rawValue ?? "none",
               "data_source": reading.dataSource?.rawValue ?? "unknown",
               "is_recent": reading.isRecent,
               "timestamp": reading.timestamp.timeIntervalSince1970
           ]
       )
   }
   ```
3. **Add analytics throughout BLEFollowManager:**

   **In `enable()` method:**

   ```swift
   func enable() {
       guard !isEnabled else { return }
       isEnabled = true
       UserDefaults.standard.set(true, forKey: "bleFollowModeEnabled")

       // Track enable event
       AnalyticsManager.shared.track(event: "ble_follow_mode_enabled")

       startMonitoring()
   }
   ```

   **In `disable()` method:**

   ```swift
   func disable() {
       guard isEnabled else { return }
       isEnabled = false
       UserDefaults.standard.set(false, forKey: "bleFollowModeEnabled")

       // Track disable event
       AnalyticsManager.shared.track(event: "ble_follow_mode_disabled")

       stopMonitoring()
   }
   ```

   **In `connectToDevice()` method:**

   ```swift
   func connectToDevice(_ deviceId: UUID) {
       guard let peripheral = discoveredPeripherals[deviceId] else {
           error = .sensorNotFound
           AnalyticsManager.shared.track(
               event: "ble_connection_failed",
               properties: ["reason": "device_not_found"]
           )
           return
       }

       connectionStatus = .connecting

       // Track connection attempt
       AnalyticsManager.shared.track(
           event: "ble_connection_attempted",
           properties: [
               "device_id": deviceId.uuidString,
               "device_name": peripheral.name ?? "unknown"
           ]
       )

       centralManager?.connect(peripheral, options: nil)
   }
   ```

   **In `centralManager(_:didConnect:)` delegate:**

   ```swift
   nonisolated func centralManager(
       _ central: CBCentralManager,
       didConnect peripheral: CBPeripheral
   ) {
       Task { @MainActor in
           connectedPeripheral = peripheral
           peripheral.delegate = self
           connectionStatus = .connected

           // Track successful connection
           AnalyticsManager.shared.track(
               event: "ble_connection_succeeded",
               properties: [
                   "device_name": peripheral.name ?? "unknown",
                   "device_id": peripheral.identifier.uuidString
               ]
           )

           peripheral.discoverServices([abbottServiceUUID])
       }
   }
   ```

   **In error scenarios:**

   ```swift
   // In centralManager(_:didFailToConnect:error:)
   AnalyticsManager.shared.track(
       event: "ble_connection_error",
       properties: [
           "error_type": "connection_failed",
           "error_message": error?.localizedDescription ?? "unknown"
       ]
   )

   // In processGlucoseData when parsing fails
   AnalyticsManager.shared.track(
       event: "ble_data_parsing_error",
       properties: [
           "data_length": data.count,
           "error_type": "parsing_failed"
       ]
   )
   ```
4. **Create PostHog dashboard:**

   - Login to PostHog: https://us.posthog.com/project/224201
   - Create new dashboard: "BLE Follow Mode"
   - Add insights for each event
   - Set up alerts for error rates > 5%

**Estimated Time**: 30 minutes

---

#### 14.2A.4. Implement Junction Cross-Validation

**Goal**: Compare BLE readings with Junction/HealthKit data to ensure accuracy.

**Recommended Approach: Async Validation Check**

1. **Open BLEFollowManager.swift:**

   ```bash
   open -a Xcode ~/Downloads/Xcode/Xcode/Services/Bluetooth/BLEFollowManager.swift
   ```
2. **Replace `validateWithJunctionData()` method (line ~228-232):**

   ```swift
   private func validateWithJunctionData(_ reading: GlucoseReading) async {
       // Fetch recent Junction/HealthKit readings for comparison
       // Look for readings within ±15 minutes

       do {
           // Try HealthKit first (fastest)
           let healthKitReadings = try await fetchHealthKitReadings(minutes: 15)

           if let recentReading = healthKitReadings.first {
               let difference = abs(reading.value - recentReading.value)
               let percentDiff = (difference / recentReading.value) * 100

               print("[BLE VALIDATION] BLE: \(reading.value) mg/dL, HealthKit: \(recentReading.value) mg/dL")
               print("[BLE VALIDATION] Difference: \(difference) mg/dL (\(percentDiff)%)")

               // Track validation result
               AnalyticsManager.shared.track(
                   event: "ble_validation_check",
                   properties: [
                       "ble_value": reading.value,
                       "healthkit_value": recentReading.value,
                       "difference_mg_dl": difference,
                       "percent_difference": percentDiff,
                       "validation_passed": percentDiff <= 10
                   ]
               )

               // Alert if significant discrepancy
               if percentDiff > 15 {
                   print("[BLE VALIDATION] ⚠️ Large discrepancy detected!")
                   AnalyticsManager.shared.track(
                       event: "ble_validation_discrepancy",
                       properties: [
                           "ble_value": reading.value,
                           "healthkit_value": recentReading.value,
                           "percent_difference": percentDiff
                       ]
                   )
               }
           } else {
               print("[BLE VALIDATION] No recent HealthKit data for comparison")
           }
       } catch {
           print("[BLE VALIDATION] Error: \(error.localizedDescription)")
       }
   }

   // Helper method to fetch HealthKit readings
   private func fetchHealthKitReadings(minutes: Int) async throws -> [GlucoseReading] {
       return try await withCheckedThrowingContinuation { continuation in
           Task { @MainActor in
               do {
                   // Use HealthKitManager to fetch recent glucose
                   let endDate = Date()
                   let startDate = endDate.addingTimeInterval(-Double(minutes * 60))

                   // Fetch glucose samples from HealthKit
                   let samples = try await HealthKitManager.shared.fetchGlucoseSamples(
                       from: startDate,
                       to: endDate
                   )

                   let readings = samples.map { GlucoseReading(from: $0) }
                   continuation.resume(returning: readings)
               } catch {
                   continuation.resume(throwing: error)
               }
           }
       }
   }
   ```
3. **Add HealthKit fetch method to HealthKitManager (if not exists):**

   ```swift
   // In HealthKitManager.swift
   func fetchGlucoseSamples(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
       guard let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) else {
           throw NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Glucose type unavailable"])
       }

       let predicate = HKQuery.predicateForSamples(
           withStart: startDate,
           end: endDate,
           options: .strictEndDate
       )

       return try await withCheckedThrowingContinuation { continuation in
           let query = HKSampleQuery(
               sampleType: glucoseType,
               predicate: predicate,
               limit: HKObjectQueryNoLimit,
               sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
           ) { _, samples, error in
               if let error = error {
                   continuation.resume(throwing: error)
               } else {
                   let glucoseSamples = samples as? [HKQuantitySample] ?? []
                   continuation.resume(returning: glucoseSamples)
               }
           }

           healthStore.execute(query)
       }
   }
   ```

**Alternative: Simple Threshold Check**

If HealthKit integration is complex, use a simpler validation:

```swift
private func validateWithJunctionData(_ reading: GlucoseReading) async {
    // Simple sanity checks without external data

    // Check 1: Value in reasonable range
    let isInRange = reading.value >= 40 && reading.value <= 400

    // Check 2: Not too different from last reading
    if let lastReading = latestGlucoseReading {
        let timeDiff = reading.timestamp.timeIntervalSince(lastReading.timestamp)
        let valueDiff = abs(reading.value - lastReading.value)

        // Glucose shouldn't change more than ~5 mg/dL per minute
        let maxExpectedChange = (timeDiff / 60) * 5
        let isReasonableChange = valueDiff <= maxExpectedChange

        AnalyticsManager.shared.track(
            event: "ble_validation_check",
            properties: [
                "in_range": isInRange,
                "reasonable_change": isReasonableChange,
                "value_diff": valueDiff,
                "time_diff_seconds": timeDiff
            ]
        )

        if !isReasonableChange {
            print("[BLE VALIDATION] ⚠️ Suspicious reading: \(valueDiff) mg/dL change in \(timeDiff)s")
        }
    }
}
```

**Estimated Time**: 1-2 hours

---

#### 14.2.2. Testing Requirements

**Unit Tests** (Create file: `XcodeTests/BLEFollowManagerTests.swift`):

- [ ] Connection state transitions
- [ ] Glucose data parsing
- [ ] Error handling
- [ ] Data validation logic
- [ ] Mock CoreBluetooth for isolated testing

**Integration Tests**:

- [ ] HealthKit integration
- [ ] Analytics event tracking
- [ ] Junction SDK cross-validation
- [ ] UI updates on data changes
- [ ] Background mode functionality

**Manual Testing** (Physical Device Required):

- [ ] Device discovery works with real Abbott Lingo sensor
- [ ] Connection/disconnection flow
- [ ] Real-time glucose updates (verify accuracy)
- [ ] Trend arrows display correctly
- [ ] Error states show proper messages
- [ ] Setup guide is clear and helpful
- [ ] Battery usage is acceptable (< 5% per 4 hours)
- [ ] Background updates continue when app is backgrounded

#### 14.2.3. Documentation Updates

**Privacy Policy**: Update https://www.viiraa.com/ViiRaa_Privacy_Policy_Notice_US_20250808.pdf

- [ ] Add BLE data collection disclosure
- [ ] Explain Bluetooth usage
- [ ] Document Abbott Lingo integration
- [ ] Update "Data Sources" section

**App Store Listing**: Update description

- [ ] Add BLE Follow Mode to feature list
- [ ] Update screenshots to show BLE interface
- [ ] Mention Abbott Lingo compatibility
- [ ] Update keywords: add "bluetooth", "real-time", "abbott lingo"

### 14.3. TestFlight Beta Deployment

#### 14.3.1. Prepare Build

```bash
# Update version number
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.1.0" Xcode/Resources/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 100" Xcode/Resources/Info.plist

# Build and archive
xcodebuild clean -project Xcode.xcodeproj -scheme Xcode
xcodebuild archive \
  -project Xcode.xcodeproj \
  -scheme Xcode \
  -archivePath ~/Desktop/ViiRaa_v1.1.0.xcarchive \
  -destination 'generic/platform=iOS'
```

#### 14.3.2. TestFlight Release Notes

```markdown
# ViiRaa v1.1.0 - BLE Follow Mode Beta

## New Features
🆕 **BLE Follow Mode** - Real-time glucose monitoring from Abbott Lingo sensors

## What to Test
1. Enable BLE Follow Mode in Settings > Real-time Glucose
2. Ensure Abbott Lingo app is installed and sensor paired
3. Connect to your Abbott Lingo sensor
4. Monitor real-time glucose readings
5. Check battery usage over extended periods (4+ hours)
6. Test background mode (send app to background, verify updates continue)
7. Report any connection issues or crashes

## Requirements
- Abbott Lingo app installed: https://apps.apple.com/us/app/lingo-by-abbott/id6478821307
- Active Abbott Lingo sensor (hardware required)
- Bluetooth enabled
- iOS 15.0 or later

## Known Issues
- Initial connection may take up to 30 seconds
- Sensor must be paired with Abbott Lingo app first
- Glucose value parsing uses simplified algorithm (accuracy may vary)

## How to Provide Feedback
- Email: support@viiraa.com
- Subject: [TestFlight v1.1.0] BLE Follow Mode Feedback
- Include: Device model, iOS version, specific issue
```

#### 14.3.3. Beta Tester Criteria

**Ideal Beta Testers**:

- Currently using Abbott Lingo CGM
- Has Abbott Lingo app installed and active sensor
- Willing to provide detailed feedback
- Can test for at least 1 week

**Invite 20-30 external testers**:

- 10 power users from community
- 5 healthcare professionals
- 5 diabetes management app users
- 5-10 general health enthusiasts

### 14.4. App Store Submission

#### 14.4.1. Update Privacy Policy

Add this section to your privacy policy:

```markdown
## Bluetooth and BLE Follow Mode

When you enable BLE Follow Mode, ViiRaa uses Bluetooth to monitor real-time glucose
data from compatible continuous glucose monitors (CGMs), specifically Abbott Lingo sensors.

**Data Collection**:
- Glucose readings transmitted via Bluetooth
- Connection status and device information
- Reading timestamps
- Glucose trend indicators

**Data Usage**:
- Display real-time glucose levels in the app
- Calculate trends and provide immediate insights
- Cross-validate with HealthKit and Junction data for accuracy

**Data Storage**:
- All glucose data is stored locally on your device
- No BLE glucose data is transmitted to ViiRaa servers
- You can delete all data by disabling BLE Follow Mode or uninstalling the app

**Third-Party Apps**:
- BLE Follow Mode requires the official Abbott Lingo app
- ViiRaa monitors Bluetooth communications using "Follower Mode" approach
- ViiRaa does not modify or interfere with Abbott Lingo app functionality
- Review Abbott's privacy policy: https://www.abbott.com/policies/privacy-policy.html

**Your Control**:
- BLE Follow Mode is optional and can be disabled anytime
- Disabling removes all BLE-related data from the app
- You can manage Bluetooth permissions in iOS Settings > ViiRaa > Bluetooth
```

#### 14.4.2. Update App Store Description

Replace the existing description with:

```markdown
ViiRaa helps you master your metabolism through continuous glucose monitoring (CGM) and personalized coaching.

KEY FEATURES:

• Real-time Glucose Monitoring
Monitor your glucose levels in real-time (1-5 minute updates) with BLE Follow Mode for Abbott Lingo sensors. See instant trends and make informed decisions about your health.

• Personalized Dashboard
Access your health metrics, glucose insights, and progress tracking all in one place.

• Apple HealthKit Integration
Seamlessly sync your CGM data, weight, and activity from Apple Health for comprehensive tracking.

• AI-Powered Coaching
Get real-time guidance from miniViiRaa, your personal AI health coach.

• Bootcamp Programs
Join guided 14-day programs to master glucose control and optimize your metabolism.

• Community Support
Connect with others on the same journey and share your progress.

BLE FOLLOW MODE:

ViiRaa's BLE Follow Mode provides immediate glucose readings from your Abbott Lingo sensor:
- Real-time updates (1-5 minutes)
- Trend indicators (↑↑, ↑, →, ↓, ↓↓)
- Background monitoring
- Battery optimized

Requirements:
- Abbott Lingo app installed
- Active Abbott Lingo sensor
- Bluetooth enabled

ABOUT VIIRAA:

ViiRaa transforms weight control into body intelligence. We believe understanding your glucose responses is the key to sustainable health and energy optimization.

HEALTH DATA:

ViiRaa integrates with:
- Apple Health (glucose, weight, activity)
- Abbott Lingo (real-time glucose via Bluetooth)
- Junction SDK (ML training and analytics)

Your health data is HIPAA-compliant and never shared with third parties.
```

#### 14.4.3. App Review Notes

Update your App Review Information → Notes with:

```
ViiRaa v1.1.0 - BLE Follow Mode Implementation

NEW FEATURE: BLE Follow Mode for real-time glucose monitoring from Abbott Lingo sensors.

IMPORTANT - BLE FOLLOW MODE DETAILS:
✓ Uses Bluetooth to monitor Abbott Lingo app communications
✓ Does NOT directly connect to CGM hardware
✓ Does NOT reverse engineer or decrypt proprietary protocols
✓ Follows "Follower Mode" approach (monitoring public BLE advertisements)
✓ Similar to approved apps: xDrip4iOS, Spike, Diabox
✓ Complies with DMCA and Abbott Terms of Service
✓ Requires official Abbott Lingo app to be installed and running

BLUETOOTH IMPLEMENTATION:
- Service UUID: [Actual UUID once implemented]
- Characteristic UUID: [Actual UUID once implemented]
- Uses CBCentralManager to discover and monitor peripherals
- Respects Apple's background mode limitations
- Battery optimized with 30-second scan timeout

TESTING WITHOUT HARDWARE:
If reviewer does not have Abbott Lingo sensor:
1. Feature is accessible in Settings > Real-time Glucose
2. Setup guide clearly explains requirements
3. App handles "no device found" gracefully
4. Demo video shows full functionality: [YouTube URL]

TESTING WITH HARDWARE (Preferred):
1. Install Abbott Lingo app: https://apps.apple.com/us/app/lingo-by-abbott/id6478821307
2. Pair Abbott Lingo sensor (60-min warm-up required)
3. Open ViiRaa > Settings > Real-time Glucose
4. Enable BLE Follow Mode
5. Connect to discovered device
6. Verify glucose readings appear within 5 minutes

PRIVACY & PERMISSIONS:
✓ NSBluetoothAlwaysUsageDescription clearly explains usage
✓ NSBluetoothPeripheralUsageDescription included
✓ All data stored locally on device
✓ No BLE data transmitted to servers
✓ Privacy policy updated: https://www.viiraa.com/privacy-policy
✓ Bluetooth permission requested at feature enable (not app launch)

BACKGROUND MODES:
✓ bluetooth-central: Required for continuous glucose monitoring
✓ fetch: HealthKit sync (existing feature)
✓ processing: Data analysis (existing feature)

KNOWN LIMITATIONS:
- Requires actual Abbott Lingo sensor (cannot simulate)
- Glucose value parsing uses simplified algorithm (will be enhanced post-launch)
- Initial connection may take 10-30 seconds

DATA COLLECTION UPDATE:
Added to App Store Connect data disclosure:
- Bluetooth device information (not linked to user)
- Real-time glucose readings (linked to user)
- Connection status (not linked to user)

We're available for any questions: support@viiraa.com

Demo Video: [Upload to YouTube as unlisted and include link]
```

#### 14.4.4. Create Demo Video

Record a 2-3 minute demo video showing:

1. **Introduction** (15 seconds)

   - "ViiRaa v1.1.0 introduces BLE Follow Mode"
   - "Real-time glucose monitoring from Abbott Lingo sensors"
2. **Setup Flow** (45 seconds)

   - Navigate to Settings > Real-time Glucose
   - Tap "BLE Follow Mode"
   - Show setup guide
   - Enable "Enable Real-time Glucose" toggle
3. **Device Discovery** (30 seconds)

   - Scan for devices
   - Show Abbott sensor appears in list
   - Tap "Connect"
   - Connection status changes
4. **Real-time Data** (45 seconds)

   - Glucose reading appears
   - Show trend arrow
   - Show last update timestamp
   - Demonstrate auto-refresh
5. **Settings & Management** (15 seconds)

   - Show connection status
   - Demonstrate disconnect
   - Show error handling

Upload to YouTube as **Unlisted** video and include link in App Review notes.

### 14.5. Post-Launch Monitoring

#### 14.5.1. Key Metrics to Track

**Adoption Metrics** (PostHog Dashboard):

```
Target: >30% of Abbott Lingo users enable BLE Follow Mode

Metrics:
- ble_follow_mode_enabled: Count of unique users who enabled feature
- ble_follow_mode_disabled: Count of users who disabled feature
- ble_connection_attempted: Total connection attempts
- ble_connection_succeeded: Successful connections
- ble_glucose_reading_received: Total readings received
```

**Performance Metrics**:

```
Target:
- Connection success rate > 95%
- Average latency < 5 minutes
- Battery impact < 5% per 4 hours

Metrics:
- Time to first reading: Average time from enable to first glucose value
- Connection duration: How long connections stay active
- Error rate: % of sessions with errors
- Battery drain: % battery used per hour with BLE enabled
```

**Quality Metrics**:

```
Target:
- Data validation success > 98%
- User satisfaction > 4.0 stars

Metrics:
- Validation discrepancy rate: % of readings that differ >10% from Junction data
- App Store reviews mentioning BLE
- Support tickets related to BLE
- Crash rate for BLE-related code
```

#### 14.5.2. Monitoring Dashboard Setup

**PostHog Dashboard: "BLE Follow Mode"**

Create charts:

1. **Daily Active BLE Users**: Line chart, event: `ble_glucose_reading_received`, unique users
2. **Connection Success Rate**: Formula: `(ble_connection_succeeded / ble_connection_attempted) * 100`
3. **Error Distribution**: Pie chart, event: `ble_connection_error`, breakdown by `error_type`
4. **Average Readings Per Session**: Bar chart, aggregation: count, breakdown by session

**App Store Connect - Crashes**:

- Check daily for BLE-related crashes
- Filter by: Symbol contains "BLEFollowManager"
- Alert: If crash rate > 1%

**User Reviews**:

- Monitor for keywords: "bluetooth", "connection", "battery", "Abbott", "Lingo"
- Respond within 48 hours
- Escalate critical issues immediately

#### 14.5.3. Rollback Plan

**If Critical Issues Arise**:

**Option 1: Remote Config Kill Switch** (Fastest - requires implementation):

```swift
// Add to BLEFollowManager.swift
func enable() {
    // Check remote feature flag
    guard RemoteConfig.shared.isBLEFollowModeEnabled else {
        connectionStatus = .error("BLE Follow Mode temporarily disabled")
        return
    }
    // ... existing enable logic
}
```

**Option 2: Emergency App Update** (24-48 hours):

```swift
// In BLEFollowManager.swift, replace enable() with:
func enable() {
    // EMERGENCY: Disable BLE due to critical issue
    // Will re-enable in v1.1.2 after fix
    connectionStatus = .error("BLE Follow Mode temporarily unavailable. Update coming soon.")
    AnalyticsManager.shared.track(event: "ble_disabled_by_killswitch")
    return
}
```

Submit emergency v1.1.1 to App Store with "Emergency Update" note requesting expedited review.

**Option 3: Communication Only** (If issue affects < 10% of users):

- Post in-app message
- Email affected users
- Social media announcement
- Provide workaround if available

### 14.6. Feature Enhancement Roadmap

**v1.1.1** (Week 2-3 post-launch):

- Bug fixes from beta feedback
- Enhanced error messages
- Improved connection reliability

**v1.2.0** (Month 2):

- Real-time glucose alerts (high/low thresholds)
- Historical trend graph with BLE data
- Apple Watch companion app

**v1.3.0** (Month 3-4):

- Multi-sensor support (Dexcom via Follower Mode)
- Export glucose data (CSV, PDF)
- Integration with ML prediction model

**v2.0.0** (Month 6):

- Caregiver sharing (remote monitoring)
- Advanced analytics dashboard
- Siri Shortcuts integration

### 14.7. Success Criteria

**Technical Success**:

- ✅ Build succeeds without errors
- ✅ BLE connection works with Abbott Lingo sensors
- ✅ Real-time glucose readings appear within 5 minutes
- ✅ Battery impact < 5% per 4 hours
- ✅ No crashes in BLE code path
- ✅ Background mode works correctly

**User Success**:

- ✅ >30% adoption rate among Abbott Lingo users
- ✅ >60% complete dual-app setup
- ✅ 4.0+ star rating for BLE feature
- ✅ <10% churn due to BLE issues

**Business Success**:

- ✅ Increased user engagement (higher DAU)
- ✅ Improved retention (users see immediate value)
- ✅ Positive press coverage
- ✅ Competitive advantage over 3-hour latency competitors

### 14.8. Support & Troubleshooting

**Common User Issues**:

| Issue                   | Cause                  | Solution                                       |
| ----------------------- | ---------------------- | ---------------------------------------------- |
| "No devices found"      | Abbott app not running | Open Abbott Lingo app first                    |
| "Connection failed"     | Sensor out of range    | Move closer to sensor                          |
| "Readings not updating" | Connection dropped     | Reconnect in Settings                          |
| "Battery drains fast"   | Continuous scanning    | Disable/re-enable BLE mode                     |
| "Inaccurate readings"   | Data parsing issue     | Cross-check with Abbott app, report to support |

**Support Email Template**:

```
Subject: BLE Follow Mode Support - [Issue Type]

Hi [User],

Thank you for reporting this issue with BLE Follow Mode.

To help us diagnose the problem, please provide:
1. Device model (e.g., iPhone 15 Pro)
2. iOS version (Settings > General > About)
3. Abbott Lingo app version
4. Steps to reproduce the issue
5. Screenshot of error (if applicable)

In the meantime, you can:
- [Workaround step 1]
- [Workaround step 2]
- Continue using HealthKit sync (3-hour latency)

We'll investigate and respond within 24 hours.

Best,
ViiRaa Support Team
```

### 14.9. Legal & Compliance

**App Store Compliance**:

- ✅ Follower Mode approach (legal)
- ✅ No reverse engineering
- ✅ No proprietary protocol decryption
- ✅ Respects Abbott Terms of Service
- ✅ Similar to approved apps (xDrip4iOS precedent)

**HIPAA Compliance**:

- ✅ All glucose data stored locally (no server transmission)
- ✅ Encrypted storage (iOS Keychain)
- ✅ User can delete all data
- ✅ Privacy policy updated

**Abbott Relationship**:

- ⚠️ Not officially partnered with Abbott
- ✅ Does not interfere with Abbott app
- ✅ Requires Abbott app to function
- ✅ Clear attribution to Abbott Lingo

### 14.10. Resources

**Documentation**:

- [BLE Implementation Summary](BLE_IMPLEMENTATION_SUMMARY.md)
- [Software Development Document](Software_Development_Document.md) (Lines 1553-2039)
- [3rd Party Bio Data Integration Report](3rd_Party_Bio_Data_Integration_Report.md)

**External Resources**:

- xDrip4iOS: https://github.com/JohanDegraeve/xdripswift
- xDrip4iOS Docs: https://xdrip4ios.readthedocs.io/
- Abbott Lingo App: https://apps.apple.com/us/app/lingo-by-abbott/id6478821307
- Apple CoreBluetooth: https://developer.apple.com/documentation/corebluetooth

**Support**:

- Engineering: engineering@viiraa.com
- Support: support@viiraa.com
- Emergency: [On-call phone]

---

## 15. Change Log

| Version | Date       | Changes                                                                                                                                                                                                                                                                     |
| ------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0     | 2025-10-14 | Initial implementation guide                                                                                                                                                                                                                                                |
| 1.1     | 2025-10-15 | Added comprehensive build error troubleshooting section with SDK-specific fixes                                                                                                                                                                                             |
| 1.2     | 2025-11-25 | Added Junction SDK Integration section with step-by-step guide for connecting iOS app to Junction for bio data sync and ML training                                                                                                                                         |
| 1.3     | 2025-12-02 | Added comprehensive App Privacy and Data Collection Disclosure section (9.1) with detailed answers to Apple's App Store data collection questionnaire, including all required data types, third-party partners, retention policies, and review notes                        |
| 1.4     | 2025-12-02 | Added Content Rights Documentation section (9.2.7) covering Apple's requirement to document legal rights to third-party content, including health data, third-party services, UI assets, educational content, and user-generated content with template declaration document |
| 1.5     | 2025-12-02 | Added comprehensive BLE Follow Mode Deployment section (14) with pre-deployment checklist, TestFlight beta instructions, App Store submission guidance, post-launch monitoring, rollback plans, and success criteria for real-time glucose monitoring feature               |
| 1.6     | 2025-12-16 | Added Junction Sync Troubleshooting section (11.9) based on Bug #21 analysis: includes sync health check functions, permission mismatch detection, step-by-step debugging procedures, testing recommendations, and key learnings. Implements `performSyncHealthCheck()`, `verifySyncSuccess()`, and `syncHealthDataWithVerification()` functions in JunctionManager.swift |
| 1.7     | 2025-12-16 | **Bug #21 Resolution Update**: Identified root cause - Junction only syncs glucose data from recognized CGM device sources (`com.abbott.lingo`, `com.dexcom.*`), NOT manually-entered data or mock data. Added section 11.9.8 documenting iOS Simulator limitations for Junction testing. Added debug functions: `writeMockGlucoseData()`, `debugGlucoseDataSources()`, `forceRequestGlucosePermission()`, `runFullBug21Diagnostic()`. Updated SettingsView with troubleshooting UI. Documented that production validation requires physical iPhone with real Abbott Lingo CGM. |
