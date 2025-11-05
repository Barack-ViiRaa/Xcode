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

2.1. **Incomplete Session Injection**: The iOS app was injecting only the `access_token` as a simple string into localStorage, but Supabase's web client requires a complete session object with multiple properties.

2.2. **Incorrect localStorage Key**: The session was being stored with a generic key like `supabase.auth.token` instead of the Supabase-specific format `sb-{project-id}-auth-token`.

2.3. **Missing Session Properties**: The injected data lacked critical properties that Supabase expects: `refresh_token`, `expires_in`, `token_type`, and `user` object with `id`, `email`, `aud`, and `role`.

2.4. **Wrong Data Type**: Instead of passing the complete `Session` object to WebView, only the `authToken: String?` was being passed, losing all other session information.

2.5. **No JavaScript Event Notification**: After injection, there was no event dispatched to notify the web app that authentication was ready, so the Supabase client might have already checked for auth before the injection completed.

### 3. What was the solution

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

### 4. What are the learnings for potential future bugs

4.1. **Understand Third-Party Session Formats**: When integrating with third-party auth providers like Supabase, Firebase, or Auth0, always verify the exact session data structure and localStorage format they expect. Don't assume a simple token string is sufficient.

4.2. **WebView Session Injection Pattern**: For WebView apps that share authentication with native iOS, the pattern is: (1) Pass complete session object to WebView, (2) Inject before and after page load, (3) Use correct storage keys, (4) Dispatch events to notify web code.

4.3. **localStorage Key Formats Matter**: Many auth SDKs use project-specific or environment-specific localStorage keys. The key format `sb-{project-id}-auth-token` is not arbitrary - it's how the SDK locates the session data.

4.4. **Session Object Completeness**: A session isn't just an access token. Modern auth systems require refresh tokens, expiration times, token types, and user metadata. Omitting any of these can cause silent failures or degraded functionality.

4.5. **Dual Injection Strategy**: Injecting only before or only after page load is insufficient. Web apps may check auth at different lifecycle points, so injecting at both document start and after load ensures the session is available whenever the web app checks.

4.6. **Event-Driven Auth Notification**: Don't assume the web app will poll for auth state. Dispatch custom events (`ios-auth-ready`) and standard events (`storage`) to proactively notify the web code that authentication state has changed.

4.7. **Test Session Structure Match**: Use browser dev tools to inspect what the web version stores in localStorage after authentication, then ensure the iOS injection matches that exact structure. Any mismatch will cause the web SDK to ignore the injected session.

4.8. **Escape All JavaScript Strings**: When injecting JavaScript code with user data (tokens, emails), always escape special characters to prevent XSS vulnerabilities and JavaScript syntax errors. Use `replacingOccurrences(of: "'", with: "\\'")`.

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

### Version 2.2 (2025-10-27)
- Added Bug 11: Provisioning Profile Not Found for Archive Build
- Documented code signing configuration requirements for distribution
- Clarified device registration requirements for different distribution methods

### Version 2.1 (2025-10-21)
- Added Bug 9: Generic Type Inference Issues with PostgrestResponse
- Added Bug 10: RPC Method Signature Changes in Supabase SDK
- Documented generic type parameter requirements and builder pattern variations
- Added learnings about Encodable constraints and API version compatibility

### Version 2.0 (2025-10-20)
- Added Bug 6: Authentication State Loading Screen Issue
- Added Bug 7: Double Login Requirement (Session Sharing Failure)
- Added Bug 8: Simplified Sign Out Architecture
- Updated Summary of Key Patterns to include authentication and session management patterns

### Version 1.0 (2025-10-15)
- Initial documentation with Bugs 1-5
- Covered SDK integration, SwiftUI concurrency, project configuration, and API compatibility issues
