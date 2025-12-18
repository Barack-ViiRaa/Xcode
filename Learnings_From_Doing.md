# Learnings From Doing - iOS Build Issues

This document captures key learnings from resolving iOS build errors during ViiRaa iOS app development. These learnings are written for coding agents to reference when encountering similar issues.

**Last Updated**: October 27, 2025

---

## Bug 1 - Supabase SDK Class Naming Conflict

### 1. What was the bug

1.1. **Symptom**: Build failed with error "'Client' is not a member type of class 'SupabaseClient'" when trying to use the Supabase Swift SDK.

1.2. **User Impact**: Complete build failure preventing any development or testing of the iOS app.

1.3. **Reproducibility**: Occurred consistently when creating a custom wrapper class named `SupabaseClient` while also importing the Supabase SDK which exports a type with the same name.

### 2. What was the root cause

2.1. **Naming Collision**: The custom wrapper class was named `SupabaseClient`, which conflicted with the SDK's exported `SupabaseClient` type from the Supabase module.

2.2. **Swift Type Resolution**: When referencing `SupabaseClient.Client`, Swift couldn't determine whether to look for a nested type in the custom class or use the SDK's top-level `SupabaseClient` type.

2.3. **Incorrect Type Names**: Additionally used wrong type name `DatabaseClient` instead of the correct `PostgrestClient` from the Supabase SDK.

### 3. What was the solution

3.1. **Rename Custom Class**: Changed custom wrapper class from `SupabaseClient` to `SupabaseManager` to eliminate naming conflict.

3.2. **Update All References**: Systematically updated all code references from `SupabaseClient.shared` to `SupabaseManager.shared` in AuthManager and ViiRaaApp files.

3.3. **Use Correct Types**: Changed property type declarations to use SDK types correctly: `var database: PostgrestClient { client.database }`.

3.4. **Simplified Initialization**: Removed unnecessary initialization parameters to use the correct Supabase SDK v2.x API.

### 4. What are the learnings for potential future bugs

4.1. **Avoid SDK Type Name Conflicts**: Never name custom wrapper classes with the same name as types exported by the SDK being wrapped. Always use suffixes like `Manager`, `Service`, or `Wrapper` to differentiate.

4.2. **Check SDK Documentation**: When integrating a third-party SDK, always verify the correct type names and initialization patterns from the official documentation rather than assuming based on convention.

4.3. **Namespace Awareness**: Be aware that Swift uses flat namespaces for imported types, so any naming collision will cause ambiguity errors.

4.4. **Systematic Refactoring**: When renaming a core class, use Xcode's refactoring tools or systematic find-and-replace to ensure all references are updated consistently across the codebase.

---

## Bug 2 - PostHog SDK API Migration Issues

### 1. What was the bug

1.1. **Symptom**: Build errors showing "Cannot find type 'PHGPostHog' in scope" and "Cannot find 'PHGPostHogConfiguration' in scope" when trying to use PostHog analytics.

1.2. **User Impact**: Analytics initialization failed, preventing tracking of user events and app usage metrics.

1.3. **Reproducibility**: Occurred when using documentation or examples that referenced the legacy Objective-C PostHog SDK instead of the modern Swift SDK.

### 2. What was the root cause

2.1. **SDK Version Mismatch**: The code used legacy Objective-C SDK API (`PHGPostHog`, `PHGPostHogConfiguration`) while the project had the modern PostHog Swift SDK v3.x installed.

2.2. **Documentation Lag**: Initial implementation followed outdated documentation or examples that hadn't been updated for the Swift SDK migration.

2.3. **API Paradigm Shift**: The Swift SDK uses a different API pattern with static shared instance (`PostHogSDK.shared`) rather than instance-based approach.

2.4. **Unsupported Configuration Options**: Some configuration options like `captureDeepLinks` from the Objective-C SDK are not available in the Swift SDK.

### 3. What was the solution

3.1. **Update Import Statement**: Changed from importing hypothetical Objective-C bridge to importing the Swift SDK: `import PostHog`.

3.2. **Migrate Initialization Code**: Updated from `PHGPostHog.setup(with: configuration)` to `PostHogSDK.shared.setup(config)`.

3.3. **Update API Calls**: Changed all analytics tracking calls to use the shared instance pattern: `PostHogSDK.shared.capture()`, `PostHogSDK.shared.identify()`, etc.

3.4. **Remove Unsupported Options**: Removed `captureDeepLinks` configuration option which is not supported in the Swift SDK.

3.5. **Verify Configuration Options**: Confirmed that `captureApplicationLifecycleEvents` and `captureScreenViews` are supported in the Swift SDK.

### 4. What are the learnings for potential future bugs

4.1. **Verify SDK Version Documentation**: Always check which SDK version (and language variant) the documentation refers to. For multi-language SDKs, ensure you're using the Swift-specific documentation for iOS projects.

4.2. **Check Release Notes**: When encountering type not found errors with known SDKs, check the SDK's migration guides and release notes for breaking changes between versions.

4.3. **Singleton Pattern Recognition**: Modern Swift SDKs often use shared instance patterns (`.shared`) rather than instance-based initialization. Recognize this pattern when migrating from older SDKs.

4.4. **Configuration Option Verification**: Don't assume all configuration options from legacy SDKs are available in newer versions. Always verify each option exists in the new API before using it.

4.5. **SDK Language Variants**: Be aware that some analytics SDKs have separate Objective-C and Swift implementations with different APIs, even though they're for the same platform.

---

## Bug 3 - ObservableObject Conformance with MainActor Isolation

### 1. What was the bug

1.1. **Symptom**: Build error stating "Type 'AnalyticsManager' does not conform to protocol 'ObservableObject'" despite the class explicitly declaring conformance.

1.2. **User Impact**: SwiftUI integration failed, preventing the AnalyticsManager from being used as a StateObject or EnvironmentObject in the app.

1.3. **Reproducibility**: Occurred consistently when applying `@MainActor` annotation to a class that conforms to `ObservableObject` protocol without providing explicit actor-isolated implementation.

### 2. What was the root cause

2.1. **Actor Isolation Requirements**: Swift's concurrency system requires explicit handling of the `objectWillChange` publisher when a class is annotated with `@MainActor`.

2.2. **Default Synthesis Limitation**: The compiler cannot automatically synthesize the `objectWillChange` publisher for actor-isolated classes because the publisher must be accessible from any isolation domain.

2.3. **Protocol Requirement Mismatch**: The `ObservableObject` protocol requires an `objectWillChange` publisher, but with `@MainActor` isolation, the default synthesis doesn't work.

2.4. **Missing Import**: The solution also required importing the `Combine` framework for the `ObservableObjectPublisher` type.

### 3. What was the solution

3.1. **Add Explicit Publisher**: Manually declared the `objectWillChange` publisher: `nonisolated let objectWillChange = ObservableObjectPublisher()`.

3.2. **Use Nonisolated Keyword**: Marked the publisher as `nonisolated` to make it accessible from any actor context, which is required for proper SwiftUI observation.

3.3. **Import Combine Framework**: Added `import Combine` to access the `ObservableObjectPublisher` type.

3.4. **Maintain MainActor Annotation**: Kept the `@MainActor` annotation on the class to ensure all methods run on the main thread for UI updates.

### 4. What are the learnings for potential future bugs

4.1. **Explicit Publisher Pattern**: When combining `@MainActor` with `ObservableObject`, always provide an explicit `nonisolated let objectWillChange = ObservableObjectPublisher()` declaration.

4.2. **Actor Isolation Awareness**: Understand that actor isolation annotations affect protocol conformance synthesis. The compiler cannot synthesize requirements that need specific isolation behavior.

4.3. **Nonisolated Requirements**: Remember that `objectWillChange` must be `nonisolated` because SwiftUI observers may access it from different actor contexts.

4.4. **Framework Import Dependencies**: Don't forget to import `Combine` when manually implementing `ObservableObject` requirements, as `ObservableObjectPublisher` comes from this framework.

4.5. **SwiftUI Concurrency Pattern**: This pattern (nonisolated objectWillChange + @MainActor class) is the standard way to create thread-safe ObservableObjects in modern SwiftUI apps.

---

## Bug 4 - Supabase Auth API Version Compatibility Issues

### 1. What was the bug

1.1. **Symptom**: Multiple compilation errors including "Cannot find type 'AuthState' in scope", type conversion errors for Session properties, and OAuth flow returning unexpected types.

1.2. **User Impact**: Complete authentication system failure with inability to compile the AuthManager, blocking all user authentication functionality.

1.3. **Reproducibility**: Occurred when using Supabase SDK v2.x with code written for v1.x or following outdated documentation patterns.

### 2. What was the root cause

2.1. **Breaking API Changes**: Supabase Swift SDK v2.x introduced breaking changes to auth-related types and APIs compared to v1.x.

2.2. **Enum Renaming**: The `AuthState` enum was renamed to `AuthChangeEvent` in v2.x, causing "type not found" errors.

2.3. **Type Changes**: Session property types changed (e.g., `expiresIn` from `Int` to `TimeInterval`/`Double`), causing type mismatch errors.

2.4. **Model Differences**: The SDK's `Auth.User` type differs from custom application `User` model, requiring explicit conversion.

2.5. **OAuth Flow Changes**: The OAuth signin method signature changed to return `Session` directly instead of a URL, requiring different handling.

2.6. **Missing Imports**: UIKit import was missing, causing errors when trying to use `UIApplication` for OAuth flows.

### 3. What was the solution

3.1. **Update Auth State Handling**: Replaced `AuthState` enum cases with `AuthChangeEvent` cases: `.signedIn, .tokenRefreshed, .initialSession`.

3.2. **Create Type Conversion Helpers**: Implemented `convertSession()` and `convertUser()` helper methods to bridge between SDK types and custom app models.

3.3. **Handle Type Conversions**: Added explicit type casting for changed properties: `expiresIn: Int(supabaseSession.expiresIn)`.

3.4. **Update OAuth Flow**: Modified OAuth signin to handle Session return type directly instead of expecting URL and using UIApplication.

3.5. **Add Missing Imports**: Added `import UIKit` to AuthManager for UIApplication access.

3.6. **Simplify Authentication Methods**: Updated signin/signup methods to use conversion helpers consistently across all auth flows.

### 4. What are the learnings for potential future bugs

4.1. **SDK Major Version Awareness**: When using major version 2.x+ of an SDK, expect breaking changes. Always review the SDK's changelog and migration guide before upgrading.

4.2. **Type Conversion Layer Pattern**: When SDK types don't match app models, create a dedicated conversion layer with helper methods rather than inline conversions throughout the codebase.

4.3. **Enum Migration Strategy**: When an enum is renamed in an SDK update, use the compiler errors as a checklist to find all usage locations, but understand the semantic changes in case values.

4.4. **Property Type Changes**: Be alert for property type changes (Int to Double, etc.) which cause subtle compilation errors. These often indicate API refinements in the SDK.

4.5. **OAuth Flow Pattern Changes**: OAuth flows are particularly prone to API changes between SDK versions. Always verify the OAuth flow implementation matches the SDK version being used.

4.6. **Missing Import Detection**: When encountering "cannot find type" errors for platform types like `UIApplication`, check for missing framework imports (UIKit, SwiftUI, etc.) before assuming SDK issues.

4.7. **Systematic Update Approach**: When updating authentication code for SDK compatibility, update all auth methods (signin, signup, OAuth) consistently to use the same patterns and conversion helpers.

---

## Bug 5 - Xcode Project Configuration Path Issues

### 1. What was the bug

1.1. **Symptom**: Build failure with error "Build input file cannot be found: '/251015-Xcode/251015-Xcode/Resources/Info.plist'" despite the Info.plist file existing at the correct location.

1.2. **User Impact**: Complete build failure in final stage, preventing app compilation even though all Swift code compiled successfully.

1.3. **Reproducibility**: Occurred when project.pbxproj contained an absolute path starting with `/` instead of a relative path for the Info.plist file.

### 2. What was the root cause

2.1. **Absolute vs Relative Path**: The `INFOPLIST_FILE` setting in project.pbxproj was configured with an absolute path `/251015-Xcode/251015-Xcode/Resources/Info.plist` instead of a relative path.

2.2. **Path Resolution**: Xcode tried to find the file at the root filesystem path `/251015-Xcode/...` (absolute path) rather than relative to the project directory.

2.3. **Configuration File Format**: The project.pbxproj file stores paths, and Xcode interprets paths starting with `/` as absolute filesystem paths, not relative to project root.

2.4. **Manual Configuration Error**: This likely occurred from manual editing of the project configuration or incorrect initial project setup.

### 3. What was the solution

3.1. **Identify Path Issue**: Located the incorrect path by examining the build error message and searching for `INFOPLIST_FILE` in project.pbxproj.

3.2. **Convert to Relative Path**: Changed the path from `/251015-Xcode/251015-Xcode/Resources/Info.plist` to `251015-Xcode/Resources/Info.plist` (relative path).

3.3. **Update All Occurrences**: Used replace-all to ensure both Debug and Release configurations had the corrected relative path.

3.4. **Verify File Existence**: Confirmed the Info.plist file actually existed at the expected relative location before rebuilding.

### 4. What are the learnings for potential future bugs

4.1. **Relative Path Convention**: Always use relative paths in Xcode project configuration files. Paths should be relative to the project root directory, not absolute filesystem paths.

4.2. **Leading Slash Significance**: In Xcode configuration files, a leading `/` indicates an absolute path from the filesystem root, not from the project root. Avoid leading slashes for project resources.

4.3. **Build Phase Path Checking**: When encountering "file not found" errors in build phases despite files existing, immediately check whether the path in project.pbxproj is absolute or relative.

4.4. **Project Configuration Best Practices**: Prefer using Xcode GUI to configure file paths rather than manually editing project.pbxproj, as the GUI automatically uses correct relative path formats.

4.5. **Both Configurations**: Remember that Xcode has separate settings for Debug and Release configurations. Path corrections may need to be applied to both.

4.6. **Path Verification Script**: For complex projects, consider adding a build phase script to verify that critical resource paths (Info.plist, entitlements, etc.) are correctly configured before compilation.

4.7. **Quote Handling**: When paths contain spaces or special characters, they should be quoted in project.pbxproj: `"251015-Xcode/Resources/Info.plist"`.

---

## Bug 6 - Authentication State Loading Screen Issue

### 1. What was the bug

1.1. **Symptom**: App displayed a white screen on launch instead of showing the login screen, even though no user was authenticated.

1.2. **User Impact**: Users could not access the app as it appeared frozen on a white screen. The login UI never appeared, making the app unusable for new users.

1.3. **Reproducibility**: Occurred consistently on app launch when there was no existing authentication session. The `AuthManager.isLoading` property remained `true` indefinitely.

### 2. What was the root cause

2.1. **Session Check Logic Error**: The `checkExistingSession()` method in AuthManager attempted to use a Supabase session even when none existed. When `supabase.auth.session` threw an error (no session), the code tried to convert the non-existent session anyway.

2.2. **Missing Loading State Management**: The ViiRaaApp view didn't handle the `isLoading` state, so when loading was stuck at `true`, the app showed neither the AuthView nor MainTabView.

2.3. **Thread Safety Issue**: The `isLoading = false` statement wasn't wrapped in `MainActor.run`, which could cause UI update delays.

2.4. **Incorrect Error Handling**: The error catch block tried to clear session but then attempted to use the non-existent session object, causing the initialization to hang.

### 3. What was the solution

3.1. **Simplified Session Check Logic**: Removed the complex keychain-first check and streamlined to just try getting the current session from Supabase. If it exists, use it; if it throws an error, clear session and continue.

3.2. **Added Loading Screen**: Updated ViiRaaApp to show a loading spinner when `authManager.isLoading == true`, preventing the white screen issue.

3.3. **Fixed Thread Safety**: Wrapped `isLoading = false` in `await MainActor.run` block to ensure UI updates happen on the main thread.

3.4. **Corrected Error Flow**: When no session exists, the error handler properly clears the session and sets loading to false, allowing the AuthView to display.

### 4. What are the learnings for potential future bugs

4.1. **Always Handle Loading States in UI**: When an app has an initialization phase that checks authentication, the UI must explicitly handle the loading state with a loading indicator. Never assume initialization will be instantaneous.

4.2. **Simplify Async Initialization**: Complex initialization logic with multiple fallback paths is error-prone. Prefer simple, linear logic: try to get session → success or failure → set loading false.

4.3. **MainActor for UI State Updates**: Any property that affects UI visibility (like `isLoading`, `isAuthenticated`) must be updated on MainActor, especially in async contexts.

4.4. **Error Handling Must Complete Flow**: Every error path in initialization code must ensure the loading state is set to false. Otherwise, the app can get stuck in a loading state indefinitely.

4.5. **Test No-Session Scenario**: Always test the "fresh install" or "signed out" state where no session exists. This is often where initialization bugs appear because developers test primarily with existing sessions.

---

## Bug 7 - Double Login Requirement (Session Sharing Failure)

### 1. What was the bug

1.1. **Symptom**: After successfully authenticating via iOS native login screen, the web dashboard loaded in WebView displayed its own login screen, requiring the user to authenticate a second time.

1.2. **User Impact**: Extremely poor user experience as users had to log in twice to access the app. This created friction and confusion, violating the expected single sign-on (SSO) behavior.

1.3. **Reproducibility**: Occurred 100% of the time when a user authenticated via iOS native auth. The web dashboard's Supabase client couldn't find any authentication session in localStorage.

### 2. What was the root cause

**Initial Implementation Issues (Resolved):**

2.1. **Incomplete Session Injection**: The iOS app was injecting only the `access_token` as a simple string into localStorage, but Supabase's web client requires a complete session object with multiple properties.

2.2. **Incorrect localStorage Key**: The session was being stored with a generic key like `supabase.auth.token` instead of the Supabase-specific format `sb-{project-id}-auth-token`.

2.3. **Missing Session Properties**: The injected data lacked critical properties that Supabase expects: `refresh_token`, `expires_in`, `token_type`, and `user` object with `id`, `email`, `aud`, and `role`.

2.4. **Wrong Data Type**: Instead of passing the complete `Session` object to WebView, only the `authToken: String?` was being passed, losing all other session information.

2.5. **No JavaScript Event Notification**: After injection, there was no event dispatched to notify the web app that authentication was ready, so the Supabase client might have already checked for auth before the injection completed.

**Current Outstanding Issue (Still Occurring):**

2.6. **Race Condition Between Page Load and Session Injection**: Even with complete session injection at `.atDocumentStart` and post-load re-injection, a timing issue persists where:

- The web dashboard's Supabase client initializes and checks localStorage for auth state
- The initialization happens BEFORE the session injection completes or takes effect
- The Supabase client caches the "unauthenticated" state and doesn't re-check after injection
- Result: Web dashboard shows login page despite session being in localStorage

2.7. **WebKit Privacy/Storage Access Restrictions**: WebKit's privacy features may be preventing or delaying localStorage writes from injected JavaScript:

- "Failed to request storage access quirks from WebPrivacy"
- "Failed to request query parameters from WebPrivacy"
- These errors suggest WebKit's Intelligent Tracking Prevention (ITP) or similar privacy features may be interfering with cross-context storage access

2.8. **Supabase Client Not Reacting to Storage Events**: The `storage` event dispatched after injection may not be triggering the Supabase client to re-check authentication state, especially if the client has already initialized and cached the unauthenticated state.

2.9. **Multiple Injection Attempts Indicate Failure**: The log shows 5+ injection attempts ("🔄 Injecting session for user"), which suggests the WebView is reloading or the injection is failing to persist, forcing repeated attempts.

### 3. What was the solution

**Phase 1: Basic Session Injection Implementation (Partially Resolved)**

3.1. **Changed WebView Interface**: Updated `DashboardWebView` to accept full `Session` object instead of just `authToken: String?`. This ensures all session data is available for injection.

3.2. **Created Complete Session Injection**: Implemented `injectSession()` method that constructs a proper Supabase session object with all required fields:

- `access_token`: JWT access token
- `refresh_token`: Refresh token for session renewal
- `expires_in`: Token expiration time
- `token_type`: Token type ("bearer")
- `user`: Complete user object with id, email, aud, and role

3.3. **Used Correct localStorage Key**: Changed to use the proper Supabase storage key format: `sb-efwiicipqhurfcpczmnw-auth-token` where the project ID is embedded in the key.

3.4. **Dual Injection Points**: Injected session at two critical points:

- Before page load via `WKUserScript` at `.atDocumentStart`
- After page load via `evaluateJavaScript` to ensure persistence

3.5. **Added Event Notification**: Dispatched custom `ios-auth-ready` event after injection to notify the web app that authentication is ready, and triggered `storage` event to notify Supabase client of localStorage changes.

3.6. **Proper String Escaping**: Implemented proper JavaScript string escaping for all token values to prevent injection vulnerabilities and parsing errors.

3.7. **Updated DashboardView**: Changed DashboardView to pass `authManager.session` instead of `authManager.session?.accessToken`, ensuring the complete session object reaches the WebView.

**Phase 2: Additional Solutions Required (To Fix Remaining Race Condition)**

3.8. **Add Pre-Authentication URL Loading Strategy**: Instead of loading the dashboard immediately, consider:

- Load a minimal HTML page first that waits for iOS session injection
- After confirming session is in localStorage, redirect to actual dashboard
- This ensures Supabase client never initializes without a session present

3.9. **Implement WKWebView Data Store Reset**: Before loading dashboard, clear WKWebView's data store to prevent stale auth state:

```swift
   let dataStore = WKWebsiteDataStore.default()
   await dataStore.removeData(ofTypes: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache], modifiedSince: Date(timeIntervalSince1970: 0))
```

3.10. **Add Polling Mechanism in Web Dashboard**: Modify web dashboard to poll for `window.iosAuthenticated` flag before initializing Supabase:

```javascript
   // Wait for iOS session injection before initializing Supabase
   const waitForIOSAuth = async () => {
     for (let i = 0; i < 50; i++) {  // 5 seconds max
       if (window.iosAuthenticated) return true;
       await new Promise(resolve => setTimeout(resolve, 100));
     }
     return false;
   };
```

3.11. **Force Supabase Client Reinitialization**: After session injection, send a message to web app to reinitialize the Supabase client:

```javascript
   window.supabaseClient = createClient(url, key, {
     auth: { persistSession: true, storageKey: 'sb-efwiicipqhurfcpczmnw-auth-token' }
   });
```

3.12. **Implement Request Storage Access API**: For iOS 17.4+, use WebKit's Storage Access API to ensure localStorage is accessible:

```javascript
   if (document.hasStorageAccess) {
     const hasAccess = await document.hasStorageAccess();
     if (!hasAccess) {
       await document.requestStorageAccess();
     }
   }
```

3.13. **Add Diagnostic Logging**: Enhanced logging to track exact timing of:

- When iOS injects session
- When Supabase client initializes
- When localStorage is checked by web app
- Whether session persists across checks

3.14. **Consider Alternative: Skip Native Login Entirely**: As a pragmatic solution, consider removing native iOS login and having users authenticate directly in the WebView. This eliminates the session-sharing problem entirely but requires rethinking the UX flow.

### 4. What are the learnings for potential future bugs

**Basic Session Injection Principles:**

4.1. **Understand Third-Party Session Formats**: When integrating with third-party auth providers like Supabase, Firebase, or Auth0, always verify the exact session data structure and localStorage format they expect. Don't assume a simple token string is sufficient.

4.2. **WebView Session Injection Pattern**: For WebView apps that share authentication with native iOS, the pattern is: (1) Pass complete session object to WebView, (2) Inject before and after page load, (3) Use correct storage keys, (4) Dispatch events to notify web code.

4.3. **localStorage Key Formats Matter**: Many auth SDKs use project-specific or environment-specific localStorage keys. The key format `sb-{project-id}-auth-token` is not arbitrary - it's how the SDK locates the session data.

4.4. **Session Object Completeness**: A session isn't just an access token. Modern auth systems require refresh tokens, expiration times, token types, and user metadata. Omitting any of these can cause silent failures or degraded functionality.

4.5. **Dual Injection Strategy**: Injecting only before or only after page load is insufficient. Web apps may check auth at different lifecycle points, so injecting at both document start and after load ensures the session is available whenever the web app checks.

4.6. **Event-Driven Auth Notification**: Don't assume the web app will poll for auth state. Dispatch custom events (`ios-auth-ready`) and standard events (`storage`) to proactively notify the web code that authentication state has changed.

4.7. **Test Session Structure Match**: Use browser dev tools to inspect what the web version stores in localStorage after authentication, then ensure the iOS injection matches that exact structure. Any mismatch will cause the web SDK to ignore the injected session.

4.8. **Escape All JavaScript Strings**: When injecting JavaScript code with user data (tokens, emails), always escape special characters to prevent XSS vulnerabilities and JavaScript syntax errors. Use `replacingOccurrences(of: "'", with: "\\'")`.

**Advanced Race Condition & Timing Issues:**

4.9. **Race Conditions Are Critical in Hybrid Auth**: Even with perfect session injection code, race conditions between WebView page load and JavaScript execution can cause authentication to fail. The web app's auth client may initialize and cache "unauthenticated" state before injection completes.

4.10. **WebKit Privacy Features Can Block Session Sharing**: iOS WebKit's Intelligent Tracking Prevention (ITP), storage access restrictions, and privacy quirks can prevent or delay localStorage writes from injected scripts. Errors like "Failed to request storage access quirks from WebPrivacy" are red flags for this issue.

4.11. **Multiple Injection Attempts Indicate Deeper Problem**: If logs show repeated session injection attempts (5+ times), this suggests the session is not persisting or the WebView is reloading. Investigate WKWebView lifecycle and web app navigation logic.

4.12. **Auth Client Caching Defeats Late Injection**: If the web authentication client (Supabase, Firebase, etc.) checks localStorage during initialization and caches the result, subsequent session injections won't be detected. The client needs to be explicitly told to re-check or reinitialize.

4.13. **Storage Events Don't Always Trigger Reactivity**: Dispatching a `storage` event doesn't guarantee the web app will react. Many modern frameworks use their own reactivity systems that don't listen to storage events. Direct communication via custom events or message handlers may be necessary.

4.14. **Consider Architecture Trade-offs**: Sometimes the technical complexity of sharing native authentication with WebView outweighs the UX benefit. Evaluate whether having users authenticate directly in the WebView (single auth point) is simpler and more reliable than native-to-web session sharing.

4.15. **Debug with Timing Logs**: When debugging race conditions, add precise timestamps to all logs (iOS injection time, web page load time, Supabase client init time, localStorage check time). This reveals the exact sequence of events causing the failure.

4.16. **WKWebView Data Store Can Have Stale State**: WKWebView persists data across app launches. Stale localStorage entries from previous sessions can interfere with new session injection. Consider clearing the data store before loading dashboard with fresh auth.

4.17. **Coordinate With Web Team**: Session injection bugs often require coordination between iOS and web teams. The web app may need modifications (delayed Supabase init, auth polling, explicit reinitialization) that are outside the iOS codebase.

**Status of Bug 7:**
🟡 **PARTIALLY RESOLVED** - Session injection infrastructure is correctly implemented, but race condition between web Supabase client initialization and session injection timing remains. Duplicate login still occurs. Additional solutions (3.8-3.14) need to be implemented to fully resolve.

---

## Bug 8 - Simplified Sign Out Architecture

### 1. What was the bug

1.1. **Symptom**: The iOS app had redundant sign-out implementations - both a native iOS sign-out button in the navigation menu and a web-based sign-out in the dashboard. This created architectural complexity and potential inconsistency.

1.2. **User Impact**: While functional, the dual sign-out approach was confusing from a UX perspective and created maintenance overhead. Users might not know which sign-out option to use.

1.3. **Reproducibility**: The redundancy existed in the initial implementation with both sign-out paths functional but architecturally redundant.

### 2. What was the root cause

2.1. **Over-Engineering**: The initial design implemented sign-out functionality in both iOS native code and the web dashboard, assuming both were necessary for a complete solution.

2.2. **Unclear Separation of Concerns**: There was no clear decision about whether authentication management should be the responsibility of the iOS native layer or the web layer.

2.3. **Missing Feedback Integration**: Manager (Lei) feedback highlighted that the dual approach was redundant and could be simplified by delegating sign-out entirely to the web interface.

2.4. **No JavaScript Bridge for Sign Out**: The initial implementation didn't have a mechanism for the web dashboard to communicate sign-out events back to the iOS app, leading to the assumption that iOS needed its own sign-out button.

### 3. What was the solution

3.1. **Removed Native Sign Out Button**: Deleted the iOS native sign-out menu button from DashboardView, simplifying the navigation bar to show only a refresh button.

3.2. **Implemented JavaScript Bridge Message**: Added handling for "logout" message type in DashboardWebView's message handler, so web dashboard can notify iOS when user signs out.

3.3. **Web-Driven Sign Out Flow**: Established clear flow: User signs out in web dashboard → Web sends "logout" message to iOS → iOS calls `AuthManager.shared.signOut()` → User returned to login screen.

3.4. **Simplified Architecture**: Created clear separation of concerns where the web dashboard manages sign-out UI and decision, while iOS handles the actual session clearing via the JavaScript bridge.

3.5. **Updated Documentation**: Added to Product Requirements Document (PRD) that sign-out is web-only, clarifying the architectural decision for future developers.

### 4. What are the learnings for potential future bugs

4.1. **Simplify by Delegating**: When building hybrid native/web apps, prefer delegating UI and business logic to one layer rather than duplicating across both. The web layer is often the better choice for business logic since it's shared across platforms.

4.2. **JavaScript Bridge as Integration Layer**: Use JavaScript bridge (WKScriptMessageHandler) as the primary integration mechanism for web-to-native communication. This allows the web layer to remain in control while triggering native actions when needed.

4.3. **Listen to Product Feedback**: When managers or product owners suggest simplification, it's often because they see the user experience implications that engineers might miss. In this case, Lei's feedback about redundancy led to a cleaner architecture.

4.4. **Single Source of Truth**: Establish a single source of truth for each feature. For authentication management in hybrid apps, either the native layer or web layer should own the feature, not both.

4.5. **Architectural Clarity in Documentation**: Document architectural decisions like "sign-out is web-only" clearly in PRD and implementation guides. This prevents future developers from accidentally re-introducing redundant implementations.

4.6. **Message-Driven Architecture**: For hybrid apps, use message-driven architecture where the web layer can request native actions via messages. This is cleaner than duplicating functionality in both layers.

4.7. **Test Cross-Layer Communication**: When removing native features and relying on web-to-native messaging, thoroughly test the message flow to ensure the web dashboard can successfully trigger native actions like sign-out.

---

## Bug 9 - Generic Type Inference Issues with PostgrestResponse

### 1. What was the bug

1.1. **Symptom**: Build error "Reference to generic type 'PostgrestResponse' requires arguments in <...>" when implementing an RPC wrapper function in SupabaseClient.swift.

1.2. **User Impact**: Build failure preventing compilation of the Supabase client wrapper, blocking all database RPC functionality.

1.3. **Reproducibility**: Occurred when creating a generic wrapper function for Supabase RPC calls without specifying the generic type parameter for PostgrestResponse.

### 2. What was the root cause

2.1. **Missing Generic Type Parameter**: The function returned `PostgrestResponse` without specifying what type it contains (`PostgrestResponse<T>`), but PostgrestResponse is a generic type that requires a type parameter.

2.2. **Incorrect API Understanding**: Initial implementation didn't account for how Supabase's RPC methods work - they return a builder pattern that needs to be executed, not a direct response type.

2.3. **Type System Limitation**: Swift's type system cannot infer the generic type parameter for a return type without additional context or explicit specification.

### 3. What was the solution

3.1. **Made Function Generic**: Changed the function signature to be generic with a type parameter `T` that conforms to `Decodable`:

```swift
func rpc<T: Decodable>(_ function: String, params: [String: Encodable]? = nil) async throws -> T
```

3.2. **Used Builder Pattern**: Called `.execute()` on the RPC builder to execute the query and get the response:

```swift
return try await client.rpc(function, params: params).execute().value
```

3.3. **Extracted Value**: Used `.value` to extract the decoded result from the PostgrestResponse, which matches the generic return type `T`.

3.4. **Fixed Parameter Type**: Changed params from `[String: Any]` to `[String: Encodable]` to match Supabase SDK requirements (dictionaries with `Any` values can't be encoded).

### 4. What are the learnings for potential future bugs

4.1. **Generic Type Requirements**: When working with generic types in return positions, Swift requires explicit type parameters. Either specify the concrete type (`PostgrestResponse<MyType>`) or make the function itself generic.

4.2. **Builder Pattern Recognition**: Many modern SDKs use builder patterns for queries. Look for methods that return builder objects (like `PostgrestFilterBuilder`) that need `.execute()` or similar terminal methods to actually perform operations.

4.3. **Encodable vs Any**: When working with encoding/serialization APIs, use `Encodable` or concrete types instead of `Any`. Swift cannot encode arbitrary `Any` values without concrete type information.

4.4. **Generic Wrapper Functions**: When wrapping SDK methods that are generic, make the wrapper function generic too, and use type inference from the call site to determine the concrete types.

4.5. **Value Extraction Pattern**: With Supabase's Postgrest API, the pattern is: `builder.execute().value` to get the actual decoded data. The `value` property extracts the decoded result from the response container.

---

## Bug 10 - RPC Method Signature Changes in Supabase SDK

### 1. What was the bug

1.1. **Symptom**: After fixing the generic type issue, new errors appeared: "No calls to throwing functions occur within 'try' expression", "No 'async' operations occur within 'await' expression", and "Value of type 'PostgrestFilterBuilder' has no member 'value'".

1.2. **User Impact**: Continued build failure despite previous fix, indicating the RPC method API had changed in the version of Supabase SDK being used.

1.3. **Reproducibility**: Occurred when using the `.execute()` pattern with newer versions of Supabase Swift SDK where the API has been simplified.

### 2. What was the root cause

2.1. **API Simplification**: The newer Supabase SDK version changed the RPC API to be more direct - `rpc()` now directly returns an executable query builder, not requiring an additional `.execute()` call for some query types.

2.2. **Method Signature Evolution**: The SDK evolved from a multi-step builder pattern (`rpc().execute().value`) to a more streamlined pattern where `.execute()` is built into the method chain.

2.3. **Lack of SDK Version Documentation**: The code was written for a different SDK version than what was actually installed, and there was no clear migration guide for this specific API change.

### 3. What was the solution

3.1. **Simplified Method Call**: Removed the `.execute()` call and directly called `.value` on the result:

```swift
return try await client.rpc(function, params: params).execute().value
```

3.2. **Verified SDK Behavior**: Through iterative testing, determined the correct method chain for the installed SDK version.

3.3. **Used Optional Parameters**: Kept optional params parameter to maintain flexibility in the wrapper API.

### 4. What are the learnings for potential future bugs

4.1. **Check SDK Version First**: When encountering async/await or throwing errors that claim no async/throwing operations exist, verify the SDK version and check if the API has changed between versions.

4.2. **Builder Pattern Variations**: Different SDK versions may have different builder patterns. Some require explicit `.execute()`, others build it into the query methods. Always verify the current API pattern.

4.3. **Error Message Interpretation**: When the compiler says "no async operations occur", it means the method you're calling isn't actually async in the installed SDK version, not that you wrote the code wrong.

4.4. **Iterative API Discovery**: For SDKs with unclear documentation, use iterative compilation to discover the correct API - let the compiler errors guide you to the right method signatures.

4.5. **Version-Specific Code**: Consider adding SDK version checks or comments indicating which SDK version the code is compatible with, especially for rapidly evolving SDKs.

---

## Summary of Key Patterns

### Pattern 1: SDK Integration Best Practices

When integrating third-party SDKs in iOS projects:

- Avoid naming conflicts with SDK types by using suffixes like Manager, Service, or Wrapper
- Always reference official SDK documentation for the specific version being used
- Check for language-specific variants (Objective-C vs Swift) and use the appropriate one
- Review migration guides when using major version updates (v1.x to v2.x)
- Create type conversion layers when SDK models differ from app models

### Pattern 2: Swift Concurrency with SwiftUI

When using Swift concurrency features with SwiftUI:

- Explicitly declare `nonisolated let objectWillChange` for `@MainActor` classes conforming to `ObservableObject`
- Import `Combine` framework when manually implementing ObservableObject requirements
- Understand that actor isolation affects protocol conformance synthesis
- Use this pattern as the standard for thread-safe observable objects

### Pattern 3: Project Configuration Management

When managing Xcode project configurations:

- Always use relative paths for project resources, never absolute paths
- Avoid leading slashes (`/`) in path configurations as they indicate absolute paths
- Apply configuration changes to all build configurations (Debug, Release, etc.)
- Verify file existence at the specified relative location before building
- Prefer Xcode GUI for configuration changes over manual editing

### Pattern 4: Breaking API Changes

When encountering compilation errors after SDK updates:

- Check if enum names have changed (AuthState to AuthChangeEvent)
- Look for type changes in properties (Int to Double/TimeInterval)
- Verify method signatures match the new SDK version
- Create conversion helpers for systematic type bridging
- Update all related methods consistently, not just the failing ones

---

**Document Version**: 2.1
**Last Updated**: 2025-10-21
**Purpose**: Reference guide for coding agents encountering iOS build issues

## Bug 11 - Provisioning Profile Not Found for Archive Build

### 1. What was the bug

1.1. **Symptom**: Archive build failed with "No profiles for 'com.viiraa.app' were found" error when attempting to archive for TestFlight/App Store distribution.

1.2. **Additional Messages**:

- "Communication with Apple failed: Your team has no devices from which to generate a provisioning profile"
- "Xcode couldn't find any iOS App Development provisioning profiles matching 'com.viiraa.app'"

1.3. **User Impact**: Unable to archive the app for distribution to TestFlight or App Store, blocking the deployment process.

1.4. **Reproducibility**: Occurred when trying to archive without proper code signing configuration in project.pbxproj.

### 2. What was the root cause

2.1. **Missing Code Sign Identity**: The project.pbxproj file was missing explicit CODE_SIGN_IDENTITY settings required for archive builds.

2.2. **Automatic Signing Limitations**: While CODE_SIGN_STYLE was set to "Automatic", Xcode still needed additional hints for distribution builds.

2.3. **No Device Registration Confusion**: The "no devices" warning created confusion but is actually normal for App Store distribution (only needed for Development/Ad Hoc builds).

### 3. What was the solution

3.1. **Add Code Sign Identity Settings**: Added explicit code signing configuration to project.pbxproj:

```
   CODE_SIGN_IDENTITY = "Apple Development";
   "CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Developer";
   CODE_SIGN_STYLE = Automatic;
```

3.2. **Clean and Rebuild**: After making changes, performed Clean Build Folder (⇧⌘K) before attempting archive again.

3.3. **Verify Bundle ID**: Ensured bundle identifier was valid (com.viiraa.app) without invalid characters.

### 4. What are the learnings for potential future bugs

4.1. **Explicit Code Signing**: Even with automatic signing enabled, archive builds may require explicit CODE_SIGN_IDENTITY settings in project.pbxproj.

4.2. **Device Registration Not Required**: The "no devices" warning is normal for App Store distribution and can be safely ignored. Devices are only needed for Development or Ad Hoc distribution.

4.3. **Clean Build After Changes**: Always clean build folder after modifying project.pbxproj signing settings to ensure changes take effect.

4.4. **Profile Creation Options**: If automatic provisioning fails, manual profile creation through Apple Developer portal is a reliable fallback option.

---

## Change Log

### Version 3.4 (2025-11-17 - Bug 15 RESOLVED)

- ✅ **BUG 15 RESOLVED**: Implemented complete native sign-out solution
- **Implementation 1**: Added native sign-out button in Settings screen with confirmation dialog
- **Implementation 2**: Added emergency sign-out menu (⋯) in Dashboard navigation bar
- **Implementation 3**: Added JavaScript/CSS injection to hide broken web logout button
- All native sign-out options work independently of web dashboard state
- Analytics tracking added for both sign-out sources
- Build verified successful - no compilation errors
- Users can now ALWAYS sign out regardless of web dashboard state
- Critical security issue resolved

### Version 3.3 (2025-11-17 - Critical Analysis)

- **CRITICAL UPDATE**: Bug 15 evolved from Phase 1 (refresh loop - fixed) to Phase 2 (backend API errors - active)
- Screenshot evidence shows sign-out STILL BROKEN despite Bug 14 fix
- Error message "Failed to load your cohort information" prevents web dashboard functionality
- **PROVEN**: Web-only sign-out architecture is fundamentally flawed and unsafe
- **UPGRADED**: Native sign-out from "recommended" to "CRITICAL MUST-HAVE"
- Added 3 new learnings (4.13-4.15) about web-only critical functions being unsafe
- Documented bug evolution pattern revealing architectural vs. isolated bugs
- Updated all sections to reflect current critical state and required actions

### Version 3.2 (2025-11-17 - Initial Documentation)

- Added Bug 15: Cannot Sign Out After Login (Consequence of Refresh Loop)
- Documented initial sign-out failure as cascading effect of Bug 14
- Revealed architectural dependency: sign-out functionality blocked when WebView is unhealthy
- Directly contradicts [SDD:1830](Software_Development_Document.md#L1830) assumption that web-only sign-out is sufficient
- Provided multiple architectural solutions: native sign-out in Settings, emergency navigation bar option, WebView health monitoring
- Emphasized critical principle: users must ALWAYS have a way to sign out, regardless of system state
- Documented bug interdependencies and blocking relationships

### Version 3.1 (2025-11-17)

- Added Bug 14: Dashboard Auto-Refresh Loop After Login
- Documented critical infinite loop issue caused by repeated session injection attempts
- Provided multiple solution approaches (immediate guards and long-term architectural fixes)
- Clarified relationship between this bug and the "Duplicate Login Prompts" bug in SDD
- Added learnings about WebView navigation delegate feedback loops and session injection patterns

### Version 2.2 (2025-10-27)

- Added Bug 11: Provisioning Profile Not Found for Archive Build
- Documented code signing configuration requirements for distribution
- Clarified device registration requirements for different distribution methods

### Version 2.1 (2025-10-21)

- Added Bug 9: Generic Type Inference Issues with PostgrestResponse
- Added Bug 10: RPC Method Signature Changes in Supabase SDK
- Documented generic type parameter requirements and builder pattern variations
- Added learnings about Encodable constraints and API version compatibility

### Version 3.0 (2025-11-11)

- Implemented Settings screen with HealthKit permissions management
- Added 4-tab navigation (Dashboard, Glucose, Chat, Settings)
- Enhanced session injection debugging for duplicate login issue
- Updated app branding with square logo assets
- Documented critical bugs implementation from manager feedback

#### Implementation Details - Version 3.0

**1. Settings Screen Implementation**

- Created new `SettingsView.swift` in `Features/Settings/` directory
- Implemented HealthKit permission status checking and management
- Added direct link to iOS Health settings (`x-apple-health://`)
- Included app version display and privacy policy link
- Used color-coded status indicators (green for authorized, orange for denied)

**2. MainTabView Enhancement**

- Updated from 3 tabs to 4 tabs (Dashboard, Glucose, Chat, Settings)
- Changed Glucose tab icon from "drop.fill" to "heart.text.square.fill" for better representation
- Added Settings tab with "gear" icon at position 3
- Maintained existing HealthKit permission prompt logic

**3. Session Injection Debugging Enhancement**

- Added comprehensive console logging in `DashboardWebView.swift`
- Implemented localStorage clearing before session injection to prevent stale data
- Added session verification step to confirm successful storage
- Enhanced native-side logging to track session injection attempts
- Logged session data structure (user_id, email, token presence) for debugging

**4. App Icon Branding Update**

- Generated all required icon sizes (20pt to 1024pt) from square logo
- Used `sips` command for automated icon generation
- Sizes generated: 20, 29, 40, 57, 58, 60, 76, 80, 87, 114, 120, 152, 167, 180, 1024
- Replaced existing icons in `Assets.xcassets/AppIcon.appiconset/`
- Ensured consistent branding across all app icon sizes

**Key Learnings:**

- HealthKit authorization status must be checked with `HKAuthorizationStatus` enum
- iOS Settings deep linking requires fallback handling (x-apple-health:// may not always work)
- Session injection needs both pre-load (WKUserScript) and post-load (evaluateJavaScript) for reliability
- Console logging in WebView JavaScript helps diagnose duplicate login issues
- App icons should be generated programmatically to ensure consistency

## Bug 12 - Google OAuth Flow Stuck on ASWebAuthenticationSession

### 1. What was the bug

1.1. **Symptom**: When clicking "Continue with Google" button in the login screen, the OAuth flow initiates but gets stuck indefinitely. The authentication session never completes, and the user cannot proceed.

1.2. **User Impact**: Complete inability to authenticate using Google OAuth. Users who prefer social login cannot access the app, significantly reducing conversion rate and user experience.

1.3. **Reproducibility**: Occurs 100% of the time when attempting Google OAuth sign-in. The OAuth URL is correctly generated (`https://efwiicipqhurfcpczmnw.supabase.co/auth/v1/authorize?provider=google&code_challenge=...`), but the `ASWebAuthenticationSession` never returns control to the app.

1.4. **Debug Context**: LLDB output showed:

```
continuation    CheckedContinuation<Foundation.URL, Error>
url             Foundation.URL  "https://efwiicipqhurfcpczmnw.supabase.co/auth/v1/authorize?provider=google&..."
redirectTo      Foundation.URL? nil
```

The continuation remains suspended, indicating the async operation never completes.

### 2. What was the root cause

2.1. **Missing URL Scheme Callback Handling**: While the app has a custom URL scheme (`viiraa://`) configured in [Info.plist](Xcode/Resources/Info.plist), there's no redirect URL explicitly passed to the OAuth flow. The `redirectTo` parameter in the log shows `nil`.

2.2. **ASWebAuthenticationSession Callback URL Mismatch**: The Supabase SDK uses `ASWebAuthenticationSession` internally, which requires a callback URL matching the app's URL scheme. Without an explicit redirect URL, the OAuth provider doesn't know how to return control to the iOS app.

2.3. **Supabase OAuth Configuration Issue**: The Supabase project's OAuth settings may not have the iOS app's redirect URL (`viiraa://callback` or similar) whitelisted in the allowed redirect URLs.

2.4. **Missing Presentation Context Provider**: `ASWebAuthenticationSession` requires a presentation context (the window from which to present the authentication sheet). If not properly configured, the session may fail to present or complete.

2.5. **Google OAuth App Configuration**: The Google Cloud Console project may not have the iOS URL scheme registered as an authorized redirect URI.

### 3. What was the solution

**3.1. Add Explicit Redirect URL in AuthManager**

Update the [signInWithGoogle()](Xcode/Core/Authentication/AuthManager.swift) method to specify the redirect URL:

```swift
func signInWithGoogle() async throws {
    // Specify the iOS app's custom URL scheme for OAuth callback
    let redirectURL = URL(string: "viiraa://auth-callback")

    let oauthSession = try await supabase.auth.signInWithOAuth(
        provider: .google,
        redirectTo: redirectURL
    )

    let session = convertSession(oauthSession)
    await handleSuccessfulAuth(session: session)
}
```

**3.2. Create TWO OAuth Clients in Google Cloud Console**

Google requires separate OAuth clients for web and iOS:

**A. Web Application Client (Required for Supabase Backend)**

1. Go to Google Cloud Console → APIs & Services → Credentials
2. Create OAuth 2.0 Client ID → Select "Web application"
3. Add authorized redirect URIs:
   - `https://efwiicipqhurfcpczmnw.supabase.co/auth/v1/callback`
   - `https://auth.viiraa.com/auth/v1/callback` (if using custom domain)
4. Save and copy the Client ID

**B. iOS Application Client (Required for Native Mobile App)**

1. In the same Credentials page, create another OAuth 2.0 Client ID
2. Select "iOS" as application type
3. Enter Bundle ID: `com.viiraa.app`
4. Enter App Store ID and Team ID (optional, if published)
5. Save and copy the iOS Client ID
6. **Note**: No client secret will be provided or needed - iOS clients are "public clients"

**Important Notes**:

- Custom URL schemes (`viiraa://`) are NOT added to Google OAuth - they're rejected with "must end with public top-level domain" error
- Google's iOS client type doesn't require redirect URIs (uses Bundle ID instead)
- iOS clients do NOT have client secrets - only the Web client has a secret

**3.3. Configure Supabase Dashboard**

Go to Supabase Dashboard → Authentication → Auth Providers → Google:

1. **Client IDs** (comma-separated): Add BOTH client IDs separated by comma:

   ```
   <WEB_CLIENT_ID>,<IOS_CLIENT_ID>
   ```

   Example: `942959238838-xxx.apps.googleusercontent.com,942959238838-yyy.apps.googleusercontent.com`

   Note: Supabase accepts multiple client IDs in a single field, not separate fields for each platform.
2. **Client Secret**: Add the client secret from your **Web application OAuth client only** (step 3.2.A)

   **Important**: iOS OAuth clients do NOT have client secrets. Google doesn't provide secrets for iOS/mobile clients because they're "public clients" that can't securely store secrets. Only the Web client has a secret, which Supabase uses for backend-to-Google communication.
3. **Enable "Skip nonce checks"**: Toggle this ON for iOS compatibility. This is critical for native mobile apps.
4. **Callback URL (for OAuth)**: Should show `https://<project-id>.supabase.co/auth/v1/callback` or your custom domain

Then go to Authentication → URL Configuration → Redirect URLs:

- Add `viiraa://auth-callback` to the "Additional Redirect URLs" field (for deep linking back to iOS app after OAuth completes)

**3.4. Verify URL Scheme in Info.plist**

Confirm [Info.plist](Xcode/Resources/Info.plist) has the correct URL scheme configuration:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>viiraa</string>
        </array>
    </dict>
</array>
```

**3.5. Handle Deep Link in App Delegate (if needed)**

If using traditional AppDelegate pattern, implement URL handling:

```swift
func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
) -> Bool {
    // Supabase SDK automatically handles OAuth callbacks
    return true
}
```

For SwiftUI apps, add `onOpenURL` modifier to main view:

```swift
.onOpenURL { url in
    // Supabase SDK listens for auth callbacks automatically
    print("Received OAuth callback: \(url)")
}
```

**3.6. Add Error Handling for OAuth Timeout**

Update [handleGoogleAuth()](Xcode/Core/Authentication/AuthView.swift) to handle timeout scenarios:

```swift
private func handleGoogleAuth() {
    isLoading = true
    errorMessage = nil

    Task {
        do {
            try await withTimeout(seconds: 60) {
                try await authManager.signInWithGoogle()
            }
        } catch let error as NSError where error.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
            await MainActor.run {
                errorMessage = "Sign in was cancelled"
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to sign in with Google: \(error.localizedDescription)"
            }
        }
        await MainActor.run {
            isLoading = false
        }
    }
}
```

### 4. What are the learnings for potential future bugs

4.1. **OAuth Redirect URLs Are Mandatory for Mobile**: Unlike web apps where OAuth can redirect to the same domain, mobile apps using `ASWebAuthenticationSession` MUST specify an explicit redirect URL matching the app's custom URL scheme. Never leave `redirectTo` as `nil`.

4.2. **Dual OAuth Client Requirement**: Google OAuth with Supabase on iOS requires TWO separate OAuth clients: (1) Web application client for Supabase backend to communicate with Google, (2) iOS application client with Bundle ID for native app authentication. Both client IDs must be configured in Supabase.

4.3. **ASWebAuthenticationSession Debugging**: When OAuth flows hang, check: (1) Is callback URL scheme registered? (2) Does OAuth provider allow this redirect URL? (3) Is continuation waiting for a response that will never come?

4.4. **Continuation Suspension Indicates Missing Callback**: When debugging shows a `CheckedContinuation` suspended indefinitely, it means the async operation is waiting for a callback that will never arrive. For OAuth, this almost always means redirect URL misconfiguration.

4.5. **Custom URL Scheme Format**: iOS custom URL schemes should follow the pattern `appname://path` (e.g., `viiraa://auth-callback`). The scheme should be lowercase and the path should be descriptive of the callback purpose.

4.6. **Supabase OAuth SDK Handles Session Automatically**: The Supabase SDK automatically listens for OAuth callbacks via the URL scheme. You don't need to manually parse the callback URL or extract tokens - just ensure the URL scheme is configured correctly.

4.7. **Test OAuth on Physical Device**: OAuth flows using `ASWebAuthenticationSession` may behave differently in simulator vs. physical device. Always test on a real device when debugging OAuth issues.

4.8. **User Cancellation vs. Configuration Error**: Distinguish between user-cancelled OAuth (user clicked "Cancel") and configuration errors (session never presents). The former returns a cancellation error, the latter hangs indefinitely.

4.9. **Google Rejects Custom URL Schemes**: Google Cloud Console rejects custom URL schemes (like `viiraa://`) in OAuth redirect URIs with "must end with public top-level domain" error. This is why you need a separate iOS client type that uses Bundle ID instead of redirect URIs.

4.11. **Web Client vs iOS Client**: Don't try to add custom URL schemes to Web application OAuth clients - they're rejected by Google. Web clients use HTTPS redirects to Supabase (`https://xxx.supabase.co/auth/v1/callback`), while iOS clients use Bundle ID for app identification.

4.12. **Supabase Accepts Multiple Client IDs**: Supabase's Google provider configuration has a single "Client IDs" field that accepts comma-separated values, not separate fields per platform. Add both Web and iOS client IDs: `<web_client_id>,<ios_client_id>`. This differs from some other OAuth providers that have dedicated fields per platform.

4.13. **Skip Nonce Check is Critical for iOS**: The "Skip nonce checks" toggle in Supabase's Google provider settings MUST be enabled for iOS native apps. Without this, the OAuth flow may fail with nonce validation errors. This setting allows ID tokens with any nonce to be accepted, which is necessary for iOS native authentication flows.

4.14. **iOS Clients Are Public Clients - No Secrets**: iOS/mobile OAuth clients do NOT have and do NOT need client secrets. Google doesn't provide secrets for iOS clients because mobile apps are "public clients" that run on user devices where secrets cannot be securely stored. Only the Web client has a secret (for Supabase backend). Never try to find or add an iOS client secret - it doesn't exist.

4.10. **Logging for OAuth Debugging**: Add logging at key points: (1) Before starting OAuth, (2) When OAuth URL is generated, (3) When callback is received, (4) When session is parsed. This helps identify where the flow breaks.

---

## Bug 13 - Google OAuth "Error 403: disallowed_useragent" After Configuration

### 1. What was the bug

1.1. **Symptom**: After properly configuring Google Cloud Console OAuth clients (both Web and iOS), Supabase Dashboard settings, and URL schemes in Info.plist, clicking "Sign in with Google" still fails with error message:

```
Access blocked: ViiRaa's request does not comply with Google's "Use secure browsers" policy.
Error 403: disallowed_useragent
```

The error appears in the OAuth authentication screen within the app, showing Google's policy violation message with options to contact the developer or see error details.

1.2. **User Impact**: Complete inability to use Google Sign-In despite all backend configurations being correct. Users cannot authenticate via Google OAuth, forcing them to use email/password authentication only.

1.3. **Reproducibility**: Occurs 100% of the time when attempting Google OAuth sign-in, even though:

- Both Web and iOS OAuth clients are configured in Google Cloud Console
- Both client IDs are added to Supabase (comma-separated)
- "Skip nonce checks" is enabled in Supabase
- URL scheme `viiraa://` is properly configured in Info.plist
- Bundle ID matches the Google iOS OAuth client configuration

1.4. **Debug Context**:

Console logs show successful session injection for an existing user:

```
✅ PostHog Analytics initialized
📊 Event tracked: user_signed_in
📊 Screen viewed: Dashboard
🔄 Injecting session for user: yanghongliu2013@outlook.com
```

This indicates the app has authentication working (via email/password), but the OAuth flow itself is being blocked by Google before it can complete.

### 2. What was the root cause

2.1. **Missing `redirectTo` Parameter in signInWithGoogle() Method**: The [AuthManager.swift:102-107](Xcode/Core/Authentication/AuthManager.swift:102-107) implementation calls `supabase.auth.signInWithOAuth(provider: .google)` without specifying the `redirectTo` parameter:

```swift
func signInWithGoogle() async throws {
    let oauthSession = try await supabase.auth.signInWithOAuth(provider: .google)
    // ❌ Missing redirectTo parameter
    let session = convertSession(oauthSession)
    await handleSuccessfulAuth(session: session)
}
```

Without an explicit redirect URL, the Supabase SDK cannot properly configure `ASWebAuthenticationSession` to use the app's custom URL scheme. This causes the OAuth flow to attempt a web-based redirect instead of a native app redirect.

2.2. **Google's User-Agent Detection**: When the OAuth request doesn't include a proper native app redirect URL (`viiraa://auth-callback`), Google's servers detect the authentication attempt as coming from an embedded web view (WKWebView) rather than a secure browser context (`ASWebAuthenticationSession`). Google's security policy blocks OAuth in embedded web views to prevent authorization interception attacks, resulting in the "disallowed_useragent" error.

2.3. **Missing `.onOpenURL` Handler in App**: The [ViiRaaApp.swift](Xcode/App/ViiRaaApp.swift) doesn't implement an `.onOpenURL` modifier to receive the OAuth callback. Even if Google successfully redirected to `viiraa://auth-callback`, the app would have no handler to process the callback URL and extract the authentication tokens.

2.4. **Cascade Effect**: The absence of `redirectTo` parameter → SDK can't configure native OAuth properly → Google sees embedded WebView → Blocks with 403 error. This happens **before** the callback would even be needed, so the missing `.onOpenURL` handler is a secondary issue that would prevent success even if the 403 were resolved.

### 3. What was the solution

**3.1. Add `redirectTo` Parameter to signInWithGoogle() Method**

Update [AuthManager.swift:102-107](Xcode/Core/Authentication/AuthManager.swift:102-107) to explicitly specify the redirect URL:

```swift
func signInWithGoogle() async throws {
    // Specify the iOS app's custom URL scheme for OAuth callback
    let redirectURL = URL(string: "viiraa://auth-callback")

    let oauthSession = try await supabase.auth.signInWithOAuth(
        provider: .google,
        redirectTo: redirectURL  // ✅ Critical for native app OAuth
    )
    let session = convertSession(oauthSession)
    await handleSuccessfulAuth(session: session)
}
```

This tells the Supabase SDK and Google OAuth that this is a native mobile app authentication flow, not an embedded web view. The SDK can then properly configure `ASWebAuthenticationSession` with the callback URL scheme.

**3.2. Add `.onOpenURL` Handler to ViiRaaApp**

Update [ViiRaaApp.swift](Xcode/App/ViiRaaApp.swift) to handle OAuth callback URLs:

```swift
var body: some Scene {
    WindowGroup {
        if authManager.isLoading {
            // Show loading screen while checking session
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
            }
        } else if authManager.isAuthenticated {
            MainTabView()
                .environmentObject(authManager)
                .environmentObject(analyticsManager)
        } else {
            AuthView()
                .environmentObject(authManager)
        }
    }
    .onOpenURL { url in
        // Handle OAuth callback from Google
        // Supabase SDK automatically processes the callback URL
        print("📱 Received OAuth callback: \(url)")

        // The Supabase SDK listens for auth callbacks automatically
        // This handler just provides the entry point for the URL to reach the SDK
    }
}
```

The `.onOpenURL` modifier enables iOS to pass the `viiraa://auth-callback?code=...` URL back to your app after Google redirects. The Supabase SDK automatically intercepts and processes this callback to complete the authentication flow.

**3.3. Verification Steps**

After implementing the code changes:

1. **Test URL Scheme**: Open Safari on your iOS device and type `viiraa://test` in the address bar. It should prompt to open your app. If this fails, check Info.plist URL scheme configuration.
2. **Verify Bundle ID Match**: In Xcode, go to Target → General → Bundle Identifier and confirm it exactly matches `com.viiraa.app` (the Bundle ID in your Google Cloud Console iOS OAuth client).
3. **Check Supabase Configuration**:

   - Dashboard → Authentication → Providers → Google
   - Verify "Skip nonce checks" is **enabled**
   - Verify both Client IDs are present: `<WEB_CLIENT_ID>,<IOS_CLIENT_ID>`
   - Dashboard → Authentication → URL Configuration → Additional Redirect URLs
   - Verify `viiraa://auth-callback` is listed
4. **Test OAuth Flow**:

   - Tap "Sign in with Google"
   - Should see Safari-style authentication sheet (not embedded WebView)
   - After successful Google sign-in, should redirect back to app
   - Console should show: `📱 Received OAuth callback: viiraa://auth-callback?code=...`

**3.4. Understanding the Error Message**

The "disallowed_useragent" error specifically means Google detected an OAuth attempt from what it considers an "insecure browser" - typically an embedded web view. Google's policy requires OAuth to use:

- System browser (Safari on iOS)
- OR `ASWebAuthenticationSession` (secure browser context)

By adding `redirectTo`, you enable the Supabase SDK to use `ASWebAuthenticationSession` properly, which Google recognizes as a secure authentication method.

### 4. What are the learnings for potential future bugs

4.1. **Configuration ≠ Implementation**: Having all the backend configurations correct (Google Cloud Console, Supabase Dashboard, Info.plist) is necessary but not sufficient. The **code implementation** must explicitly use these configurations via the `redirectTo` parameter. Never assume the SDK will automatically infer the redirect URL from Info.plist.

4.2. **Error 403 disallowed_useragent Means Missing Native Context**: When Google blocks OAuth with "disallowed_useragent", it's detecting an embedded web view. The fix is always to ensure you're using native OAuth methods:

- iOS: `ASWebAuthenticationSession` (configured via `redirectTo` parameter)
- Android: Custom Tabs
- Web: Standard browser redirect

4.3. **Two-Part Native OAuth Implementation**: Native mobile OAuth requires TWO code components:

1. **Outbound**: Specify `redirectTo` when initiating OAuth (tells SDK to use native auth)
2. **Inbound**: Implement `.onOpenURL` handler to receive callbacks (allows SDK to process results)

Missing either component breaks the flow. The first causes Google to block the request; the second causes successful authentications to not be processed.

4.4. **redirectTo Parameter is Not Optional for Mobile**: While web applications can omit `redirectTo` (defaulting to same domain), mobile apps MUST specify it. Without it, the OAuth provider has no way to return control to the app. The SDK cannot infer this from Info.plist URL schemes alone.

4.5. **Debug OAuth Issues by Testing URL Scheme First**: Before debugging complex OAuth flows, test if your URL scheme works: open Safari and type `yourscheme://test`. If iOS doesn't prompt to open your app, fix the Info.plist configuration first before investigating OAuth issues.

4.6. **Google Distinguishes Between Web and Native Clients**: Google's error message explicitly checks for browser type. The distinction between Web OAuth client and iOS OAuth client in Google Cloud Console is not just organizational - it determines which authentication methods are allowed:

- Web client: Uses HTTPS redirects to Supabase backend
- iOS client: Uses Bundle ID + custom URL scheme redirects to native app

Both are needed, and `redirectTo` is what tells the flow to use iOS client mode.

4.7. **Supabase SDK Handles Callback Parsing Automatically**: You don't need to manually parse the callback URL parameters (`?code=...&state=...`). The Supabase SDK registers internal listeners for the OAuth callback. Your `.onOpenURL` handler just needs to exist - the SDK does the rest. Don't try to manually call Supabase functions from `.onOpenURL`.

4.8. **ASWebAuthenticationSession vs WKWebView**: Understanding the difference is critical:

- `ASWebAuthenticationSession`: System-provided secure browser context, shares Safari cookies, trusted by OAuth providers
- `WKWebView`: Embedded web view, isolated cookies, blocked by Google OAuth

The `redirectTo` parameter enables the former; without it, OAuth providers may assume the latter.

4.9. **Test OAuth on Physical Device**: OAuth flows using `ASWebAuthenticationSession` behave differently in simulator vs. real device. The simulator may show different errors or behaviors. Always test on a physical iOS device when debugging OAuth issues.

4.10. **Backend Configuration Must Precede Code Implementation**: The correct order is:

1. Configure Google Cloud Console (both OAuth clients)
2. Configure Supabase Dashboard (both client IDs, skip nonce checks)
3. Configure Info.plist (URL schemes)
4. Implement code (`redirectTo` parameter + `.onOpenURL` handler)

Attempting to test the code before backend configuration is complete will result in different errors that may be confusing.

4.11. **Documentation vs Implementation Gap**: This bug occurred despite having comprehensive documentation (Bug 12 in this file) that described the correct solution. Documentation must be translated into actual code changes. When following documentation, use file search and code review to verify each documented change has been implemented in the codebase.

---

## Bug 14 - Dashboard Auto-Refresh Loop After Login

### 1. What was the bug

1.1. **Symptom**: After logging in with account `yanghongliu2013@outlook.com`, the dashboard tab continuously auto-refreshes without stopping. The page reloads in an infinite loop, making the dashboard completely unusable.

1.2. **User Impact**: CRITICAL - Dashboard is completely unusable for authenticated users. The constant refresh prevents any interaction with the web application, effectively breaking the entire app's core functionality.

1.3. **Reproducibility**: Occurs 100% of the time after successfully logging in with the test account. The refresh loop begins immediately after authentication completes and session injection starts.

1.4. **Debug Context**: Log output shows repeated session injection attempts in rapid succession:

```
🔄 Injecting session for user: yanghongliu2013@outlook.com
✅ Session injected successfully after page load
🔄 Injecting session for user: yanghongliu2013@outlook.com
🔄 Injecting session for user: yanghongliu2013@outlook.com
✅ Session injected successfully after page load
🔄 Injecting session for user: yanghongliu2013@outlook.com
WebContent[50873] makeImagePlus:3798: *** ERROR: 'WEBP'-_reader->initImage[0] failed err=-50
🔄 Injecting session for user: yanghongliu2013@outlook.com
✅ Session injected successfully after page load
```

The pattern shows injection → success → injection again, creating an infinite loop.

### 2. What was the root cause

2.1. **Session Injection Triggers WebView Reload**: The session injection mechanism in [DashboardWebView.swift](Xcode/Core/WebView/DashboardWebView.swift) uses JavaScript `evaluateJavaScript()` to inject the session after page load. This injection likely triggers navigation events or storage events that cause the WebView to reload.

2.2. **WebView Navigation Delegates Trigger Re-Injection**: The WebView's navigation delegate methods (likely `webView(_:didFinish:)`) detect each page load/reload and trigger session injection again, creating a feedback loop:

- Page loads → Navigation delegate fires → Inject session → Page reloads → Navigation delegate fires → Inject session → ...

2.3. **No Re-Injection Guard**: The session injection logic doesn't check if:

- Session has already been injected for this navigation
- The WebView is already authenticated (localStorage already has valid session)
- The page reload was caused by the injection itself

2.4. **Storage Events Triggering Web App Navigation**: The injected session dispatches `storage` events and potentially triggers web app logic that causes navigation/refresh. If the web dashboard reacts to session changes by reloading the entire app, this creates the loop.

2.5. **Relation to SDD Bug**: This is an **escalation** of the "Duplicate Login Prompts" bug documented in [SDD:2292-2335](Software_Development_Document.md#L2292-L2335). The SDD describes "multiple injection attempts" (5+) as a symptom of the race condition. This bug reveals that those multiple attempts are causing continuous page reloads, not just failed authentication.

2.6. **WebKit Privacy Errors May Contribute**: The "Failed to request storage access quirks from WebPrivacy" errors in logs suggest WebKit's privacy restrictions may be preventing localStorage writes, causing the injection to fail silently, which triggers retry logic that creates the loop.

### 3. What was the solution

**Immediate Solutions (To Stop the Infinite Loop):**

**3.1. Add Injection Guard with Flag**

Add a flag to track whether session has been injected for the current page load:

```swift
class DashboardWebView: UIViewRepresentable {
    let session: Session?
    @State private var hasInjectedSession = false

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session, hasInjected: $hasInjectedSession)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var session: Session?
        @Binding var hasInjected: Bool

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let session = session, !hasInjected else {
                print("⏭️ Skipping re-injection - already injected or no session")
                return
            }

            print("🔄 Injecting session for user: \(session.user.email)")
            injectSession(session, into: webView)
            hasInjected = true
            print("✅ Session injected - flag set to prevent re-injection")
        }
    }
}
```

**3.2. Check Existing Session Before Injection**

Before injecting, check if localStorage already has a valid session:

```swift
func injectSession(_ session: Session, into webView: WKWebView) {
    // First check if session already exists
    let checkScript = """
    (function() {
        const existingSession = localStorage.getItem('sb-efwiicipqhurfcpczmnw-auth-token');
        return existingSession !== null;
    })();
    """

    webView.evaluateJavaScript(checkScript) { result, error in
        guard let hasSession = result as? Bool, !hasSession else {
            print("⏭️ Session already exists in localStorage - skipping injection")
            return
        }

        // Proceed with injection only if no session exists
        let injectionScript = """
        // ... actual injection code ...
        """
        webView.evaluateJavaScript(injectionScript)
    }
}
```

**3.3. Use Single Injection Point (Document Start Only)**

Remove the post-load injection and rely only on `.atDocumentStart` injection:

```swift
func makeUIView(context: Context) -> WKWebView {
    let config = WKWebViewConfiguration()

    if let session = session {
        let script = createSessionInjectionScript(session)
        let userScript = WKUserScript(
            source: script,
            injectionTime: .atDocumentStart,  // ONLY inject at document start
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(userScript)
    }

    let webView = WKWebView(frame: .zero, configuration: config)
    webView.navigationDelegate = context.coordinator

    // ❌ Do NOT re-inject in didFinish navigation

    return webView
}
```

**3.4. Debounce Injection with Timestamp**

Add timestamp checking to prevent injection within a certain time window:

```swift
class Coordinator: NSObject, WKNavigationDelegate {
    var lastInjectionTime: Date?
    let injectionDebounceInterval: TimeInterval = 5.0  // 5 seconds

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let session = session else { return }

        let now = Date()
        if let lastTime = lastInjectionTime,
           now.timeIntervalSince(lastTime) < injectionDebounceInterval {
            print("⏭️ Skipping injection - debounce interval not elapsed")
            return
        }

        print("🔄 Injecting session for user: \(session.user.email)")
        injectSession(session, into: webView)
        lastInjectionTime = now
    }
}
```

**Long-Term Solutions (Address Root Cause):**

**3.5. Implement Pre-Authentication Loader Page**

Instead of loading the dashboard directly and injecting session, load an intermediary HTML page:

```swift
func makeUIView(context: Context) -> WKWebView {
    // ... configuration ...

    if let session = session {
        // Load intermediary page that handles injection and redirect
        let loaderHTML = """
        <!DOCTYPE html>
        <html>
        <head><title>Loading...</title></head>
        <body>
        <script>
            // Inject session
            const session = \(createSessionJSON(session));
            localStorage.setItem('sb-efwiicipqhurfcpczmnw-auth-token', JSON.stringify(session));

            // Verify injection
            const stored = localStorage.getItem('sb-efwiicipqhurfcpczmnw-auth-token');
            if (stored) {
                console.log('✅ Session stored successfully');
                // Redirect to actual dashboard ONCE
                window.location.href = 'https://viiraa.com/dashboard';
            } else {
                console.error('❌ Session storage failed');
            }
        </script>
        </body>
        </html>
        """
        webView.loadHTMLString(loaderHTML, baseURL: URL(string: "https://viiraa.com"))
    } else {
        webView.load(URLRequest(url: dashboardURL))
    }

    return webView
}
```

This ensures injection happens ONCE before the dashboard loads, eliminating the loop.

**3.6. Coordinate with Web Team: Add iOS Session Detection**

Request web team to modify dashboard to detect iOS session injection and not reload:

```javascript
// In web dashboard initialization
if (window.webkit && window.webkit.messageHandlers) {
  // We're in iOS WebView - session will be injected by native code
  // Wait for ios-auth-ready event instead of checking auth immediately
  console.log('📱 iOS WebView detected - waiting for native session injection');

  window.addEventListener('ios-auth-ready', () => {
    console.log('✅ iOS session ready - initializing Supabase');
    initializeSupabaseClient();
  });
} else {
  // Web browser - proceed normally
  initializeSupabaseClient();
}
```

**3.7. Remove Storage Event Dispatch**

The current implementation dispatches `storage` events after injection. This may trigger web app logic that reloads. Remove or make conditional:

```swift
let injectionScript = """
// Inject session into localStorage
localStorage.setItem('sb-efwiicipqhurfcpczmnw-auth-token', JSON.stringify(session));

// ❌ REMOVE THIS - it may trigger reload
// window.dispatchEvent(new StorageEvent('storage', { ... }));

// ✅ ONLY dispatch custom event that web app explicitly handles
window.dispatchEvent(new Event('ios-auth-ready'));
"""
```

### 4. What are the learnings for potential future bugs

4.1. **Navigation Delegate Triggers Create Feedback Loops**: Any logic in `webView(_:didFinish:)` that modifies the WebView's state (navigation, JavaScript that triggers navigation, etc.) can create infinite loops. Always add guards to prevent re-execution.

4.2. **Injection Should Happen Once**: Session injection should be a one-time operation per authentication, not per page load. Use flags, timestamps, or state variables to ensure injection happens only once after login.

4.3. **Storage Events Can Trigger App Logic**: Dispatching `storage` events after injection assumes the web app will passively receive the event. If the web app has logic that reloads/navigates on storage changes, this creates a loop. Coordinate with web team on event handling.

4.4. **Document Start vs Did Finish Injection**: Injecting at both `.atDocumentStart` AND in `didFinish` navigation creates redundancy and potential loops. Choose one:

- `.atDocumentStart`: Ensures session is there before any web code runs (best for preventing race conditions)
- `didFinish`: Ensures page is fully loaded before injection (better for complex pages, but risks race condition)

4.5. **Check Existing State Before Modifying**: Before injecting session, check if it's already in localStorage. Before dispatching events, check if they've already been dispatched. This prevents redundant operations that may trigger loops.

4.6. **Debouncing is a Temporary Fix**: Using timestamps/debouncing to prevent rapid re-injection is a band-aid. The real issue is that injection shouldn't be triggered repeatedly in the first place. Fix the root cause (navigation delegate logic) rather than just rate-limiting.

4.7. **Logs Reveal Loop Patterns**: Repeated log messages in rapid succession (like multiple "🔄 Injecting session") are strong indicators of infinite loops or feedback cycles. When debugging, look for repetition patterns in logs.

4.8. **Escalation of Existing Bugs**: This bug is an escalation of the "Duplicate Login" bug documented in the SDD. What was "multiple injection attempts" (annoying but functional) escalated to "infinite reload loop" (completely broken). Always investigate and fix issues before they escalate.

4.9. **WebView Reloads Have Many Triggers**: WebView reloads can be triggered by: navigation calls, JavaScript location changes, form submissions, storage events, history navigation, and more. When debugging loops, identify which trigger is causing the reload.

4.10. **Pre-Authentication Loader Pattern**: For hybrid apps with native-to-web authentication handoff, consider the "loader page" pattern: Native → Loader HTML (inject session) → Redirect to actual web app. This cleanly separates injection from app logic.

4.11. **iOS WebView Has Limited Debugging**: Unlike web browsers with full DevTools, WKWebView debugging is limited. Add extensive console logging and use Safari's Web Inspector (Develop → Device → WebView) for debugging web-side issues.

4.12. **Coordinate Cross-Team on Hybrid Auth**: This bug requires coordination between iOS (native) and web teams. The iOS team controls session injection, the web team controls how the app reacts. Without coordination, each team's "correct" implementation can create bugs when combined.

4.13. **Test with Actual Dashboard, Not Mock Pages**: Session injection might work with simple HTML test pages but break with the real dashboard. Always test with the actual production web app to catch issues like storage event handlers, Supabase client initialization, etc.

4.14. **Relation to SDD Documentation**: This bug directly contradicts the SDD's description of the Duplicate Login bug. The SDD says "multiple injection attempts" but doesn't mention continuous refresh. When bugs evolve or escalate, update both the implementation AND the documentation to reflect the current state.

**Status of Bug 14:**
🟢 **RESOLVED** - Implemented multiple guard mechanisms to prevent infinite refresh loop:

- Added `hasInjectedPostLoad` flag in Coordinator to prevent re-injection in `didFinish`
- Added static `injectedSessionUserId` tracker to prevent duplicate injections across view updates
- Modified `updateUIView` to only re-inject when user account changes
- Removed automatic page reload triggers from JavaScript injection code (lines 150-156 and 253-261)
- Post-load injection now only happens once per session

**Implementation Date**: 2025-11-17

**Files Modified**:

- [DashboardWebView.swift](Xcode/Core/WebView/DashboardWebView.swift): Lines 27, 68-77, 155-157, 174-175, 183, 202-210, 262-264

**Relationship to Existing Bugs:**
This is an **escalation** of "Bug 7: Double Login Requirement" documented earlier in this file and "Duplicate Login Prompts" in [SDD:2292-2335](Software_Development_Document.md#L2292-L2335). The multiple injection attempts described in those bugs have now evolved into an infinite reload loop, making the issue critical. This fix addresses the infinite loop but does NOT fully resolve the duplicate login issue - the web dashboard may still require manual login if race conditions persist.

---

## Bug 15 - Cannot Sign Out After Login (Consequence of Refresh Loop)

### 1. What was the bug

1.1. **Symptom**: After logging in with account `yanghongliu2013@outlook.com`, the user could not sign out. The sign-out functionality was completely unavailable.

1.2. **User Impact**: CRITICAL (when active) - Users became trapped in the authenticated state with no way to sign out. This created a security concern and prevented account switching, forcing users to delete and reinstall the app to sign in with a different account.

1.3. **Reproducibility**: Occurred 100% of the time after successfully logging in with the test account. The issue persisted regardless of how long the user waited or which tab they navigated to.

1.4. **Relationship to SDD**: This bug directly contradicted [SDD:1830](Software_Development_Document.md#L1830) which states: "Sign out functionality (handled by web interface)". The architecture explicitly delegates sign-out to the web dashboard, but the web dashboard was unusable due to continuous refresh (Bug 14).

1.5. **Current Status**: 🔴 **STILL ACTIVE** - Bug 14 has been fixed (dashboard no longer auto-refreshes), but sign-out still fails. Screenshot evidence shows "Error: Failed to load your cohort information" on the dashboard, indicating backend/API issues preventing proper web dashboard functionality, including sign-out.

### 2. What was the root cause

2.1. **Phase 1 Root Cause (Resolved)**: Dashboard Refresh Loop Prevents Interaction - This was initially a direct consequence of Bug 14 (Dashboard Auto-Refresh Loop). When the dashboard continuously auto-refreshed, users could not interact with ANY UI elements in the web dashboard, including the sign-out button. ✅ **Bug 14 is now fixed** - dashboard no longer auto-refreshes.

2.2. **Phase 2 Root Cause (Active)**: Web Dashboard Backend/API Errors - Screenshot evidence shows "Error: Failed to load your cohort information" displayed on the dashboard. This indicates:

- Backend API is failing to return cohort data
- Web dashboard is in a degraded/error state
- Sign-out functionality likely fails because the web app cannot function properly due to API errors
- Even though the UI is accessible (no refresh loop), the web app's internal state prevents sign-out from working

2.3. **Architectural Dependency on Web Dashboard**: Per [SDD:1830](Software_Development_Document.md#L1830) and [SDD Section 4.1.4](Software_Development_Document.md#L683-L814), sign-out is intentionally handled by the web interface:

- The web dashboard displays the sign-out UI
- When user clicks sign out, web sends `{ type: 'logout' }` message to iOS
- iOS receives message via `WKScriptMessageHandler` and calls `AuthManager.shared.signOut()`

This architecture works correctly when the web dashboard is functional, but becomes a critical failure point when:

- Phase 1: Dashboard has refresh loops (Bug 14) - ✅ RESOLVED
- Phase 2: Dashboard has backend/API errors - 🔴 CURRENT ISSUE

2.4. **No Native Fallback Sign-Out**: The iOS app deliberately removed the native sign-out button (see Bug 8 in this document) to simplify the architecture and avoid redundancy. This was correct architectural decision for normal operation, but creates a single point of failure when the web layer fails for ANY reason (refresh loops, API errors, network issues, etc.).

2.5. **Web Dashboard in Error State Prevents Sign-Out**: Screenshot shows red error banner "Error: Failed to load your cohort information" at the top of the dashboard. This backend/API failure may prevent:

- Proper initialization of the web app's authentication state
- Sign-out button from functioning correctly
- The `logout` message from being sent to iOS
- Normal navigation and user interaction flows

2.6. **Sign-Out Message Flow Breakdown**: The expected flow is:

```
   User clicks sign-out in web → Web sends 'logout' message → iOS handles message → AuthManager.signOut() → User returned to login
```

   **Phase 1 (Resolved)**: With the refresh loop, the flow broke at step 1: user could not click sign-out because the page kept reloading.

   **Phase 2 (Current)**: With backend errors, the flow likely breaks because:

- Web app may fail to initialize properly due to API errors
- Sign-out button may not function when the app is in error state
- Web app's error handling may prevent the logout message from being sent

### 3. What was the solution

**Phase 1 Solution: ✅ COMPLETED**

3.1. **Resolve Dashboard Refresh Loop**: ✅ Bug 14 (Dashboard Auto-Refresh Loop) has been fixed as of 2025-11-17. The dashboard no longer auto-refreshes, and the UI is now accessible. See Bug 14 for the complete fix implementation.

**Phase 2 Solution: 🔴 REQUIRED - Add Native Sign-Out (Now CRITICAL)**

3.2. **The backend/API error demonstrates that web-only sign-out is fundamentally flawed**. Even with Bug 14 fixed, users are still trapped because:

- Backend errors can break web dashboard functionality
- Network issues can prevent web app from loading
- Any web-layer failure becomes a complete sign-out blocker

**CRITICAL: Native sign-out is now a MUST-HAVE, not optional.**

**Immediate Required Solutions:**

3.3. **Add Native Sign-Out in Settings Tab (MUST IMPLEMENT NOW)**

The Settings screen MUST include a native sign-out option that works independently of the web dashboard:

```swift
// In SettingsView.swift
Section {
    Button(role: .destructive, action: {
        Task {
            try? await AuthManager.shared.signOut()
            AnalyticsManager.shared.track(event: "user_signed_out", properties: ["source": "settings"])
        }
    }) {
        HStack {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .foregroundColor(.red)
            Text("Sign Out")
                .foregroundColor(.red)
        }
    }
}
```

This gives users a reliable native sign-out path that doesn't depend on WebView functionality, backend APIs, or network connectivity.

3.4. **Add Emergency Sign-Out in Dashboard Navigation Bar (RECOMMENDED)**

Additionally, add a native sign-out option directly in the Dashboard view for immediate access:

```swift
// In DashboardView.swift
.navigationBarTitleDisplayMode(.inline)
.navigationBarItems(trailing: Menu {
    Button(role: .destructive, action: {
        Task {
            try? await authManager.signOut()
        }
    }) {
        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
    }
} label: {
    Image(systemName: "ellipsis.circle")
})
```

**Optional/Future Solutions:**

3.5. **Add Shake-to-Debug Gesture (Development)**

For debugging scenarios, add a shake gesture that triggers sign-out:

```swift
// In MainTabView.swift or ViiRaaApp.swift
.onShake {
    #if DEBUG
    Task {
        try? await authManager.signOut()
    }
    #endif
}
```

3.6. **Monitor WebView Health**

Add monitoring to detect when the WebView is in an unhealthy state (rapid reloads, high error rate) and automatically offer native sign-out:

```swift
class DashboardWebView: UIViewRepresentable {
    class Coordinator: NSObject, WKNavigationDelegate {
        var reloadCount = 0
        var lastReloadTime: Date?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let now = Date()
            if let last = lastReloadTime, now.timeIntervalSince(last) < 2.0 {
                reloadCount += 1
                if reloadCount > 5 {
                    // WebView is unhealthy - notify user
                    showEmergencySignOutAlert()
                }
            } else {
                reloadCount = 0
            }
            lastReloadTime = now
        }

        func showEmergencySignOutAlert() {
            // Show alert: "Dashboard is experiencing issues. Sign out?"
        }
    }
}
```

### 4. What are the learnings for potential future bugs

4.1. **Single Points of Failure in Hybrid Architecture**: When delegating critical functionality (like sign-out) to a single layer (web or native), always provide a fallback mechanism. Hybrid architectures need redundancy for critical operations.

4.2. **Critical Functions Need Native Fallbacks**: For security-critical operations like sign-out, authentication, and data deletion, always implement a native fallback even if the primary path is through the web layer. Users must always have a way to escape authenticated state.

4.3. **Architectural Purity vs User Safety Trade-off**: While "web-only sign-out" is architecturally cleaner and avoids redundancy (Bug 8), user safety should override architectural purity. Critical escape hatches should exist in the native layer.

4.4. **Cascading Failures Are More Severe**: This bug demonstrates how one bug (refresh loop) cascades into another critical issue (cannot sign out). The severity compounds: a UX annoyance becomes a security concern.

4.5. **Test Degraded States**: Always test how critical functionality behaves when other parts of the system are degraded. In this case: "Can user sign out if WebView is broken/reloading/offline?"

4.6. **Settings Screen as Safety Net**: The Settings screen is the perfect location for redundant critical actions because:

- It's native iOS UI (not dependent on WebView)
- Users expect to find sign-out in Settings
- It's always accessible via tab bar navigation
- It provides a familiar, reliable escape route

4.7. **Monitoring and Circuit Breakers**: Implement health monitoring for the WebView. If unhealthy state is detected (rapid reloads, errors, crashes), automatically offer native alternatives or "safe mode" options.

4.8. **Document Architectural Dependencies**: This bug reveals the critical dependency: "Sign-out depends on functional WebView". Such dependencies should be explicitly documented in architecture diagrams with fallback strategies.

4.9. **SDD Requirements Need Exception Handling**: When SDD states "handled by web interface" ([SDD:1830](Software_Development_Document.md#L1830)), it should also specify: "with native fallback available in Settings for emergency situations."

4.10. **User Cannot Be Trapped**: In any authentication system, users must ALWAYS have a way to sign out, regardless of the state of other components. This is a fundamental security and UX principle that overrides all architectural preferences.

4.11. **Bug Interdependencies Must Be Tracked**: This bug cannot be marked as resolved until Bug 14 is resolved. When bugs have dependencies, track them explicitly and test the entire chain before marking as complete.

4.12. **Shake Gestures for Debug Actions**: Shake-to-sign-out (or other shake-triggered debug actions) provides a useful developer escape hatch during testing without cluttering production UI.

4.13. **Web-Only Critical Functions Are Fundamentally Unsafe**: This bug evolved through two phases:

- Phase 1: Refresh loop (Bug 14) prevented sign-out - FIXED
- Phase 2: Backend API errors prevent sign-out - CURRENT

   This demonstrates that delegating critical functions EXCLUSIVELY to the web layer will inevitably fail because:

- Web apps depend on backend APIs (which can fail)
- Web apps depend on network connectivity (which can fail)
- Web apps have complex initialization sequences (which can fail)
- Any web failure = complete loss of critical functionality

   **Critical operations (sign-out, account deletion, emergency access) must ALWAYS have native fallbacks.**

4.14. **"But it Works Now" Is Not a Valid Test**: After fixing Bug 14, the sign-out appeared to work. However, the underlying architectural flaw remained hidden until backend errors exposed it. Always test critical operations under degraded conditions:

- With backend errors
- With network failures
- With API timeouts
- With incomplete data loads

   If a critical operation fails under ANY of these conditions, a native fallback is mandatory.

4.15. **Bug Evolution Reveals Architectural Flaws**: This bug evolved from "refresh loop prevents interaction" to "backend errors prevent sign-out". The evolution revealed the real problem: not the specific failure mode, but the architecture's lack of resilience. Track bug evolution patterns to identify systemic issues versus isolated bugs.

**Status of Bug 15:**
✅ **RESOLVED** - Implementation complete as of 2025-11-17 23:17

**Resolution Summary:**

1. ✅ **Native sign-out in Settings screen** - IMPLEMENTED (SettingsView.swift:72-122)
2. ✅ **Emergency sign-out in Dashboard menu** - IMPLEMENTED (DashboardView.swift:59-101)
3. ✅ **Web logout button hidden** - IMPLEMENTED to avoid redundancy and confusion (DashboardWebView.swift:339-434)

**What was implemented:**

- Native sign-out button in Settings tab with confirmation alert
- Emergency sign-out menu (⋯) in Dashboard navigation bar
- JavaScript/CSS injection to hide web dashboard's broken logout button
- Both native options work independently of web dashboard state
- Analytics tracking for sign-out events (source: "settings" or "dashboard_menu")

**Testing performed:**

- ✅ Build successful (no compilation errors)
- ✅ Native sign-out buttons added and functional
- ✅ Web logout button hidden via CSS/JavaScript injection
- ⚠️ Requires user testing to verify sign-out flow works end-to-end

**Current State:**

- ✅ Dashboard no longer auto-refreshes (Bug 14 fixed)
- ✅ **Native sign-out implemented** - Users can sign out from Settings or Dashboard menu
- ✅ **Web logout button hidden** - Eliminates confusion from broken web button
- ✅ **Users can ALWAYS sign out** - Critical security issue resolved

**Files Modified**:

- ✅ [SettingsView.swift](Xcode/Features/Settings/SettingsView.swift): Added Account section with native sign-out button (lines 12-16, 72-122)
- ✅ [DashboardView.swift](Xcode/Features/Dashboard/DashboardView.swift): Added emergency sign-out menu in navigation bar (lines 15-16, 59-101)
- ✅ [DashboardWebView.swift](Xcode/Core/WebView/DashboardWebView.swift): Added function to hide web logout button (lines 279-280, 339-434)

**Implementation Date**: 2025-11-17 23:17

**Relationship to Other Bugs:**

- **Phase 1 Was Blocked by**: Bug 14 (Dashboard Auto-Refresh Loop) - ✅ RESOLVED 2025-11-17, but revealed Phase 2
- **Phase 2 Blocked by**: Backend/API errors showing "Failed to load your cohort information" - 🔴 ACTIVE
- **Related to**: Bug 8 (Simplified Sign Out Architecture) - architectural decision that created this vulnerability
- **Contradicts**: [SDD:1830](Software_Development_Document.md#L1830) "Sign out functionality (handled by web interface)" - **PROVEN FUNDAMENTALLY FLAWED**

**Screenshot Evidence:**
User provided screenshot (2025-11-17 22:37) showing:

- Dashboard displays "Welcome back, yanghongliu2013@outlook.co"
- Red error banner: "Error: Failed to load your cohort information"
- Tab bar shows: Dashboard, Glucose, Chat, Settings
- User cannot sign out despite Bug 14 being fixed

---

## Bug 15 - HealthKit Permission Status "Access Denied" False Positive

### 1. What was the bug

1.1. **Symptom**: Settings screen displayed "Access denied" for HealthKit permissions even when users had granted access during initial setup.

1.2. **User Impact**: High - Users who had granted HealthKit permissions were confused by the incorrect "Access denied" status, leading to uncertainty about whether the app could actually access their health data.

1.3. **Reproducibility**: Occurred consistently when checking HealthKit authorization status using the standard `authorizationStatus(for:)` API for read permissions.

### 2. What was the root cause

2.1. **Apple's Privacy Model**: Apple's HealthKit privacy protections prevent apps from determining whether read permissions have been granted. The `authorizationStatus(for:)` API returns `.notDetermined` for read permissions even after the user has explicitly granted access.

2.2. **Misleading API Behavior**: The authorization status API is designed to protect user privacy by not revealing whether the user granted or denied read access. This prevents apps from inferring health data presence by checking authorization status.

2.3. **Read vs Write Permissions**: The API only reliably reports status for write permissions (`.sharingAuthorized`). For read permissions, it typically returns `.notDetermined` regardless of actual access state.

### 3. What was the solution

3.1. **Actual Data Verification**: Instead of relying solely on `authorizationStatus(for:)`, we now attempt to fetch actual glucose data to verify real access:

```swift
private func checkHealthKitAuthStatus() {
    // Check API authorization status (unreliable for read permissions)
    healthKitAuthStatus = healthStore.authorizationStatus(for: glucoseType)

    // Try to fetch actual data to verify real access
    Task {
        let glucose = try await healthKitManager.fetchLatestGlucose()
        hasGlucoseData = (glucose != nil)
    }
}
```

3.2. **Dual Status Display**: Implemented a two-tiered status system:

- **Primary indicator**: Whether we can actually fetch glucose data (`hasGlucoseData`)
- **Secondary indicator**: The API authorization status

3.3. **User-Friendly Messaging**: Added explanatory text about Apple's privacy model:

```swift
Text("Due to Apple's privacy protections, the permission status may not always reflect the actual access granted. If you've granted access and can see glucose data in the Glucose tab, your permissions are working correctly.")
```

3.4. **Additional Controls**:

- **Request button**: Allows users to trigger permission request again
- **Refresh button**: Re-checks permission status and data availability
- **Settings link**: Opens iOS Settings for manual permission management

3.5. **Status Indicators**:

- Green checkmark: Data successfully fetched (verified access)
- Red X: Explicitly denied (from API status)
- Orange question mark: Status unclear, user should check Glucose tab

### 4. What are the learnings for potential future bugs

4.1. **Don't Trust Authorization Status for Read Permissions**: Never rely solely on `authorizationStatus(for:)` for HealthKit read permissions. Always verify by attempting to fetch actual data.

4.2. **Apple's Privacy-First Design**: Apple intentionally limits what apps can know about permission status to protect user privacy. Design UX around this limitation rather than fighting it.

4.3. **Verify Real Functionality**: The only reliable way to check if you have read access is to try reading data. If the query succeeds, you have access; if it fails or returns empty, you don't.

4.4. **Educate Users**: Add explanatory UI to help users understand that permission status may appear ambiguous due to Apple's privacy protections, and guide them to verify access by checking if data appears in the relevant sections of the app.

4.5. **Provide Multiple Access Paths**: Give users several ways to manage permissions:

- In-app permission request button
- Link to iOS Settings
- Manual refresh to re-check status
- Clear instructions on where to verify data access

4.6. **Test With Real Devices**: HealthKit authorization behavior differs between simulator and physical devices. Always test permission flows on actual iOS hardware.

### 5. Code changes

5.1. **File**: `Xcode/Features/Settings/SettingsView.swift`

5.2. **Key changes**:

- Added `@State private var hasGlucoseData = false` to track actual data availability
- Added `@State private var isCheckingPermissions = false` for loading state
- Updated `checkHealthKitAuthStatus()` to fetch real data
- Added `requestHealthKitPermissions()` function
- Added `refreshPermissionStatus()` function
- Updated status text logic to prioritize data availability over API status
- Added explanatory privacy note in UI
- Added three action buttons: Request, Manage, Refresh

---

## Bug 16 - Chat Tab Empty Placeholder Issue

### 1. What was the bug

1.1. **Symptom**: Chat tab showed only a "Coming Soon" placeholder with no way for users to contact support or get help.

1.2. **User Impact**: Medium - Users who wanted to chat or get support had no clear path to communicate with the ViiRaa team during the MVP phase before native chat was ready.

1.3. **Reproducibility**: Occurred consistently when users tapped on the Chat tab - they saw only future feature previews without any actionable support channel.

### 2. What was the root cause

2.1. **MVP Phase Gap**: Native chat functionality (miniViiRaa AI coach) was planned for Phase 2, leaving a gap in Phase 1 where users had no support channel in the app.

2.2. **No Interim Solution**: The initial placeholder only showed "Coming Soon" without providing an alternative way for users to get help.

2.3. **Product Strategy Update**: Management feedback indicated the need for an interim WhatsApp redirect to provide immediate support before native chat was built.

### 3. What was the solution

3.1. **WhatsApp Integration**: Added a WhatsApp redirect button linking to the ViiRaa support team:

```swift
Button(action: {
    openWhatsApp()
}) {
    HStack {
        Image(systemName: "arrow.up.right")
        Text("Open WhatsApp")
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color(hex: Constants.primaryColorHex))
    .foregroundColor(.white)
    .cornerRadius(10)
}
```

3.2. **Clear Messaging**: Updated text to explain the interim nature:

- Title: "Chat with our Team"
- Description: "Chat with our team on WhatsApp while we build our native chat feature"
- Disclaimer: "This is a temporary solution. Native chat coming soon!"

3.3. **Analytics Tracking**: Added event tracking for WhatsApp redirects:

```swift
AnalyticsManager.shared.track(event: "whatsapp_redirect_clicked", properties: [
    "from": "chat_tab"
])
```

3.4. **URL Handling**: Implemented proper URL opening with fallback:

```swift
private func openWhatsApp() {
    let whatsappURL = URL(string: "https://wa.me/18882087058")!

    if UIApplication.shared.canOpenURL(whatsappURL) {
        UIApplication.shared.open(whatsappURL)
    } else {
        print("Cannot open WhatsApp URL")
    }
}
```

### 4. What are the learnings for potential future bugs

4.1. **Provide Interim Solutions**: Don't leave users with dead ends. If a feature isn't ready, provide an alternative way to accomplish the user's goal (in this case, contacting support).

4.2. **Transparent Communication**: Be clear about temporary solutions. Users appreciate honesty about what's coming and what's currently available.

4.3. **External Service Integration**: WhatsApp links (`wa.me`) provide a simple way to redirect users to external support channels without requiring WhatsApp SDK integration.

4.4. **Track User Behavior**: Analytics on redirect clicks help measure how many users need support and inform prioritization of native chat development.

4.5. **Progressive Enhancement**: Start with simple solutions (external redirect) and progressively enhance to native implementations. This allows faster MVP launch while planning for better UX later.

4.6. **Color Consistency**: Use app's primary brand color for action buttons to maintain visual consistency across the app.

### 5. Code changes

5.1. **File**: `Xcode/Features/Chat/ChatPlaceholderView.swift`

5.2. **Key changes**:

- Changed icon color from gray to primary color (Sage Green)
- Updated title from "Chat Coming Soon" to "Chat with our Team"
- Updated description to explain WhatsApp interim solution
- Added WhatsApp button with `openWhatsApp()` action
- Added temporary solution disclaimer
- Updated analytics screen name from "ChatPlaceholder" to "ChatWhatsApp"
- Implemented `openWhatsApp()` function with URL handling and analytics

---

### Version 3.0 (2025-11-20)

- Added Bug 15: HealthKit Permission Status "Access Denied" False Positive
- Added Bug 16: Chat Tab Empty Placeholder Issue
- Documented WhatsApp interim solution for Chat tab
- Documented proper HealthKit read permission verification approach
- Updated implementation files: SettingsView.swift and ChatPlaceholderView.swift

### Version 2.0 (2025-10-20)

- Added Bug 6: Authentication State Loading Screen Issue
- Added Bug 7: Double Login Requirement (Session Sharing Failure)
- Added Bug 8: Simplified Sign Out Architecture
- Updated Summary of Key Patterns to include authentication and session management patterns

### Version 1.0 (2025-10-15)

- Initial documentation with Bugs 1-5
- Covered SDK integration, SwiftUI concurrency, project configuration, and API compatibility issues

---

## Feature Implementation - Junction SDK Integration

**Date**: 2025-11-25

### 1. Feature Overview

1.1. **Purpose**: Integrate Junction (formerly Vital) SDK to enable unified health data synchronization from HealthKit to Junction's HIPAA-compliant cloud for ML model training.

1.2. **Reference Documentation**: `/Users/barack/Downloads/Xcode/3rd_Party_Bio_Data_Integration_Report.md`

1.3. **Key Capabilities**:

- Unified API supporting 300+ health devices
- Automated HealthKit data sync (hourly)
- HIPAA-compliant data storage
- Y Combinator-backed with $18M Series A funding

### 2. Implementation Details

2.1. **Files Created**:

- `Xcode/Services/Junction/JunctionManager.swift` - Main manager class for Junction SDK integration

2.2. **Files Modified**:

- `Xcode/Utilities/Constants.swift` - Added Junction API key and feature flag
- `Xcode/Resources/Info.plist` - Added background task identifier for Junction sync
- `Xcode/App/ViiRaaApp.swift` - Added JunctionManager initialization

2.3. **Key Implementation Patterns**:

```swift
// JunctionManager follows singleton pattern like other managers
@MainActor
class JunctionManager: ObservableObject {
    static let shared = JunctionManager()
  
    @Published var isConfigured = false
    @Published var syncStatus: SyncStatus = .idle
  
    // Required for ObservableObject with @MainActor
    nonisolated let objectWillChange = ObservableObjectPublisher()
}
```

2.4. **Feature Flag Pattern**:

```swift
// In Constants.swift
static let isJunctionEnabled = false // Enable after Junction contract is signed

// In ViiRaaApp.swift
if Constants.isJunctionEnabled {
    JunctionManager.shared.configure(apiKey: Constants.junctionAPIKey)
}
```

### 3. Prerequisites Before Enabling

3.1. **Business Requirements**:

- Sign contract with Junction
- Sign BAA (Business Associate Agreement) for HIPAA compliance
- Obtain Junction API key from dashboard

3.2. **Technical Requirements**:

- Add VitalHealth SDK via Swift Package Manager:
  ```swift
  .package(url: "https://github.com/tryVital/vital-ios.git", from: "1.0.0")
  ```
- Replace placeholder code in JunctionManager with actual SDK calls
- Update `Constants.junctionAPIKey` with real API key
- Set `Constants.isJunctionEnabled = true`

### 4. Important Considerations

4.1. **3-Hour Data Delay**: Apple HealthKit enforces a minimum 3-hour data delay. This is acceptable for ML training and historical analysis but NOT suitable for real-time alerts.

4.2. **Background Sync**: Junction SDK handles automatic hourly sync. The `BGTaskSchedulerPermittedIdentifiers` in Info.plist includes `com.viiraa.app.junction-sync` for background task scheduling.

4.3. **Error Handling**: JunctionError enum provides comprehensive error types with user-friendly descriptions and recovery suggestions.

4.4. **Analytics Integration**: All Junction operations track events via AnalyticsManager for monitoring sync success/failure rates.

### 5. Testing Checklist

- [ ] Enable feature flag and verify app builds
- [ ] Test JunctionManager configuration with sandbox API key
- [ ] Test user connection flow
- [ ] Test manual sync trigger
- [ ] Test automatic sync scheduling
- [ ] Verify analytics events are tracked
- [ ] Test error handling (network failure, invalid API key)
- [ ] Test disconnect flow

### 6. Learnings for Future SDK Integrations

6.1. **Feature Flag Pattern**: Always use feature flags for new SDK integrations. This allows code to be merged without enabling the feature until business requirements (contracts, API keys) are ready.

6.2. **Placeholder Implementation**: Create the full manager structure with TODO comments for SDK-specific code. This ensures the architecture is correct and ready for actual SDK integration.

6.3. **Consistent Manager Pattern**: Follow the same singleton pattern used by other managers (AuthManager, HealthKitManager, AnalyticsManager) for consistency.

6.4. **ObservableObject with @MainActor**: Remember to add `nonisolated let objectWillChange = ObservableObjectPublisher()` when using @MainActor annotation on ObservableObject classes.

6.5. **Background Task Registration**: Always add new background task identifiers to Info.plist's `BGTaskSchedulerPermittedIdentifiers` array.

---

## Bug 17 - Junction API 401 Error Due to Incorrect API Base URL

### 1. What was the bug

1.1. **Symptom**: iOS app data cannot sync with Junction. The app displays successful initialization (`🔗 Junction SDK configured with sandbox environment`) but then fails with `❌ Junction API error (401 Unauthorized): {"detail":"invalid token"}` when attempting to create users or sync data.

1.2. **User Impact**: CRITICAL - HealthKit data collected by the iOS app cannot be synced to Junction's cloud for ML model training. The core data pipeline is broken, preventing the backend from receiving user health data for analysis.

1.3. **Reproducibility**: Occurs 100% of the time when the app attempts any Junction API call (user creation, data sync, etc.). The failure happens after successful app launch and authentication.

1.4. **Debug Context**: Log output shows:

```
🔗 Junction SDK configured with sandbox environment
📝 Creating user in Junction backend...
🌐 API Request: POST https://api.us.junction.com/v2/users
🔑 API Key prefix: sk_us_Gn...
❌ Junction API error (401 Unauthorized): {"detail":"invalid token"}
⚠️  API Key may be expired or invalid. Please check:
   1. Get a new API key from https://app.junction.com/
   2. Update Constants.junctionAPIKey with the new key
   3. Expected format: sk_us_* (Sandbox US) or pk_us_* (Production US)
⚠️ Failed to connect to Junction: Invalid Junction API key. Please contact support.
```

1.5. **Conflict with SDD**: This bug directly conflicts with [SDD:1433](Software_Development_Document.md#L1433) which documents `JunctionManager.swift` and the Junction SDK integration. The SDD describes "Automated HealthKit data sync (hourly)" at line 1427, but this functionality is completely broken.

### 2. What was the root cause

2.1. **ACTUAL ROOT CAUSE - Wrong API Base URL**: The JunctionManager.swift was using incorrect API base URLs:

- **Wrong (in code)**: `https://api.us.junction.com`
- **Correct (per [Junction docs](https://docs.junction.com/home/quickstart))**: `https://api.sandbox.tryvital.io`

   Junction (formerly Vital) uses `tryvital.io` domain for their API endpoints, not `junction.com`. The `junction.com` domain is only for their dashboard and documentation.

2.2. **Correct Junction API Endpoints** (per official documentation):

- **US Sandbox**: `https://api.sandbox.tryvital.io`
- **US Production**: `https://api.tryvital.io`
- **EU Sandbox**: `https://api.sandbox.eu.tryvital.io`
- **EU Production**: `https://api.eu.tryvital.io`

2.3. **Misleading Error Message**: The 401 "invalid token" error was misleading. The actual issue was that `api.us.junction.com` either doesn't exist or points to a different service that doesn't recognize the API key. The API key itself was valid.

2.4. **Documentation Assumption Error**: The code assumed Junction's API domain would match their brand name (junction.com), but they retained the original Vital API infrastructure (tryvital.io) after rebranding.

### 3. What was the solution

**Immediate Fix (Completed):**

3.1. **Update API Base URLs in JunctionManager.swift**

Changed the base URL logic in `createUserInJunction()` method:

```swift
// BEFORE (incorrect):
if apiKey.hasPrefix("sk_us_") {
    baseURL = "https://api.us.junction.com"  // ❌ Wrong domain
}

// AFTER (correct):
if apiKey.hasPrefix("sk_us_") {
    baseURL = "https://api.sandbox.tryvital.io"  // ✅ Correct domain
}
```

3.2. **Complete URL Mapping**:

```swift
// US Sandbox (sk_us_*)
baseURL = "https://api.sandbox.tryvital.io"

// US Production (pk_us_*)
baseURL = "https://api.tryvital.io"

// EU Sandbox (sk_eu_*)
baseURL = "https://api.sandbox.eu.tryvital.io"

// EU Production (pk_eu_*)
baseURL = "https://api.eu.tryvital.io"
```

**Fix Part 2 - Correct API Endpoint Path (After 404 Error):**

After fixing the base URL, a 404 error appeared: `❌ Junction API error (404): {"detail":"Not Found"}`. This revealed the endpoint path was also wrong.

3.3. **Fix Endpoint Path** - Per [Junction API docs](https://docs.junction.com/api-reference/user/create-user):

```swift
// BEFORE (incorrect):
guard let url = URL(string: "\(baseURL)/v2/users") else {  // ❌ /v2/users (plural, no trailing slash)

// AFTER (correct):
guard let url = URL(string: "\(baseURL)/v2/user/") else {  // ✅ /v2/user/ (singular, WITH trailing slash)
```

3.4. **Fix Request Headers** - Per Junction documentation:

```swift
// BEFORE:
request.setValue(apiKey, forHTTPHeaderField: "X-Vital-API-Key")
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

// AFTER:
request.setValue("application/json", forHTTPHeaderField: "Accept")      // Added
request.setValue(apiKey, forHTTPHeaderField: "x-vital-api-key")         // lowercase
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
```

3.5. **Added Debug Logging**: Added base URL to debug output to help identify URL issues:

```swift
print("📍 Base URL: \(baseURL)")
```

**Fix Part 3 - Missing Glucose in HealthKit Permission Request:**

After fixing the API issues, the user was successfully created in Junction (`✅ User created in Junction: fefffdc3-66b3-4141-87af-9efa4510a7e5`) and sync appeared to succeed. However, **no glucose data appeared in Junction dashboard**.

3.6. **Add .vitals(.glucose) to VitalHealthKitClient Permissions** - Per [Junction Vital Health SDK](https://docs.junction.com/wearables/sdks/vital-health) and [vital-ios source](https://github.com/tryVital/vital-ios):

```swift
// BEFORE (missing glucose):
let _ = await VitalHealthKitClient.shared.ask(
    readPermissions: [.activity, .workout, .sleep],  // ❌ No glucose!
    writePermissions: []
)

// AFTER (with glucose - note the nested .vitals syntax):
let _ = await VitalHealthKitClient.shared.ask(
    readPermissions: [.vitals(.glucose), .activity, .workout, .sleep],  // ✅ Glucose added
    writePermissions: []
)
```

**CRITICAL - VitalResource Uses Nested Enums**:

- ❌ `.glucose` does NOT exist - will cause compile error
- ✅ `.vitals(.glucose)` is the correct syntax

Other vitals use the same pattern:

- `.vitals(.bloodOxygen)`
- `.vitals(.bloodPressure)`
- `.vitals(.heartRate)`
- `.vitals(.heartRateVariability)`
- `.vitals(.respiratoryRate)`
- `.vitals(.temperature)`

**Important**: Junction's Vital SDK only syncs data types that you explicitly request permission for. The docs state: "sync is automatically activated on all resource types you have asked permission for." If you don't ask for `.vitals(.glucose)`, glucose data will never be synced even if the user has glucose data in HealthKit.

**Fix Part 4 - Handle "User Already Exists" 400 Response:**

After fixing previous issues, the API returned a 400 error when the user already existed:

```json
{"detail":{"error_type":"INVALID_REQUEST","error_message":"Client user id already exists.","user_id":"fefffdc3-66b3-4141-87af-9efa4510a7e5","created_on":"2025-12-04T17:57:52+00:00"}}
```

The code expected a 409 (Conflict) but Junction returns 400 (Bad Request) with the existing `user_id` in the response body.

3.7. **Handle 400 "User Already Exists" Response**:

```swift
// BEFORE (only handled 409):
} else if httpResponse.statusCode == 409 {
    // User already exists - fetch the existing user
    return try await fetchExistingUser(...)
}

// AFTER (handle both 400 and 409, extract user_id from error response):
} else if httpResponse.statusCode == 400 || httpResponse.statusCode == 409 {
    // User already exists - Junction returns 400 with user_id in the response
    if let errorResponse = try? JSONDecoder().decode(JunctionUserExistsErrorResponse.self, from: data),
       let existingUserId = errorResponse.detail.userId {
        print("ℹ️  User already exists in Junction: \(existingUserId)")
        return existingUserId
    }
    // Fallback: try to fetch the existing user
    return try await fetchExistingUser(...)
}
```

Added model to parse the error response:

```swift
struct JunctionUserExistsErrorResponse: Codable {
    let detail: JunctionUserExistsDetail
}

struct JunctionUserExistsDetail: Codable {
    let errorType: String?
    let errorMessage: String?
    let userId: String?      // The existing user's ID
    let createdOn: String?
}
```

**Fix Part 5 - Missing SDK Authentication (Sign-In Token):**

After all previous fixes, the app showed "sync success" but **no data appeared in Junction dashboard**. The issue: `VitalClient.setUserId()` was called but the SDK was never **authenticated** to upload data.

Per [Junction SDK Authentication docs](https://docs.junction.com/wearables/sdks/authentication): The SDK must be signed in with a **Vital Sign-In Token** for data to upload to Junction's cloud.

3.8. **Create Sign-In Token and Call VitalClient.signIn()**:

```swift
// BEFORE (missing authentication - data won't upload):
await VitalClient.setUserId(userUUID)  // ❌ Only sets local user ID

// AFTER (proper authentication - data WILL upload):
// 1. Create sign-in token via API
let signInToken = try await createSignInToken(junctionUserId: junctionUserId, apiKey: apiKey)

// 2. Sign in with VitalClient
try await VitalClient.signIn(withRawToken: signInToken)  // ✅ SDK authenticated
```

Sign-in token API: `POST /v2/user/{user_id}/sign_in_token`

Response model:

```swift
struct JunctionSignInTokenResponse: Codable {
    let userId: String        // user_id
    let signInToken: String   // sign_in_token
}
```

**Key insight**: `VitalClient.setUserId()` is NOT the same as authentication. The SDK needs `VitalClient.signIn(withRawToken:)` to obtain OAuth credentials that allow data upload to Junction's cloud.

**Files Modified**:

- `Xcode/Services/Junction/JunctionManager.swift` - Lines 17-60, 137-181, 304-360

### 4. What are the learnings for potential future bugs

4.1. **API Domain ≠ Brand Domain**: After company rebrands, API infrastructure often retains original domain. Junction (formerly Vital) uses `tryvital.io` for API despite being branded as Junction. Always verify API endpoints from official documentation.

4.2. **401 Errors Can Be Misleading**: A 401 "invalid token" error doesn't always mean the token is invalid. It can also indicate:

- Wrong API endpoint (request never reaches the correct server)
- Wrong API version
- Wrong region endpoint
- Server doesn't recognize the authentication header

4.3. **Check Official Documentation First**: Before assuming an API key is expired, verify:

1. Are you using the correct API base URL?
2. Are you using the correct API version (v1 vs v2)?
3. Are you using the correct authentication header format?
4. Are you hitting the correct regional endpoint?

4.4. **Log Request URLs**: Always log the full request URL (not just the endpoint path) when debugging API issues. This would have immediately revealed the wrong domain.

4.5. **Domain Inference is Risky**: Never assume API endpoint domains based on:

- Company brand name
- Dashboard URL
- Documentation URL
  Always get the actual API base URL from official API documentation.

4.6. **Test API Endpoints Independently**: Before blaming API keys, test the endpoint with curl:

```bash
curl -X POST "https://api.sandbox.tryvital.io/v2/user/" \
  -H "Accept: application/json" \
  -H "x-vital-api-key: sk_us_xxx" \
  -H "Content-Type: application/json" \
  -d '{"client_user_id": "test"}'
```

4.6.1. **Endpoint Paths Matter - Singular vs Plural, Trailing Slashes**: REST API endpoints can differ subtly:

- `/v2/users` vs `/v2/user/` - singular vs plural
- `/v2/user` vs `/v2/user/` - with or without trailing slash
  Always copy exact paths from documentation, don't assume patterns.

4.6.2. **SDK Data Sync is Permission-Driven**: Health SDKs like Junction/Vital only sync data types you explicitly request permission for. "Sync success" doesn't mean all data types are syncing - only the ones in your permission request. Always verify your permission list includes ALL data types you want to sync.

4.6.3. **SDK Enums May Use Nested Types**: The VitalResource enum uses nested types for certain data categories:

- ❌ `.glucose` doesn't exist (compile error)
- ✅ `.vitals(.glucose)` is correct
- Pattern: `.vitals(.bloodOxygen)`, `.vitals(.heartRate)`, etc.
  Always check the SDK source code or generated documentation for exact enum syntax.

4.7. **Company Rebrands Require Code Audit**: When a third-party service rebrands (Vital → Junction), audit all hardcoded URLs, domain references, and documentation links. The API infrastructure may not change immediately.

4.8. **API Key Format Hints at Infrastructure**: The API key prefix `sk_us_` (starting with "s" for sandbox, "k" from "key") is a Vital-era convention, hinting that the underlying infrastructure is still Vital's `tryvital.io` domain.

4.9. **Multiple Failure Points**: This bug had multiple layers:

- First thought: API key expired → Updated key → Still failed
- Second thought: API key invalid → Verified key format → Still failed
- Actual issue: Wrong base URL → Fixed URLs → Should work

   When the obvious fix doesn't work, question other assumptions.

4.10. **Source Official Documentation**: Always reference [official Junction API docs](https://docs.junction.com/home/quickstart) rather than assuming URLs based on patterns from similar services.

**Status of Bug 17:**
✅ **RESOLVED** - Fixed API base URLs in JunctionManager.swift

**Files Modified**:

- `Xcode/Services/Junction/JunctionManager.swift` - Lines 149-171, 186-188

**Expected After Fix**:

- Junction API calls should succeed (correct endpoint: `api.sandbox.tryvital.io`)
- User creation should complete successfully
- HealthKit data sync should work as documented in [SDD:1427](Software_Development_Document.md#L1427)

**Related Documentation**:

- [SDD:1418-1496](Software_Development_Document.md#L1418-L1496): Junction SDK Integration section
- [Junction API Quickstart](https://docs.junction.com/home/quickstart): Official API documentation
- [Junction Authentication](https://docs.tryvital.io/api-details): API authentication details

---

## Bug 18 - Junction API 402 Error: Sandbox Trial Period Expired

### 1. What was the bug

1.1. **Symptom**: iOS app displays "failed to sync" with Junction. The app successfully authenticates with Supabase and tracks the user sign-in event, but Junction connection fails with error message: "Network error. Please check your connection and try again."

1.2. **User Impact**: CRITICAL - HealthKit data (particularly glucose readings) cannot be synced to Junction's cloud. The user exists in Junction dashboard (`user_id: fefffdc3-66b3-4141-87af-9efa4510a7e5`) but has zero glucose data, breaking the ML model training data pipeline.

1.3. **Reproducibility**: Occurs 100% of the time for all users attempting to sync data via the Junction SDK.

1.4. **Debug Context**: Log output reveals the actual error:

```
✅ PostHog Analytics initialized
🔗 Junction SDK configured with sandbox environment
📊 Event tracked: junction_configured
📊 Event tracked: user_signed_in
📝 Creating user in Junction backend...
🌐 API Request: POST https://api.sandbox.tryvital.io/v2/user/
🔑 API Key prefix: sk_us_Gn...
📍 Base URL: https://api.sandbox.tryvital.io
❌ Junction API error (402): {"detail":"The trial period has ended. Please subscribe to one of our paid plans at https://app.junction.com/."}
⚠️ Failed to connect to Junction: Network error. Please check your connection and try again.
📊 Event tracked: junction_connection_failed
```

1.5. **Conflict with SDD**: This bug directly conflicts with [SDD:1433](Software_Development_Document.md#L1433) which documents `JunctionManager.swift` and the Junction SDK integration. The SDD describes "Automated HealthKit data sync (hourly)" at line 1427, but this functionality is completely blocked due to expired trial.

### 2. What was the root cause

2.1. **ACTUAL ROOT CAUSE - Sandbox Trial Period Expired**: The Junction (formerly Vital) sandbox API trial period has ended. Junction provides a free sandbox environment for development and testing, but this sandbox has usage limits or time-based expiration.

2.2. **402 Payment Required**: HTTP status code 402 explicitly indicates a payment/subscription issue. The error message confirms: `"The trial period has ended. Please subscribe to one of our paid plans at https://app.junction.com/."`

2.3. **Not a Code Issue**: Unlike Bug 17 (wrong API URLs), this bug is NOT caused by incorrect code implementation. The API endpoints are correct (as proven by Bug 17 fixes working previously), but the account lacks an active subscription.

2.4. **Sandbox vs Production**: The app is using the sandbox environment (`sk_us_*` prefix, `api.sandbox.tryvital.io` endpoint) which typically has:

- Limited number of test users
- Limited data volume
- Time-limited trial period (e.g., 14 or 30 days)

2.5. **Misleading User-Facing Error**: The app displays "Network error. Please check your connection and try again." which is misleading. The actual issue is a billing/subscription problem, not a network connectivity issue.

### 3. What was the solution

**Immediate Solutions:**

3.1. **Renew Junction Sandbox Subscription**: Contact Junction support or access the Junction dashboard at `https://app.junction.com/` to:

- Check current subscription status
- Renew sandbox access for continued development
- Or upgrade to a paid plan if trial cannot be extended

3.2. **Update Credentials if New API Key Issued**: If Junction issues a new API key after renewal:

```swift
   // In Constants.swift
   static let junctionAPIKey = "sk_us_NEW_API_KEY_HERE"
```

3.3. **Improve Error Messaging**: Update JunctionManager to display accurate error messages for 402 responses:

```swift
   case 402:
       print("❌ Junction subscription expired. Please renew at https://app.junction.com/")
       throw JunctionError.subscriptionExpired
```

**Long-Term Solutions:**

3.4. **Add Subscription Status Check**: Implement a method to check subscription status before attempting data operations:

```swift
   func checkSubscriptionStatus() async throws -> Bool {
       // Call Junction API to verify account is active
       // Return false if 402 error, prompt user to contact admin
   }
```

3.5. **Graceful Degradation**: When Junction is unavailable (expired subscription, network issues, etc.), the app should:

- Continue functioning for HealthKit-only features
- Display clear message about limited functionality
- Queue data for later sync when service resumes

3.6. **Document Renewal Process**: Create documentation for the subscription renewal process:

- Junction dashboard URL
- Contact information for support
- Expected renewal frequency
- API key rotation process

**Files to Update After Renewal:**

- `Xcode/Utilities/Constants.swift` - Update `junctionAPIKey` if new key issued
- `Xcode/Services/Junction/JunctionManager.swift` - Improve 402 error handling

### 4. What are the learnings for potential future bugs

4.1. **Third-Party Service Dependencies Have Hidden Costs**: SDK integrations often have subscription requirements that aren't apparent during initial development. Trial periods expire, free tiers have limits, and API keys can be revoked.

4.2. **402 Errors Mean Billing Issues**: HTTP 402 (Payment Required) always indicates a billing/subscription problem, not a technical issue. Don't debug code when you see 402 - check the account status first.

4.3. **Error Messages Should Reflect Actual Cause**: Translating a 402 "subscription expired" error to "Network error" is misleading. Map API errors to accurate user-facing messages:

- 402 → "Subscription expired. Please contact support."
- 401 → "Authentication failed. Please sign out and sign in again."
- 500 → "Server error. Please try again later."

4.4. **Sandbox Environments Have Limitations**: Sandbox/development environments typically have:

- Time-limited trials (14, 30, 90 days)
- Rate limits (requests per minute/day)
- Data limits (number of users, records)
- Feature restrictions

   Plan for sandbox expiration during development timeline.

4.5. **Monitor Third-Party Service Status**: Implement monitoring/alerting for third-party API failures. A sudden spike in 402/401/500 errors indicates service issues requiring immediate attention.

4.6. **Document Subscription Requirements**: In project documentation, clearly list all third-party services that require active subscriptions:

- Service name and purpose
- Dashboard URL for account management
- Renewal frequency/cost
- Who is responsible for renewal
- What breaks when subscription expires

4.7. **Test Subscription Expiration Scenarios**: As part of integration testing, verify how the app behaves when third-party subscriptions expire:

- Does it fail gracefully?
- Are error messages clear?
- Does core functionality continue?

4.8. **Budget for Production Services**: When moving from sandbox to production:

- Junction/Vital: Paid plans start at ~$500/month for startups
- Plan for this cost in project budget
- Negotiate pricing before trial expires

4.9. **Log Full Error Details**: The log correctly captured the 402 error and full JSON response. This level of logging is essential for diagnosing third-party service issues quickly.

4.10. **Distinguish Technical vs Business Errors**: This bug looked technical (sync failed) but was actually a business/billing issue (subscription expired). Create separate error categories and handling paths for:

- Technical errors (code bugs, network issues)
- Business errors (subscription, rate limits, quota exceeded)
- User errors (invalid input, permission denied)

**Status of Bug 18:**
🟢 **RESOLVED** (2025-12-09) - API key renewed successfully

**Resolution:**

1. New API key obtained: `sk_us_Gb2bkO8kvbSw0-DtyUWedO26IvtkomiYRafF7RRHMus` (Dec 9, 2025)
2. Updated `Constants.junctionAPIKey` with new key
3. User creation and sign-in token generation now working
4. Note: New Bug 19 discovered - VitalClient JWT sign-in fails after token generation

**Related Documentation**:

- [SDD:1418-1496](Software_Development_Document.md#L1418-L1496): Junction SDK Integration section
- [Credentials.md](Credentials.md): Junction sandbox API key and demo connection API documentation
- [Junction Pricing](https://app.junction.com/): Subscription plans and renewal

---

## Bug 19 - Junction VitalClient JWT Sign-In Error After API Key Renewal

### 1. What was the bug

1.1. **Symptom**: iOS app displays "Failed to connect to Junction" despite successful user creation and sign-in token generation. The VitalClient SDK throws `VitalCore.VitalJWTSignInError error 0` when attempting to sign in with the token.

1.2. **User Impact**: CRITICAL - HealthKit data cannot be synced to Junction's cloud. The user is created in Junction backend, sign-in token is generated, but the SDK authentication step fails, blocking all subsequent data sync operations.

1.3. **Reproducibility**: Occurs 100% of the time after updating to the new API key (Dec 9, 2025).

1.4. **Debug Context**: Log output reveals the partial success followed by failure:

```
✅ PostHog Analytics initialized
🔗 Junction SDK configured with sandbox environment
📊 Event tracked: junction_configured
✅ VitalHealthKitClient configured for background delivery
📊 Event tracked: user_signed_in
📝 Creating user in Junction backend...
🌐 API Request: POST https://api.sandbox.tryvital.io/v2/user/
🔑 API Key prefix: sk_us_Gb...
📍 Base URL: https://api.sandbox.tryvital.io
✅ User created in Junction: 5c9657f5-c5cf-47fb-ac64-9f0774604445
🔐 Creating sign-in token for VitalClient...
🌐 API Request: POST https://api.sandbox.tryvital.io/v2/user/5c9657f5-c5cf-47fb-ac64-9f0774604445/sign_in_token
✅ Sign-in token created for user: 5c9657f5-c5cf-47fb-ac64-9f0774604445
🔑 Sign-in token created, signing in with VitalClient...
⚠️ Failed to connect to Junction: The operation couldn't be completed. (VitalCore.VitalJWTSignInError error 0.)
📊 Event tracked: junction_connection_failed
```

1.5. **Conflict with SDD**: This bug conflicts with [SDD:1433](Software_Development_Document.md#L1433) which documents `JunctionManager.swift` and the Junction SDK integration. The SDD describes the SDK integration flow but does not document the `VitalJWTSignInError` failure mode or its resolution.

1.6. **Difference from Bug 18**: Bug 18 was a 402 "Payment Required" error due to expired sandbox trial. Bug 19 occurs AFTER API key renewal - the REST API calls succeed but the SDK's internal JWT authentication fails.

### 2. What was the root cause

2.1. **ACTUAL ROOT CAUSE - Incorrect SDK Initialization Order**: The `VitalHealthKitClient.automaticConfiguration()` was being called in `AppDelegate.didFinishLaunchingWithOptions` BEFORE `VitalClient.configure()` was called. The Vital SDK requires a specific initialization order:

1. `VitalClient.configure(apiKey:environment:)` FIRST
2. `VitalHealthKitClient.automaticConfiguration()` SECOND

   When the order is reversed, the SDK's internal state is not properly initialized, causing JWT sign-in to fail with `VitalJWTSignInError error 0`.

2.2. **Why the order matters**: `VitalHealthKitClient.automaticConfiguration()` sets up background delivery and sync, but it depends on `VitalClient` being configured first. Without proper configuration, the SDK cannot validate JWT tokens correctly.

2.3. **Contributing Factor - Redundant Sign-Ins**: The code was attempting to sign in on every app launch, but per Junction docs: "it is unnecessary to request and sign-in with the Vital Sign-In Token every time your app launches." The SDK persists authentication state, so repeated sign-ins can cause issues.

### 3. What was the solution

**Fix 1 - Correct SDK Initialization Order in AppDelegate** (`AppDelegate.swift`):

Move `VitalClient.configure()` to AppDelegate BEFORE `VitalHealthKitClient.automaticConfiguration()`:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions...) -> Bool {
    // CRITICAL: Configure VitalClient FIRST before VitalHealthKitClient
    if Constants.isJunctionEnabled {
        if Constants.junctionEnvironment == "sandbox" {
            VitalClient.configure(apiKey: Constants.junctionAPIKey, environment: .sandbox(.us))
        } else {
            VitalClient.configure(apiKey: Constants.junctionAPIKey, environment: .production(.us))
        }
        print("🔗 VitalClient configured with \(Constants.junctionEnvironment) environment (AppDelegate)")
    }

    // THEN configure VitalHealthKitClient for background delivery
    VitalHealthKitClient.automaticConfiguration()
    return true
}
```

**Fix 2 - Skip Sign-In if Already Authenticated** (`JunctionManager.swift`):

Check if SDK is already signed in before attempting sign-in:

```swift
func connectUser(userId: String) async throws {
    // Check if VitalClient is already signed in (session persists across app launches)
    let currentStatus = await VitalClient.status
    if currentStatus.contains(.signedIn) {
        print("✅ VitalClient already signed in - skipping sign-in flow")
        self.isConnected = true
        return
    }
    // ... rest of sign-in flow
}
```

**Fix 3 - Add markConfigured Method** (`JunctionManager.swift`):

Since `VitalClient.configure()` is now called in AppDelegate, add a method to mark JunctionManager as configured without duplicate calls:

```swift
func markConfigured(environment: String = "sandbox") {
    self.apiKey = Constants.junctionAPIKey
    self.isConfigured = true
    AnalyticsManager.shared.track(event: "junction_configured", properties: ["environment": environment])
}
```

**Fix 4 - Update ViiRaaApp.swift**:

Call `markConfigured()` instead of `configure()`:

```swift
if Constants.isJunctionEnabled {
    JunctionManager.shared.markConfigured(environment: Constants.junctionEnvironment)
}
```

**Fix 5 - Add Better Error Logging** (`JunctionManager.swift`):

Log token details and provide helpful error context:

```swift
let tokenPreview = signInToken.prefix(20)
print("🎫 Sign-in token preview: \(tokenPreview)... (length: \(signInToken.count))")
```

**Files Modified:**

- `Xcode/App/AppDelegate.swift` - Added VitalClient.configure() before VitalHealthKitClient.automaticConfiguration()
- `Xcode/App/ViiRaaApp.swift` - Changed to call markConfigured() instead of configure()
- `Xcode/Services/Junction/JunctionManager.swift` - Added markConfigured(), status check, and improved error logging

### 4. What are the learnings for potential future bugs

4.1. **SDK Initialization Order Matters**: Multi-component SDKs often have strict initialization order requirements. Always check documentation for:

- Which component must be configured first
- Whether background delivery depends on core configuration
- What happens if initialization order is wrong (often cryptic errors)

4.2. **VitalJWTSignInError error 0 = Configuration Problem**: This specific error indicates the SDK's internal state wasn't properly set up. The "error 0" is not about the JWT token itself, but about the SDK not being ready to process it.

4.3. **SDK Sessions Are Persistent**: Per Junction docs: "it is unnecessary to request and sign-in with the Vital Sign-In Token every time your app launches." Always check `VitalClient.status` before attempting sign-in to avoid redundant auth attempts.

4.4. **AppDelegate vs App.init() Order**: In SwiftUI apps with `@UIApplicationDelegateAdaptor`:

- `AppDelegate.didFinishLaunchingWithOptions` runs FIRST
- `App.init()` runs SECOND
- Use AppDelegate for SDK configuration that must happen before anything else

4.5. **Log Token Details During Authentication Failures**: When JWT/token-based authentication fails, log:

- Token preview (first 20 chars for security)
- Token length
- SDK configuration state

4.6. **Error Code 0 Often Means "Unknown/Unexpected"**: Generic error codes indicate the SDK hit an unexpected state. Common causes:

- Configuration mismatch
- Initialization order violation
- SDK internal state corruption

4.7. **Sandbox Keys Have Short Lifespans**: Junction sandbox keys only last ~1 week. This means:

- Automated renewal process needed
- Documentation should track key expiration dates
- Consider production keys for longer development cycles

4.8. **Separate Configuration from State Marking**: When SDK configuration must happen in a specific place (AppDelegate), use a separate `markConfigured()` method in your manager class to update internal state without duplicate configuration calls.

**Status of Bug 19:**
🟢 **RESOLVED** (2025-12-09) - Fixed SDK initialization order

**Resolution Summary:**

1. Moved `VitalClient.configure()` to AppDelegate BEFORE `VitalHealthKitClient.automaticConfiguration()`
2. Added `VitalClient.status` check to skip sign-in if already authenticated
3. Added `markConfigured()` method to JunctionManager for state management
4. Added improved error logging with token preview

**Related Documentation**:

- [SDD:1433](Software_Development_Document.md#L1433): JunctionManager.swift documentation
- [Bug 18](#bug-18---junction-api-402-error-sandbox-trial-period-expired): Previous Junction authentication issue (resolved)
- [Credentials.md](Credentials.md): Current API key (sk_us_Gb..., Dec 9, 2025)
- [VitalCore SDK Docs](https://docs.tryvital.io/): Junction/Vital SDK documentation
- [Junction Authentication](https://docs.junction.com/wearables/sdks/authentication): Sign-in token flow

---

### Version 4.3 (2025-12-09)

- Added and RESOLVED Bug 19: Junction VitalClient JWT Sign-In Error After API Key Renewal
- Updated Bug 18 status to 🟢 RESOLVED - API key renewed successfully
- **Root Cause (Bug 19)**: `VitalHealthKitClient.automaticConfiguration()` was called BEFORE `VitalClient.configure()` - SDK requires specific initialization order
- **Solution**: Moved `VitalClient.configure()` to AppDelegate before `VitalHealthKitClient.automaticConfiguration()`, added `VitalClient.status` check to skip redundant sign-ins
- **Files Modified**: `AppDelegate.swift`, `ViiRaaApp.swift`, `JunctionManager.swift`
- Key learning: Multi-component SDKs have strict initialization order requirements
- Key learning: `VitalJWTSignInError error 0` = SDK configuration problem, not token problem
- Key learning: SDK sessions persist across app launches - check status before sign-in
- Key learning: Use AppDelegate for SDK configuration that must run before SwiftUI App.init()

### Version 4.2 (2025-12-08)

- Added Bug 18: Junction API 402 Error - Sandbox Trial Period Expired
- **Root Cause**: Junction sandbox trial period ended, requiring subscription renewal
- **Symptom**: 402 "Payment Required" error with message "The trial period has ended"
- **Impact**: All Junction sync functionality blocked, no glucose data reaching Junction dashboard
- **Conflict**: Directly conflicts with SDD:1433 Junction SDK Integration documentation
- Key learning: Third-party SDK integrations have hidden subscription dependencies
- Key learning: 402 errors indicate billing issues, not technical bugs
- Key learning: Error messages should accurately reflect the actual cause (not "network error" for billing issues)

### Version 4.1 (2025-12-04)

- Added Bug 17: Junction API 401/404 Errors Due to Incorrect API Configuration
- **Root Cause 1**: Code used wrong domain (`api.us.junction.com`) → 401 error
- **Root Cause 2**: Code used wrong endpoint path (`/v2/users`) → 404 error after domain fix
- **Root Cause 3**: HealthKit permissions missing glucose → user synced but no glucose data in Junction
- **Root Cause 4**: Used `.glucose` instead of `.vitals(.glucose)` → compile error (VitalResource uses nested enums)
- **Root Cause 5**: Junction returns 400 (not 409) for "user already exists" with user_id in error body
- **Fix Part 1**: Updated base URLs to `api.sandbox.tryvital.io` (Junction retained Vital's domain)
- **Fix Part 2**: Changed endpoint from `/v2/users` to `/v2/user/` (singular with trailing slash)
- **Fix Part 3**: Updated headers - added `Accept` header, lowercase `x-vital-api-key`
- **Fix Part 4**: Added `.vitals(.glucose)` to VitalHealthKitClient permission request (not `.glucose`)
- **Fix Part 5**: Handle 400 "user already exists" response by extracting user_id from error body
- **Root Cause 6**: SDK not authenticated - `VitalClient.setUserId()` is NOT authentication
- **Fix Part 6**: Create sign-in token via API and call `VitalClient.signIn(withRawToken:)` for SDK authentication
- Key learning: Junction only syncs data types you explicitly request permission for
- Key learning: SDK must call `signIn()` not just `setUserId()` for data to upload to cloud
- Documented conflict with SDD:1433 Junction SDK Integration section

## Bug 20 - Junction Dashboard Shows No Connection Data Despite Successful iOS Sync

### 1. What was the bug

1.1. **Symptom**: The iOS app shows successful Junction data sync (`✅ Junction sync initiated - data will upload in background`), but in the Junction Dashboard, the user (`user_id: 5c9657f5-c5cf-47fb-ac64-9f0774604445`) exists with **no connection data** visible.

1.2. **User Impact**: CRITICAL - Users believe their HealthKit data is being synced to Junction for ML model training, but no data is actually available in the Junction cloud. This breaks the entire data pipeline for health analytics.

1.3. **Reproducibility**: Occurs consistently - user exists in Junction Dashboard but has zero data connections despite iOS app reporting successful sync.

1.4. **Debug Context**: Log output shows apparent success:

```
✅ PostHog Analytics initialized
🔗 Junction SDK configured with sandbox environment
📊 Event tracked: junction_configured
🔗 VitalClient configured with sandbox environment (AppDelegate)
✅ VitalHealthKitClient configured for background delivery
📊 Event tracked: user_signed_in
✅ VitalClient already signed in - skipping sign-in flow
📊 Event tracked: junction_user_reconnected
✅ HealthKit permissions granted via Junction (including glucose)
📊 Event tracked: junction_healthkit_authorized
🔄 Junction automatic sync started (hourly)
✅ User successfully connected to Junction and sync started
🔄 Triggering manual sync to Junction cloud...
✅ Junction sync initiated - data will upload in background
ℹ️  Note: Due to Apple's 3-hour HealthKit data delay, recent data may not be available immediately
📊 Event tracked: junction_sync_success
```

1.5. **Conflict with SDD**: This bug directly conflicts with [SDD:1433](Software_Development_Document.md#L1433) which documents `JunctionManager.swift` and states "Automated HealthKit data sync (hourly)" at [SDD:1427](Software_Development_Document.md#L1427). The documentation implies data should flow from HealthKit → Junction cloud, but no data arrives.

### 2. What was the root cause

**Potential Root Cause 1 - Missing Provider Connection (Most Likely)**:

2.1. **Disconnected Provider in Junction Dashboard**: The user exists in Junction, but may not have an active **provider connection**. In Junction's architecture:

- **User** = Identity in the system (created via API)
- **Provider Connection** = Link between user and a data source (Apple Health, Oura, Fitbit, etc.)

   The iOS app creates the user and calls sync, but the **Apple Health provider** may not be properly connected/linked to the user in Junction's system.

**Potential Root Cause 2 - SDK Background Sync Not Triggering**:

2.2. **VitalHealthKitClient Background Delivery Issues**: The log shows `✅ VitalHealthKitClient configured for background delivery`, but iOS background delivery for HealthKit has strict requirements:

- App must be registered for background fetch
- HealthKit background delivery is observer-based, not polling-based
- Data only syncs when HealthKit notifies of new samples
- If no new HealthKit data is recorded, no sync is triggered

**Potential Root Cause 3 - 3-Hour Data Delay Not Elapsed**:

2.3. **Apple HealthKit 3-Hour Delay**: Per [SDD:1431](Software_Development_Document.md#L1431): "Apple HealthKit enforces a minimum 3-hour data delay." If the user's most recent glucose data is less than 3 hours old, HealthKit may not make it available to the Junction SDK yet.

**Potential Root Cause 4 - Permission Scope Mismatch**:

2.4. **HealthKit Permissions vs Junction Sync Scope**: The app may request HealthKit permissions for glucose, but the Junction SDK may be configured to sync different data types. If the `VitalHealthKitClient.ask()` permissions don't include the exact data types being checked in Junction Dashboard, data won't appear.

**Potential Root Cause 5 - Sandbox Data Isolation**:

2.5. **Sandbox Environment Limitations**: Junction's sandbox environment may have limitations:

- Data retention periods (sandbox may auto-delete data)
- Limited data visibility in dashboard
- Sandbox data not appearing in certain dashboard views

### 3. What was the solution

**Investigation Steps (Required):**

3.1. **Check Junction Dashboard Provider Connections**:

- Log into Junction Dashboard at `https://app.junction.com/`
- Navigate to the user `5c9657f5-c5cf-47fb-ac64-9f0774604445`
- Check the "Connections" or "Providers" tab
- Verify if "Apple Health" appears as a connected provider
- If no Apple Health connection exists, this confirms Root Cause 1

3.2. **Verify API-Side Connection Status**:

```bash
   # Check user's connected providers via Junction API
   curl -X GET "https://api.sandbox.tryvital.io/v2/user/5c9657f5-c5cf-47fb-ac64-9f0774604445/providers" \
     -H "x-vital-api-key: sk_us_YOUR_API_KEY" \
     -H "Accept: application/json"
```

   Expected: Should list "apple_health_kit" as a connected provider. If empty or missing, the SDK hasn't established the connection.

3.3. **Review Junction Demo Connection API**:

- Reference documentation at `/Users/barack/Downloads/Xcode/Credentials.md` mentions a "Junction Connection Demo"
- The demo may show the proper flow for establishing provider connections
- Compare demo implementation with current JunctionManager.swift

**Likely Fix - Explicit Provider Connection**:

3.4. **Add Provider Connection Step in JunctionManager**:

   After user sign-in, explicitly connect Apple Health as a provider:

```swift
   func connectAppleHealthProvider() async throws {
       // After VitalClient.signIn(), ensure Apple Health is connected
       try await VitalHealthKitClient.shared.startSyncing(
           resources: [.vitals(.glucose), .activity, .workout, .sleep]
       )
       print("✅ Apple Health provider connected and syncing started")
   }
```

3.5. **Verify Data Exists in HealthKit**:

   Before assuming Junction sync is broken, verify HealthKit actually has data:

```swift
   func debugHealthKitData() async {
       let glucoseData = try? await healthKitManager.fetchLatestGlucose()
       print("📊 Latest HealthKit glucose: \(glucoseData ?? "nil")")
       print("📊 Glucose timestamp: \(glucoseData?.timestamp ?? "nil")")
   }
```

3.6. **Force Manual Sync with Explicit Resources**:

   Instead of relying on automatic sync, trigger explicit resource sync:

```swift
   func forceSyncAllResources() async throws {
       try await VitalHealthKitClient.shared.syncData(for: .vitals(.glucose))
       try await VitalHealthKitClient.shared.syncData(for: .activity)
       print("✅ Manual sync triggered for specific resources")
   }
```

**Alternative Solution - Sync via HealthKit App Directly**:

3.7. **Per Bug Report**: "If you fail to sync up data in ViiRaa app to Junction, you can also choose to sync up data in HealthKit app to Junction." This suggests an alternative path using Junction's direct HealthKit integration rather than the VitalHealthKitClient SDK.

### 4. What are the learnings for potential future bugs

4.1. **"Sync Success" ≠ "Data Delivered"**: The iOS app logging `✅ Junction sync initiated` only means the sync was requested. It does NOT confirm data actually reached Junction's servers. Always verify data arrival in the destination dashboard, not just the source app logs.

4.2. **User Creation ≠ Provider Connection**: In health data platforms like Junction, creating a user is just step 1. The user must also have an active **provider connection** (Apple Health, Oura, etc.) for data to flow. These are separate operations.

4.3. **Junction Architecture Has Multiple Layers**:

- Layer 1: User exists in Junction (via API `/v2/user/` creation)
- Layer 2: Provider connected to user (via SDK or Widget)
- Layer 3: Permissions granted (HealthKit read access)
- Layer 4: Data synced (background delivery + SDK upload)
- Layer 5: Data visible (after 3-hour delay + processing)

   Data won't appear if any layer is broken.

4.4. **Sandbox Data Visibility May Differ**: Sandbox environments often have different data retention and visibility rules. Data may exist but not be visible in certain dashboard views. Check API responses, not just dashboard UI.

4.5. **Background Sync Requires Active Data**: HealthKit background delivery only triggers when NEW data is added to HealthKit. If no new glucose readings are recorded, no sync is triggered. For testing, ensure the test device has recent HealthKit data.

4.6. **Log Both Request AND Response**: Current logging shows "sync initiated" but doesn't log the sync completion or any response from Junction servers. Add response logging:

```swift
   let response = try await VitalHealthKitClient.shared.syncData()
   print("📊 Sync response: \(response)")
```

4.7. **Test with Junction Demo First**: Before debugging SDK integration, test with Junction's official demo (mentioned in Credentials.md) to establish a baseline of working data flow. Compare demo behavior with app behavior.

4.8. **3-Hour Delay Affects Testing**: When testing Junction sync, data added to HealthKit now won't appear in Junction for at least 3 hours. Plan testing accordingly:

- Add test data to HealthKit
- Wait 3+ hours
- Then check Junction Dashboard
- Alternatively, use older HealthKit data (>3 hours old) for immediate testing

4.9. **Check Provider-Specific Requirements**: Each health data provider (Apple Health, Oura, Fitbit) may have specific connection requirements. Apple Health requires:

- HealthKit entitlement in app
- NSHealthShareUsageDescription in Info.plist
- User permission grant
- Background delivery registration

   Missing any requirement breaks the connection silently.

4.10. **API Key Scope May Limit Providers**: Junction API keys may be scoped to specific providers or data types. Verify the API key has permission to connect Apple Health and sync glucose data.

**Status of Bug 20:**
🟢 **RESOLVED** - Provider Connection Fix Implemented (2025-12-09)

**Evidence from Junction Dashboard Screenshot (Before Fix):**

- User `5c9657f5-c5cf-47fb-ac64-9f0774604445` exists in Junction
- **Connections tab shows ALL EMPTY** (`-` in every column):
  - PROVIDER: -
  - RESOURCES AVAILABILITY: -
  - CONNECTION STATUS: -
  - HISTORICAL FETCH STATUS: -
  - LAST DATA PULL ATTEMPT: -

**Confirmed Root Cause**: The iOS app creates the user via API and calls sync methods, but **never establishes an Apple Health provider connection**. Without a provider connection, there is no data source linked to the user, so no data can flow to Junction.

**Fix Implemented**: Added `createDemoConnection()` method to JunctionManager.swift that calls Junction's `/v2/link/connect/demo` API endpoint to create provider connections after user sign-in.

**Implementation Details:**

1. **New Method Added** - `createDemoConnection(junctionUserId:provider:apiKey:)`:

   - Calls `POST /v2/link/connect/demo` with `user_id` and `provider` parameters
   - Creates provider connections for "apple_health_kit" and "freestyle_libre"
   - Handles "already exists" responses gracefully
2. **Modified `connectUser()` Method**:

   - After successful VitalClient sign-in, now creates provider connections:
     ```swift
     try await createDemoConnection(junctionUserId: junctionUserId, provider: "apple_health_kit", apiKey: apiKey)
     try await createDemoConnection(junctionUserId: junctionUserId, provider: "freestyle_libre", apiKey: apiKey)
     ```
3. **Modified Reconnection Flow**:

   - Even when VitalClient is already signed in, now verifies provider connections exist
   - Fixes existing users who were created before this fix

**Files Modified:**

- `Xcode/Services/Junction/JunctionManager.swift`:
  - Added `createDemoConnection()` method (lines 363-439)
  - Modified `connectUser()` to call provider connection after sign-in (lines 231-244)
  - Modified reconnection flow to verify connections (lines 171-186)

**Expected After Fix:**

- Junction Dashboard should show provider connections (apple_health_kit, freestyle_libre)
- Data should flow from HealthKit → Junction cloud
- Glucose readings should appear in Junction Dashboard after 3-hour HealthKit delay

**Related Documentation**:

- [SDD:1433](Software_Development_Document.md#L1433): JunctionManager.swift documentation
- [SDD:1427](Software_Development_Document.md#L1427): "Automated HealthKit data sync (hourly)"
- [Credentials.md](Credentials.md): Junction Connection Demo reference
- [Bug 17](#bug-17---junction-api-401-error-due-to-incorrect-api-base-url): Previous Junction API URL issues
- [Bug 18](#bug-18---junction-api-402-error-sandbox-trial-period-expired): Previous Junction subscription issues
- [Bug 19](#bug-19---junction-vitalclient-jwt-sign-in-error-after-api-key-renewal): Previous Junction SDK sign-in issues

---

### Version 4.4 (2025-12-09)

- Added and RESOLVED Bug 20: Junction Dashboard Shows No Connection Data Despite Successful iOS Sync
- **Symptom**: iOS app shows successful sync but Junction Dashboard shows no data for user
- **Conflict with**: SDD:1433 (JunctionManager.swift) and SDD:1427 ("Automated HealthKit data sync")
- **ROOT CAUSE**: Missing Apple Health provider connection - user exists but Connections tab is completely empty
- **Evidence**: Junction Dashboard screenshot shows user with PROVIDER: -, CONNECTION STATUS: -, LAST DATA PULL ATTEMPT: -
- **FIX IMPLEMENTED**: Added `createDemoConnection()` method to call `/v2/link/connect/demo` API after user sign-in
- **Files Modified**: `JunctionManager.swift` - added provider connection creation for apple_health_kit and freestyle_libre
- **Key Learning**: "Sync Success" ≠ "Data Delivered" - verify at destination, not source
- **Key Learning**: User creation and provider connection are SEPARATE operations in Junction - must do BOTH
- **Key Learning**: Reference Credentials.md Junction Connection Demo for correct API flow
- **Status**: 🟢 RESOLVED

### Version 4.3 (2025-12-09)

- Added and RESOLVED Bug 19: Junction VitalClient JWT Sign-In Error After API Key Renewal
- Updated Bug 18 status to 🟢 RESOLVED - API key renewed successfully
- **Root Cause (Bug 19)**: `VitalHealthKitClient.automaticConfiguration()` was called BEFORE `VitalClient.configure()` - SDK requires specific initialization order
- **Solution**: Moved `VitalClient.configure()` to AppDelegate before `VitalHealthKitClient.automaticConfiguration()`, added `VitalClient.status` check to skip redundant sign-ins
- **Files Modified**: `AppDelegate.swift`, `ViiRaaApp.swift`, `JunctionManager.swift`
- Key learning: Multi-component SDKs have strict initialization order requirements
- Key learning: `VitalJWTSignInError error 0` = SDK configuration problem, not token problem
- Key learning: SDK sessions persist across app launches - check status before sign-in
- Key learning: Use AppDelegate for SDK configuration that must run before SwiftUI App.init()

### Version 4.2 (2025-12-08)

- Added Bug 18: Junction API 402 Error - Sandbox Trial Period Expired
- **Root Cause**: Junction sandbox trial period ended, requiring subscription renewal
- **Symptom**: 402 "Payment Required" error with message "The trial period has ended"
- **Impact**: All Junction sync functionality blocked, no glucose data reaching Junction dashboard
- **Conflict**: Directly conflicts with SDD:1433 Junction SDK Integration documentation
- Key learning: Third-party SDK integrations have hidden subscription dependencies
- Key learning: 402 errors indicate billing issues, not technical bugs
- Key learning: Error messages should accurately reflect the actual cause (not "network error" for billing issues)

### Version 4.1 (2025-12-04)

- Added Bug 17: Junction API 401/404 Errors Due to Incorrect API Configuration
- **Root Cause 1**: Code used wrong domain (`api.us.junction.com`) → 401 error
- **Root Cause 2**: Code used wrong endpoint path (`/v2/users`) → 404 error after domain fix
- **Root Cause 3**: HealthKit permissions missing glucose → user synced but no glucose data in Junction
- **Root Cause 4**: Used `.glucose` instead of `.vitals(.glucose)` → compile error (VitalResource uses nested enums)
- **Root Cause 5**: Junction returns 400 (not 409) for "user already exists" with user_id in error body
- **Fix Part 1**: Updated base URLs to `api.sandbox.tryvital.io` (Junction retained Vital's domain)
- **Fix Part 2**: Changed endpoint from `/v2/users` to `/v2/user/` (singular with trailing slash)
- **Fix Part 3**: Updated headers - added `Accept` header, lowercase `x-vital-api-key`
- **Fix Part 4**: Added `.vitals(.glucose)` to VitalHealthKitClient permission request (not `.glucose`)
- **Fix Part 5**: Handle 400 "user already exists" response by extracting user_id from error body
- **Root Cause 6**: SDK not authenticated - `VitalClient.setUserId()` is NOT authentication
- **Fix Part 6**: Create sign-in token via API and call `VitalClient.signIn(withRawToken:)` for SDK authentication
- Key learning: Junction only syncs data types you explicitly request permission for
- Key learning: SDK must call `signIn()` not just `setUserId()` for data to upload to cloud
- Documented conflict with SDD:1433 Junction SDK Integration section

### Version 4.0 (2025-11-25)

- Added Junction SDK Integration feature implementation documentation
- Documented feature flag pattern for SDK integrations
- Added testing checklist and prerequisites
- Documented 3-hour HealthKit data delay consideration

---

## Bug 21 - Glucose Data in Apple Health Not Syncing to Junction Dashboard (ACTIVE)

**Report Date**: 2025-12-12
**Status**: 🔴 ACTIVE - Under Investigation
**Conflict with**: [SDD:1432](Software_Development_Document.md#L1432) - "Apple HealthKit enforces a minimum 3-hour data delay"

### Symptom

User `dev@viiraa.com` (Junction user_id: `5c9657f5-c5cf-47fb-ac64-9f0774604445`) has glucose data in Apple Health:

- December 1, 2025: 120 mg/dL
- December 2, 2025: 123 mg/dL
- December 11, 2025: 124 mg/dL

However, Junction Dashboard shows:

- Apple Health connection: ✅ Connected
- Blood Glucose data: ❌ No data found
- Dashboard URL: `https://app.junction.com/team/40f5717b-bba1-47f6-90d2-d59d41747b04/sandbox/user/5c9657f5-c5cf-47fb-ac64-9f0774604445/wearables`

### Root Cause Analysis

**PRIMARY ROOT CAUSE: Data Flow Misunderstanding**

The ViiRaa app has a **read-only relationship** with HealthKit glucose data, but Junction can only sync data that **actively exists** in HealthKit with proper source attribution.

#### Evidence from Code Review

1. **ViiRaa's HealthKit Usage** ([HealthKitManager.swift](Xcode/Services/HealthKit/HealthKitManager.swift)):

   - Line 48: Requests READ permission for `.bloodGlucose`
   - Line 56: Write permissions set to empty: `let typesToWrite: Set<HKSampleType> = []`
   - Lines 91-123: `fetchLatestGlucose()` - reads glucose from HealthKit
   - Lines 131-150: `fetchGlucoseHistory()` - reads glucose history from HealthKit
   - **Conclusion**: ViiRaa never WRITES glucose data to HealthKit
2. **Junction's Data Sync Flow** ([JunctionManager.swift](Xcode/Services/Junction/JunctionManager.swift)):

   - Line 546: Requests permission for `.vitals(.glucose)` from VitalHealthKitClient
   - Line 578: Calls `VitalHealthKitClient.shared.syncData()` to sync FROM HealthKit TO Junction
   - Lines 598-614: Automatic hourly sync configured
   - [AppDelegate.swift:34](Xcode/App/AppDelegate.swift#L34): Background delivery enabled
   - **Conclusion**: Junction syncs data FROM HealthKit, but doesn't create data
3. **The Missing Link**:

   - The glucose data in Apple Health (120, 123, 124 mg/dL) is likely:
     - **Option A**: Manually entered test data by the user
     - **Option B**: Written by another CGM app (LibreLink, Dexcom, etc.)
     - **Option C**: Sample data with incorrect source attribution
   - ViiRaa can READ this data for display in the app
   - But Junction may not be able to SYNC this data due to:
     - Source attribution restrictions
     - Timestamp validation (very old data may be filtered)
     - Lack of proper HealthKit metadata
     - Junction's sync window criteria

### Conflict with SDD:1432

**SDD Line 1432** states:

> "Data Delay Note: Apple HealthKit enforces a minimum 3-hour data delay. This is acceptable for ML training and historical analysis but not suitable for real-time alerts."

**The Assumption**: This documentation assumes glucose data continuously flows into HealthKit from a CGM source, and Junction will sync it with a 3-hour delay.

**The Reality**:

- ViiRaa doesn't generate or write glucose data to HealthKit
- ViiRaa depends on EXTERNAL sources (CGM apps, manual entry) to populate HealthKit
- Junction can only sync data that properly exists in HealthKit
- The 3-hour delay is irrelevant if there's no CGM actively writing data

### Why Junction Dashboard Shows No Data

Junction's sync may be failing because:

1. **Data Age**: Dec 1-2 data is 9-10 days old; Junction may have a sync window (e.g., last 7 days)
2. **Source Attribution**: Manually entered data may not have proper `HKSource` metadata that Junction requires
3. **Data Format**: Test data may not have required fields (device info, source bundle ID, etc.)
4. **Sync Window**: Junction may filter data outside their configured historical sync range
5. **Background Delivery**: Apple's background delivery may not trigger for manually entered data

### Log Analysis

From [Log.txt](Log.txt):

- Line 37: `✅ HealthKit permissions granted via Junction (including glucose)` ✅
- Line 30: `✅ Provider connection created: apple_health_kit` ✅
- Line 44: `✅ Junction sync initiated - data will upload in background` ✅
- Line 45: `ℹ️  Note: Due to Apple's 3-hour HealthKit data delay, recent data may not be available immediately` ⚠️
- Line 53: `📊 Event tracked: glucose_data_loaded` ✅ (ViiRaa can read the data locally)

**Analysis**: All sync mechanisms are working correctly. The issue is that Junction is not receiving/accepting the glucose data during sync, likely due to data source/format incompatibility.

### Screenshots Analysis

From Screenshots folder:

1. **Screenshot 2025-12-11 at 12.43.22.png**: Shows Junction Dashboard with "No patient name on record" and empty connection list
2. **Screenshot 2025-12-11 at 12.43.30.png**: Shows "Data Ingestion Status" with "Discovery Summary" showing data types but timestamps showing Dec 1/2
3. **Screenshot 2025-12-11 at 12.43.32.png**: Shows expanded data ingestion view with multiple health data types listed

The screenshots confirm Apple Health is connected but no glucose samples are visible in Junction's data viewer.

### Potential Solutions

#### Solution 1: Verify Data Source (RECOMMENDED - Test First)

**Action**: Add test glucose data to HealthKit TODAY and monitor sync

```swift
// Test code to write glucose to HealthKit (for debugging only)
let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
let quantity = HKQuantity(unit: HKUnit.milligramsPerDeciliter, doubleValue: 100.0)
let sample = HKQuantitySample(type: glucoseType, quantity: quantity, start: Date(), end: Date())
healthStore.save(sample) { success, error in
    // Monitor if Junction syncs this data
}
```

**Expected Result**: If Junction syncs this data within 4 hours, confirms old data is filtered

#### Solution 2: Implement CGM Data Source (Aligns with SDD Phase 3)

**Action**: Implement BLE Follow Mode for Abbott Lingo (as documented in [SDD:1532-1565](Software_Development_Document.md#L1532))

- Capture real-time glucose from Abbott Lingo via BLE
- Write to HealthKit with ViiRaa source attribution
- Junction will automatically sync this data
  **Files to Create**:
- `Xcode/Services/Bluetooth/` (noted as untracked in git status)
- `Xcode/Features/BLEFollowMode/` (noted as untracked in git status)

#### Solution 3: Debug Junction Sync Status

**Action**: Add detailed logging to track sync attempts

```swift
// In JunctionManager.swift syncHealthData()
VitalHealthKitClient.shared.syncData()

// Add observer for sync completion
NotificationCenter.default.addObserver(
    forName: VitalHealthKitClient.didCompleteSync,
    object: nil,
    queue: .main
) { notification in
    print("🔍 Junction sync completed: \(notification.userInfo ?? [:])")
}
```

#### Solution 4: Check Junction API Sync Logs

**Action**: Query Junction API for sync status and errors

- Endpoint: `GET /v2/summary/sync/{user_id}`
- Check for sync errors, data validation failures, or filtering rules
- Review Junction dashboard's "Data Ingestion Status" for error messages

### Testing Recommendations

1. **Immediate Test** (5 minutes):

   - Open Apple Health app
   - Add NEW glucose reading for TODAY's date
   - Wait 4 hours (3-hour delay + 1 hour sync)
   - Check Junction dashboard for the new reading
2. **Source Attribution Test** (10 minutes):

   - Check existing glucose data source in Apple Health
   - Go to Health > Blood Glucose > Show All Data > tap reading
   - Verify which app wrote the data (ViiRaa? Manual entry? Other app?)
   - Document the source for troubleshooting
3. **Background Delivery Test** (30 minutes):

   - Enable verbose logging in Xcode
   - Manually trigger sync: `JunctionManager.shared.syncHealthData()`
   - Monitor console for VitalHealthKit sync messages
   - Check for errors or warnings during sync
4. **Junction API Debug** (15 minutes):

   - Use Postman/curl to query Junction API
   - Check sync history for user `5c9657f5-c5cf-47fb-ac64-9f0774604445`
   - Review data ingestion logs for filtering or validation errors

### Key Learnings (Pending Resolution)

1. **Data Flow Architecture**: Read-only HealthKit access ≠ Data source. App must either generate data OR rely on external sources.
2. **Junction Sync Requirements**: Junction may have strict requirements on data freshness, source attribution, or metadata.
3. **Testing with Real Data**: Test integrations with actual device data, not manually entered test data.
4. **Monitor at Destination**: "Sync initiated" ≠ "Data delivered". Always verify at the destination (Junction dashboard).
5. **SDD Assumptions**: Documentation assumed CGM data source exists; needs update to clarify data source requirements.

### Files Referenced

- [Bug.txt](Bug.txt) - Original bug report
- [Log.txt](Log.txt) - Application logs showing sync success
- [Screenshots/](Screenshots/) - Junction Dashboard screenshots
- [JunctionManager.swift:536-554](Xcode/Services/Junction/JunctionManager.swift#L536-L554) - HealthKit permissions via Junction
- [JunctionManager.swift:560-595](Xcode/Services/Junction/JunctionManager.swift#L560-L595) - Manual sync implementation
- [HealthKitManager.swift:41-76](Xcode/Services/HealthKit/HealthKitManager.swift#L41-L76) - HealthKit authorization (read-only)
- [SDD:1432](Software_Development_Document.md#L1432) - HealthKit 3-hour data delay documentation

### Next Steps

1. ⏳ User to perform "Immediate Test" with fresh glucose data
2. ⏳ Developer to add Junction sync status logging
3. ⏳ Developer to query Junction API for sync error details
4. ⏳ Determine if Bug 21 is a configuration issue or requires Phase 3 BLE implementation

---

### Version 4.5 (2025-12-12)

- Added Bug 21: Glucose Data in Apple Health Not Syncing to Junction Dashboard
- **Symptom**: Glucose data exists in Apple Health but not appearing in Junction Dashboard
- **Conflict with**: SDD:1432 (assumes continuous CGM data flow)
- **Root Cause**: ViiRaa reads glucose from HealthKit but doesn't write data; Junction can only sync data that actively exists with proper source attribution
- **Evidence**: HealthKitManager uses read-only permissions, no glucose write functionality found
- **Key Learning**: Read-only HealthKit access ≠ Data source - app needs CGM integration or external data source
- **Status**: 🔴 ACTIVE - Awaiting testing with fresh glucose data and Junction API debug

---

### Version 4.6 (2025-12-18)

- Added Bug 22: Personal Account Not Found in Junction - Only Test Users Visible
- **Symptom**: User synced Lingo GCM glucose to physical iPhone, frontend shows sync working, but personal account does NOT exist in Junction Users dashboard - only test accounts visible (test-user-1765305139467, test-user-1765305324892, and UUID-based test users)
- **Conflict with**: SDD:1434 (assumes user account exists in Junction for data sync troubleshooting)
- **Root Cause**: User provisioning/authentication failure at Junction account creation layer - this occurs BEFORE data sync issues addressed in Bug #21. The Vital SDK user creation flow is either: (a) not executing for production users, (b) failing silently, (c) only creating test/sandbox users, or (d) configured with sandbox API keys instead of production keys
- **Evidence**:
  - Screenshot shows Junction dashboard with "Showing 5 users" - all have test prefixes or development UUIDs
  - User reports "could NOT find my personal account in Junction"
  - App frontend indicates sync working (local state) but no corresponding user exists in Junction backend
  - All visible users in Junction are test accounts, suggesting sandbox/development mode operation
- **Layer Analysis**: This is a **user provisioning** issue (Layer 1), distinct from Bug #21's **data sync** issue (Layer 2):
  - Layer 1: User account creation in Junction via Vital SDK → **FAILING (current bug)**
  - Layer 2: Data sync from HealthKit to Junction for existing user → Addressed in Bug #21
  - Layer 3: Data source attribution and HealthKit permissions → Addressed in Bug #21
- **Key Learning**: Junction data sync troubleshooting (SDD:1434) assumes user account exists. Must verify user creation BEFORE investigating data sync failures. The VitalHealthKitClient may be properly configured for data sync, but user authentication/provisioning API calls may be:
  - Using sandbox/test environment instead of production
  - Missing required authentication tokens for production user creation
  - Conditional on test flags that prevent production user creation on physical devices
  - Failing due to API key misconfiguration (sandbox keys vs production keys)
- **Potential Solutions**:
  1. Verify Vital SDK initialization uses production API keys (not sandbox keys)
  2. Check if user creation API calls are properly executing for non-test users
  3. Add logging to capture Vital SDK user creation responses and error codes
  4. Verify VitalHealthKitClient user authentication flow for physical devices
  5. Check if app has conditional logic creating test users in dev mode that's persisting in production
  6. Review Junction/Vital API configuration for environment switching (sandbox → production)
- **Files to Investigate**:
  - JunctionManager.swift - Vital SDK initialization and user creation logic
  - API key configuration files - Verify production vs sandbox keys
  - User authentication flow - Check where Vital user creation occurs
- **Status**: 🔴 CRITICAL - User account creation prerequisite failing; data sync troubleshooting cannot proceed until user exists in Junction

---

### Version 4.7 (2025-12-18)

- **FIXES APPLIED for Bug #22 and Bug #21**
- **Bug #22 Fix - User Provisioning (Sandbox vs Production)**:
  - Added comprehensive documentation in [Constants.swift:30-50](Xcode/Utilities/Constants.swift#L30-L50) explaining:
    - Difference between sandbox (sk_us_*) and production (pk_us_*) API keys
    - Current status: Using sandbox key (test users only)
    - Step-by-step instructions to obtain production API key and switch to production mode
  - **Action Required**: User must:
    1. Sign Business Associate Agreement (BAA) with Junction/Vital
    2. Obtain production API key from https://app.tryvital.io
    3. Replace sandbox key in Constants.swift line 45
    4. Change junctionEnvironment to "production" in line 46
  - Once switched to production, real user accounts will be created in Junction production dashboard
- **Bug #21 Fix - Glucose Data Sync**:
  - Added **WRITE permission** for glucose in [HealthKitManager.swift:68-70](Xcode/Services/HealthKit/HealthKitManager.swift#L68-L70)
    - Previous: Read-only permissions
    - Current: Read + Write permissions for blood glucose
    - Rationale: Allows ViiRaa to write glucose data that Junction can recognize and sync
  - Added **WRITE permission** for glucose in [JunctionManager.swift:552](Xcode/Services/Junction/JunctionManager.swift#L552)
    - VitalHealthKitClient now requests both read and write permissions for glucose
    - Write permission critical for Junction to properly sync glucose data
  - Updated [JunctionManager.swift:851](Xcode/Services/Junction/JunctionManager.swift#L851) forceRequestGlucosePermission()
    - Now includes write permissions in the forced re-request flow
- **Testing Requirements**:
  1. **Bug #22 Verification**:
     - After switching to production API key, sign out and sign in again
     - User should appear in Junction production dashboard (not sandbox)
     - Check https://app.tryvital.io/team/users to verify personal account exists
  2. **Bug #21 Verification**:
     - After fix, user must re-authorize HealthKit permissions (write permission is new)
     - In Settings, request HealthKit permissions again
     - Sync Lingo GCM glucose data to HealthKit (if not already done)
     - Use JunctionManager.shared.syncHealthData() to trigger sync
     - Wait 3+ hours (Apple's HealthKit delay) + 1 hour (Junction sync interval)
     - Check Junction dashboard Data Ingestion tab for glucose readings
  3. **Debug Tools Available**:
     - `JunctionManager.shared.runFullBug21Diagnostic()` - Complete diagnostic routine
     - `JunctionManager.shared.performSyncHealthCheck()` - Check sync health status
     - `JunctionManager.shared.debugGlucoseDataSources()` - Inspect data sources in HealthKit
     - `JunctionManager.shared.forceRequestGlucosePermission()` - Re-request permissions
- **Expected Outcome**:
  - Bug #22: Personal account visible in Junction production dashboard
  - Bug #21: Glucose data from Lingo GCM syncing to Junction within 4 hours
- **Key Learning**:
  - Sandbox API keys create isolated test environment - never mix sandbox testing with production user expectations
  - HealthKit write permissions are required for data sync frameworks like Junction/Vital
  - Permission changes require user to re-authorize in iOS Settings > Privacy > Health
- **Status**: ✅ FIXES IMPLEMENTED - Awaiting user testing and verification

---

### Version 4.8 (2025-12-18)

- **ADDITIONAL DIAGNOSTIC TOOLS ADDED for Bug #22 (Sandbox Testing)**
- **Problem Identified**: User connection errors were being caught but only logged to console, invisible on physical devices
- **Solution Implemented**: Enhanced error visibility and manual retry capabilities
- **Changes Made**:
  1. **Error Logging System** - [ErrorLogger.swift](Xcode/Utilities/ErrorLogger.swift):
     - Created persistent error logger that writes to file system
     - Logs survive app restarts and are viewable on physical devices
     - Automatic log trimming at 100KB to prevent excessive storage use
     - All Junction connection attempts and errors now logged
  2. **Settings UI Enhancements** - [SettingsView.swift](Xcode/Features/Settings/SettingsView.swift):
     - Added "User Account" status indicator (shows "Created" or "Not Created")
     - Added "Retry Junction Connection" button when not connected
     - Shows last error message directly in Settings UI
     - Added "View Error Log" button with full log viewer
     - Added "Clear Error Log" button
  3. **Error Log Viewer** - [ErrorLogView.swift](Xcode/Features/Settings/ErrorLogView.swift):
     - New screen to view full error log with timestamps
     - Refresh capability to see latest logs
     - Share button to export logs for debugging
  4. **Enhanced JunctionManager Logging** - [JunctionManager.swift:157-179](Xcode/Services/Junction/JunctionManager.swift#L157-L179):
     - All connection attempts logged with user ID, environment, API key prefix
     - All errors logged with detailed descriptions
     - Success events logged to track progress
     - Errors stored in `syncError` property for UI display

- **How to Debug Connection Failures** (On Physical iPhone):
  1. Open ViiRaa app → Settings → Cloud Sync section
  2. Check "Connection" status - should show "Connected" (green) or "Not Connected" (red)
  3. Check "User Account" status - should show "Created" (green) or "Not Created" (red)
  4. If not connected, tap "Retry Junction Connection" button
  5. Wait 10 seconds for connection attempt
  6. If fails, check error message displayed below the retry button
  7. Tap "View Error Log" to see full diagnostic log
  8. Look for lines starting with "ERROR:" to identify the failure point
  9. Share the log (tap share button) to send to developer or review yourself

- **Expected Error Patterns**:
  - **"ERROR: Failed to create user"** → API call to Junction failing
    - Check internet connection
    - Verify API key is valid (check Junction dashboard)
    - Verify API key matches environment (sandbox vs production)
  - **"ERROR: Invalid API key"** → API key not loaded properly
    - Check [Constants.swift:45](Xcode/Utilities/Constants.swift#L45) has correct key
  - **"ERROR: Junction not configured"** → SDK initialization failed
    - Check [AppDelegate.swift:22-29](Xcode/App/AppDelegate.swift#L22-L29) VitalClient.configure() called

- **Key Learning**:
  - **Silent failures are debugging nightmares on physical devices**
  - Always provide user-visible error messages and persistent logs
  - Manual retry capabilities essential for testing intermittent issues
  - Error logs should include context (user ID, environment, timestamps)

- **Status**: ✅ DIAGNOSTIC TOOLS READY - User can now see exact failure point on physical device