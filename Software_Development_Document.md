# Software Development Documentation

## ViiRaa iOS Mobile Application

---

## Document Information

- **Version**: 1.9
- **Last Updated**: 2025-12-16
- **Product**: ViiRaa iOS Mobile Application
- **Status**: Updated with Bug #21 Root Cause Analysis (Junction Sync) - December 2025
- **Related Documents**: [Product Requirements Document.md](./Product%20Requirements%20Document.md)
- **Reference Code**: [viiraalanding-main](./viiraalanding-main)

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Requirements Summary](#2-requirements-summary)
3. [Architecture &amp; Design](#3-architecture--design)
4. [Technical Implementation](#4-technical-implementation)
5. [Security &amp; Privacy](#5-security--privacy)
6. [Development Workflow](#6-development-workflow)
7. [Testing Strategy](#7-testing-strategy)
8. [Deployment &amp; Release](#8-deployment--release)
9. [Appendices](#9-appendices)

---

## 1. System Overview

### 1.1 Executive Summary

ViiRaa iOS app is a native mobile application that wraps the existing web dashboard experience using WKWebView technology, enhanced with Apple HealthKit integration for critical glucose metrics. The app follows an MVP deployment strategy:

- **Immediate Goal (MVP)**: Submit minimum viable version to both TestFlight and App Store

  - TestFlight: Internal testing with Lei (zl.stone1992@gmail.com) and team
  - App Store: Submit to identify any gaps for approval
- **Key Features (MVP)**:

  - WebView-based dashboard with native iOS shell
  - HealthKit integration emphasizing:
    1. **Time In Range** - Critical metric for weight loss (large font display)
    2. **Peak Glucose** - Most damaging metric (prominent warning display)
  - Native authentication with secure Keychain storage

This MVP approach allows us to quickly validate with App Store requirements while gathering feedback through TestFlight for future enhancements.

### 1.2 Technology Stack

#### Native iOS Layer

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (preferred) or UIKit
- **Minimum iOS Version**: iOS 15.0
- **Target Devices**: iPhone (primary), iPad (compatible)
- **Xcode Version**: 14.0+

#### Runtime Environtment

- **MacOS Version**: 26.0.1 (25A362)
- **Xcode Version**: Version 26.0.1 (17A400)
- **Simulator Hardware Version**: iPhone 17
- **Simulator Software Version**: iOS 26.0 (23A343)

#### Web Integration Layer

- **WebView**: WKWebView (Apple's modern web rendering engine)
- **JavaScript Bridge**: WKScriptMessageHandler for native-web communication
- **Cookie Management**: WKHTTPCookieStore for authentication persistence

#### Backend Integration

- **Authentication**: Supabase Auth (OAuth + Email/Password)
- **Database**: Supabase PostgreSQL
- **API**: Node.js backend (viiraa-mvp-backend on Railway)
- **Analytics**: PostHog (web + mobile unified tracking)

#### Native iOS Features

- **Storage**: Keychain Services for secure token storage
- **HealthKit**: Apple HealthKit framework (Phase 2)
- **Push Notifications**: APNs infrastructure (Future phase)

#### Third-Party Health Data Integration (Phase 2)

- **Junction SDK**: Vital Mobile SDK for unified health data access
  - Supports 300+ health devices including CGM systems
  - Enables automated HealthKit data sync to Junction cloud
  - HIPAA-compliant cloud storage for ML model training
  - Reference: `/Users/barack/Downloads/Xcode/3rd_Party_Bio_Data_Integration_Report.md`

---

## 2. Requirements Summary

### 2.1 Functional Requirements

#### Phase 1: TestFlight MVP

| ID     | Requirement                                         | Priority  | Status  |
| ------ | --------------------------------------------------- | --------- | ------- |
| FR-1.1 | Native iOS app shell with tab navigation            | Must-have | Pending |
| FR-1.2 | WebView integration loading `/dashboard` route    | Must-have | Pending |
| FR-1.3 | User authentication (Google OAuth + Email/Password) | Must-have | Pending |
| FR-1.4 | Secure session management with Keychain storage     | Must-have | Pending |
| FR-1.5 | Dashboard Tab displaying full user dashboard        | Must-have | Pending |
| FR-1.6 | Chat Tab with WhatsApp redirect (interim solution)  | Must-have | Pending |
| FR-1.7 | TestFlight deployment for internal team             | Must-have | Pending |

#### Phase 2: App Store Submission

| ID      | Requirement                                                | Priority | Status      |
| ------- | ---------------------------------------------------------- | -------- | ----------- |
| FR-2.1  | Apple HealthKit integration (CGM data read)                | Critical | ✅ Complete |
| FR-2.2  | HealthKit integration (Weight data read)                   | Critical | ✅ Complete |
| FR-2.3  | HealthKit integration (Activity data read)                 | Critical | ✅ Complete |
| FR-2.4  | Native glucose data display view with charts               | Critical | ✅ Complete |
| FR-2.5  | Glucose statistics and analytics                           | Critical | ✅ Complete |
| FR-2.6  | Settings screen with HealthKit permissions management      | Critical | Pending     |
| FR-2.7  | Fix HealthKit "Access denied" bug when permissions granted | Critical | Pending     |
| FR-2.8  | App Store metadata and screenshots                         | Critical | Pending     |
| FR-2.9  | Privacy policy and HealthKit usage descriptions            | Critical | Pending     |
| FR-2.10 | Fix Google Sign-In crash bug                               | Critical | Pending     |
| FR-2.11 | Fix duplicate login prompts (SSO implementation)           | Critical | Pending     |
| FR-2.12 | Update app branding with square logo                       | Critical | Pending     |
| FR-2.13 | Junction SDK Integration for bio data sync                 | Critical | Pending     |
| FR-2.14 | Glucose Prediction Feature (WebView integration)           | Critical | ✅ Complete |

#### Phase 3: BLE Follow Mode (Optional)

| ID     | Requirement                                          | Priority | Status  |
| ------ | ---------------------------------------------------- | -------- | ------- |
| FR-3.1 | BLE Follow Mode for real-time glucose (Abbott Lingo) | Optional | Pending |
| FR-3.2 | BLE settings UI with connection status               | Optional | Pending |
| FR-3.3 | Dual-app setup guide and onboarding                  | Optional | Pending |
| FR-3.4 | Data validation between BLE and Junction sources     | Optional | Pending |
| FR-3.5 | Feature flag for gradual BLE rollout                 | Optional | Pending |

#### Future Phases

| ID     | Requirement                              | Priority | Status |
| ------ | ---------------------------------------- | -------- | ------ |
| FR-4.1 | miniViiRaa AI coach chat integration     | High     | Future |
| FR-4.2 | Push notifications for engagement        | High     | Future |
| FR-4.3 | Offline functionality                    | Medium   | Future |
| FR-4.4 | Native UI components (gradual migration) | Medium   | Future |

### 2.2 Non-Functional Requirements

#### Performance

- **Launch Time**: App launch to dashboard display < 3 seconds
- **WebView Load Time**: Initial dashboard load < 2 seconds (on good network)
- **Memory Usage**: < 150MB under normal usage
- **Crash-Free Rate**: > 99%

#### Security

- **Token Storage**: All authentication tokens stored in iOS Keychain
- **HTTPS Only**: All network communication over HTTPS
- **Certificate Pinning**: Consider for production (optional enhancement)
- **Data Encryption**: Sensitive data encrypted at rest and in transit

#### Compatibility

- **iOS Versions**: iOS 14.0+ (covers ~95% of active devices)
- **Devices**: iPhone 8 and newer (primary), iPad support (compatible)
- **Orientations**: Portrait (primary), Landscape (supported)
- **Accessibility**: VoiceOver support, Dynamic Type support

#### Compliance

- **Apple Guidelines**:
  - 4.2 (Minimum Functionality) - Addressed with HealthKit
  - 2.5.2 (Software Requirements) - Native iOS APIs
  - 5.1.1 (Privacy - Data Collection) - Proper privacy policy
- **HIPAA Considerations**: Health data handling best practices
- **GDPR Compliance**: User data privacy and consent

---

## 3. Architecture & Design

### 3.1 High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ViiRaa iOS Native App                    │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              App Entry Point (App.swift)               │  │
│  │  - App initialization                                  │  │
│  │  - Environment setup                                   │  │
│  │  - Analytics initialization (PostHog)                  │  │
│  └────────────────────┬───────────────────────────────────┘  │
│                       │                                       │
│  ┌────────────────────▼───────────────────────────────────┐  │
│  │           Main Navigation (TabView)                    │  │
│  │  ┌──────────────────┐  ┌──────────────────────────┐   │  │
│  │  │  Dashboard Tab   │  │     Chat Tab (Phase 2)   │   │  │
│  │  └────────┬─────────┘  └──────────────────────────┘   │  │
│  └───────────┼────────────────────────────────────────────┘  │
│              │                                               │
│  ┌───────────▼────────────────────────────────────────────┐  │
│  │         Dashboard View Controller                      │  │
│  │  - WKWebView container                                 │  │
│  │  - Navigation delegate                                 │  │
│  │  - JavaScript bridge handler                           │  │
│  └───────────┬────────────────────────────────────────────┘  │
│              │                                               │
│  ┌───────────▼────────────────────────────────────────────┐  │
│  │           Authentication Manager                       │  │
│  │  - Supabase Auth SDK integration                       │  │
│  │  - Keychain token management                           │  │
│  │  - Session lifecycle handling                          │  │
│  └───────────┬────────────────────────────────────────────┘  │
│              │                                               │
│  ┌───────────▼────────────────────────────────────────────┐  │
│  │         HealthKit Manager (Phase 2)                    │  │
│  │  - Permission requests                                 │  │
│  │  - Data read/write operations                          │  │
│  │  - Background sync                                     │  │
│  └────────────────────────────────────────────────────────┘  │
└───────────────────────┬───────────────────────────────────────┘
                        │
                        │ HTTPS
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              ViiRaa Web Infrastructure                       │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │          React Web Dashboard (Vite + React 18)         │  │
│  │  - /dashboard route (main user interface)              │  │
│  │  - shadcn/ui components                                │  │
│  │  - Responsive design (mobile-optimized)                │  │
│  └────────────────────┬───────────────────────────────────┘  │
│                       │                                       │
│  ┌────────────────────▼───────────────────────────────────┐  │
│  │            Supabase Backend Services                   │  │
│  │  - Authentication (auth.users)                         │  │
│  │  - Database (public.users, orders, cohorts)            │  │
│  │  - Edge Functions (get-config)                         │  │
│  └────────────────────┬───────────────────────────────────┘  │
│                       │                                       │
│  ┌────────────────────▼───────────────────────────────────┐  │
│  │       Node.js Backend API (Railway/ngrok)              │  │
│  │  - /api/payment/create-checkout-session                │  │
│  │  - Business logic and validation                       │  │
│  │  - Stripe integration                                  │  │
│  └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Application Structure

```
ViiRaaApp/
├── ViiRaaApp/
│   ├── App/
│   │   ├── ViiRaaApp.swift              # Main app entry point
│   │   ├── AppDelegate.swift            # App lifecycle (if needed)
│   │   └── SceneDelegate.swift          # Scene lifecycle (if needed)
│   │
│   ├── Core/
│   │   ├── Navigation/
│   │   │   ├── MainTabView.swift        # Tab navigation container
│   │   │   └── TabItem.swift            # Tab configuration
│   │   │
│   │   ├── WebView/
│   │   │   ├── DashboardWebView.swift   # WKWebView wrapper
│   │   │   ├── WebViewCoordinator.swift # Navigation delegate
│   │   │   └── JavaScriptBridge.swift   # JS <-> Native bridge
│   │   │
│   │   └── Authentication/
│   │       ├── AuthManager.swift        # Auth state management
│   │       ├── SupabaseClient.swift     # Supabase SDK wrapper
│   │       ├── KeychainManager.swift    # Secure token storage
│   │       └── AuthView.swift           # Native auth UI (fallback)
│   │
│   ├── Features/
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift      # Main dashboard screen
│   │   │   └── DashboardViewModel.swift # Dashboard logic
│   │   │
│   │   ├── Chat/
│   │   │   ├── ChatView.swift           # Chat placeholder (Phase 1)
│   │   │   └── ChatViewModel.swift      # Chat logic (Phase 2)
│   │   │
│   │   └── Profile/
│   │       └── ProfileView.swift        # Native profile (future)
│   │
│   ├── Services/
│   │   ├── HealthKit/
│   │   │   ├── HealthKitManager.swift   # HealthKit operations
│   │   │   └── HealthDataModels.swift   # Health data structures
│   │   │
│   │   ├── Analytics/
│   │   │   └── AnalyticsManager.swift   # PostHog integration
│   │   │
│   │   └── Network/
│   │       ├── NetworkManager.swift     # API client
│   │       └── APIEndpoints.swift       # Endpoint definitions
│   │
│   ├── Models/
│   │   ├── User.swift                   # User data model
│   │   ├── Session.swift                # Session data model
│   │   └── HealthData.swift             # Health data models
│   │
│   ├── Utilities/
│   │   ├── Constants.swift              # App constants
│   │   ├── Extensions/                  # Swift extensions
│   │   │   ├── String+Extensions.swift
│   │   │   ├── View+Extensions.swift
│   │   │   └── Date+Extensions.swift
│   │   └── Helpers/
│   │       └── Logger.swift             # Logging utility
│   │
│   └── Resources/
│       ├── Assets.xcassets              # Images, colors, icons
│       ├── Info.plist                   # App configuration
│       └── Localizable.strings          # Localization (future)
│
├── ViiRaaAppTests/
│   ├── AuthManagerTests.swift
│   ├── WebViewTests.swift
│   └── HealthKitManagerTests.swift
│
├── ViiRaaAppUITests/
│   └── UITests.swift
│
└── Podfile / Package.swift              # Dependency management
```

### 3.3 Data Flow Diagrams

#### Authentication Flow

```
┌─────────────┐
│   User      │
└──────┬──────┘
       │
       ▼
┌──────────────────────────────────────┐
│  1. Launch App                       │
│  Check Keychain for saved session    │
└──────┬───────────────────────────────┘
       │
       ├─── Session Found ────┐
       │                      │
       │                      ▼
       │            ┌─────────────────────┐
       │            │  3. Load Dashboard  │
       │            │  Pass token to      │
       │            │  WebView via JS     │
       │            └─────────────────────┘
       │
       └─── No Session ───┐
                          │
                          ▼
              ┌───────────────────────────┐
              │  2. Show Auth View        │
              │  Options:                 │
              │  - Sign in with Google    │
              │  - Sign in with Email     │
              │  - Sign up                │
              └───────┬───────────────────┘
                      │
                      ▼
              ┌───────────────────────────┐
              │  3. Authenticate via      │
              │  Supabase SDK             │
              │  - OAuth flow (Google)    │
              │  - Email/Password         │
              └───────┬───────────────────┘
                      │
                      ▼
              ┌───────────────────────────┐
              │  4. Receive Session Token │
              │  Store in Keychain        │
              └───────┬───────────────────┘
                      │
                      ▼
              ┌───────────────────────────┐
              │  5. Navigate to Dashboard │
              │  Load WebView with token  │
              └───────────────────────────┘
```

#### WebView Communication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      Native App Layer                        │
└────────────┬────────────────────────────────────────────────┘
             │
             │ 1. Inject Auth Token
             │    JavaScript: window.setAuthToken(token)
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    WKWebView Container                       │
│                                                               │
│  Note: Sign-out is handled within the web interface.         │
│  Web dashboard manages authentication state and sends        │
│  "logout" message to iOS when user signs out.                │
│                                                               │
│  window.webkit.messageHandlers.nativeApp.postMessage({       │
│    type: 'logout'                                            │
│  })                                                          │
│                                                               │
│  window.webkit.messageHandlers.nativeApp.postMessage({       │
│    type: 'navigate',                                         │
│    payload: { url: '/dashboard' }                            │
│  })                                                          │
└────────────┬────────────────────────────────────────────────┘
             │
             │ 2. Message from Web
             │    Handled by WKScriptMessageHandler
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│              JavaScriptBridge.swift                          │
│  func userContentController(                                 │
│    _ controller: WKUserContentController,                    │
│    didReceive message: WKScriptMessage                       │
│  )                                                           │
└────────────┬────────────────────────────────────────────────┘
             │
             │ 3. Process Message
             │    - logout: Call AuthManager.shared.signOut()
             │    - navigate: Handle deep link
             │    - analytics: Forward to PostHog
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                   Native Action Handler                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Technical Implementation

### 4.1 Core Components Implementation

#### 4.1.1 Main App Entry Point (ViiRaaApp.swift)

```swift
import SwiftUI

@main
struct ViiRaaApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var analyticsManager = AnalyticsManager.shared

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(analyticsManager)
            } else {
                AuthView()
                    .environmentObject(authManager)
            }
        }
    }

    init() {
        setupApp()
    }

    private func setupApp() {
        // Initialize Supabase
        SupabaseClient.shared.initialize()

        // Initialize PostHog Analytics
        AnalyticsManager.shared.initialize()

        // Configure appearance
        configureAppearance()
    }

    private func configureAppearance() {
        // Set app-wide UI appearance
        UITabBar.appearance().backgroundColor = .systemBackground
    }
}
```

#### 4.1.2 Authentication Manager (AuthManager.swift)

```swift
import Foundation
import Combine
import Supabase

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var user: User?
    @Published var session: Session?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true

    private let supabase = SupabaseClient.shared
    private let keychain = KeychainManager.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupAuthStateListener()
        checkExistingSession()
    }

    private func setupAuthStateListener() {
        // Listen to auth state changes from Supabase
        NotificationCenter.default.publisher(for: .supabaseAuthStateChanged)
            .sink { [weak self] notification in
                guard let self = self else { return }
                self.handleAuthStateChange(notification)
            }
            .store(in: &cancellables)
    }

    private func checkExistingSession() {
        Task {
            do {
                // Check keychain for stored session
                if let sessionData = keychain.getSessionData(),
                   let session = try? JSONDecoder().decode(Session.self, from: sessionData) {

                    // Validate session with Supabase
                    let user = try await supabase.auth.user(jwt: session.accessToken)

                    self.session = session
                    self.user = user
                    self.isAuthenticated = true
                }
            } catch {
                print("Session validation failed: \(error)")
                await clearSession()
            }

            self.isLoading = false
        }
    }

    func signInWithGoogle() async throws {
        // Launch Google OAuth flow
        let session = try await supabase.auth.signInWithOAuth(provider: .google)
        await handleSuccessfulAuth(session: session)
    }

    func signInWithPassword(email: String, password: String) async throws {
        let session = try await supabase.auth.signIn(email: email, password: password)
        await handleSuccessfulAuth(session: session)
    }

    func signUp(email: String, password: String) async throws {
        let session = try await supabase.auth.signUp(email: email, password: password)
        await handleSuccessfulAuth(session: session)
    }

    // Called by WebView when user signs out via web interface
    func signOut() async throws {
        try await supabase.auth.signOut()
        await clearSession()
    }

    private func handleSuccessfulAuth(session: Session) async {
        // Store session in keychain
        if let sessionData = try? JSONEncoder().encode(session) {
            keychain.saveSessionData(sessionData)
        }

        self.session = session
        self.user = session.user
        self.isAuthenticated = true

        // Track sign-in event
        AnalyticsManager.shared.track(event: "user_signed_in", properties: [
            "method": "email" // or "google"
        ])
    }

    private func clearSession() async {
        keychain.clearSessionData()
        self.session = nil
        self.user = nil
        self.isAuthenticated = false
    }
}
```

#### 4.1.3 Keychain Manager (KeychainManager.swift)

```swift
import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()

    private let serviceName = "com.viiraa.app"
    private let sessionKey = "userSession"

    private init() {}

    func saveSessionData(_ data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: sessionKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            print("Keychain save error: \(status)")
        }
    }

    func getSessionData() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: sessionKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as? Data
        }

        return nil
    }

    func clearSessionData() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: sessionKey
        ]

        SecItemDelete(query as CFDictionary)
    }
}
```

#### 4.1.3.1 Session Management & Single Sign-On

**Critical Implementation Requirement**: The iOS app must share the complete Supabase session with the WebView to prevent double login.

**Problem**: After user authenticates via iOS native login, the web dashboard loaded in WebView doesn't have access to the authentication session, causing it to show a login screen again.

**Solution**: Inject complete Supabase session into WebView's localStorage

**Session Data Structure**:

```typescript
{
  access_token: string,      // JWT access token
  refresh_token: string,     // Refresh token for session renewal
  expires_in: number,        // Token expiration time in seconds
  token_type: string,        // Token type (typically "bearer")
  user: {
    id: string,              // User UUID
    email: string,           // User email
    aud: "authenticated",    // Audience claim
    role: "authenticated"    // User role
  }
}
```

**localStorage Key Format**: `sb-{supabase-project-id}-auth-token`

**Implementation Points**:

1. **Before Page Load**: Inject session via `WKUserScript` at `.atDocumentStart`
2. **After Page Load**: Re-inject via `evaluateJavaScript` to ensure persistence
3. **String Escaping**: All token strings must be escaped for safe JavaScript injection
4. **Event Notification**: Dispatch custom `ios-auth-ready` event to notify web app
5. **Global Flags**: Set `window.iosAuthenticated` and `window.iosSession` for detection

**Security Considerations**:

- Tokens stored securely in iOS Keychain
- JavaScript injection properly escaped to prevent XSS
- Session refresh handled automatically by Supabase client
- No plaintext token storage in UserDefaults

#### 4.1.4 Dashboard WebView (DashboardWebView.swift)

**Updated Implementation with Session Injection**:

```swift
import SwiftUI
import WebKit

struct DashboardWebView: UIViewRepresentable {
    let url: URL
    let session: Session?  // Changed from authToken: String?
    @Binding var isLoading: Bool

    // Backward compatibility
    var authToken: String? {
        session?.accessToken
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        // Configure JavaScript message handlers
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "nativeApp")
        configuration.userContentController = contentController

        // Enable JavaScript
        configuration.preferences.javaScriptEnabled = true

        // Create WebView
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        // Inject auth token if available
        if let token = authToken {
            injectAuthToken(webView: webView, token: token)
        }

        // Load dashboard URL
        let request = URLRequest(url: url)
        webView.load(request)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Update WebView if needed
    }

    private func injectAuthToken(webView: WKWebView, token: String) {
        let script = """
        window.authToken = '\(token)';
        window.localStorage.setItem('supabase.auth.token', '\(token)');
        """

        let userScript = WKUserScript(
            source: script,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )

        webView.configuration.userContentController.addUserScript(userScript)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: DashboardWebView

        init(_ parent: DashboardWebView) {
            self.parent = parent
        }

        // Navigation Delegate Methods

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            print("WebView navigation error: \(error)")
        }

        // JavaScript Message Handler

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard let body = message.body as? [String: Any],
                  let type = body["type"] as? String else {
                return
            }

            handleMessage(type: type, payload: body["payload"])
        }

        private func handleMessage(type: String, payload: Any?) {
            switch type {
            case "navigate":
                if let url = payload as? String {
                    // Handle deep linking or navigation
                    print("Navigate to: \(url)")
                }

            case "analytics":
                if let event = payload as? [String: Any],
                   let eventName = event["name"] as? String,
                   let properties = event["properties"] as? [String: Any] {
                    AnalyticsManager.shared.track(event: eventName, properties: properties)
                }

            default:
                print("Unknown message type: \(type)")
            }

            // Note: Sign-out is handled entirely by the web interface.
            // The web dashboard manages authentication state and redirects appropriately.
        }
    }
}
```

#### 4.1.5 Main Tab View (MainTabView.swift)

The MainTabView serves as the primary navigation container for the ViiRaa iOS app, implementing a tab-based navigation pattern that provides users with quick access to the app's core features. This component follows iOS Human Interface Guidelines for tab bar navigation and manages four distinct sections of the application.

**Purpose**:

- Provide intuitive navigation between Dashboard, Glucose, Chat, and Settings
- Maintain navigation state across user sessions
- Follow native iOS design patterns for familiar user experience
- Showcase both WebView integration and native iOS functionality (HealthKit)

**Key Features**:

- **Tab 0 - Dashboard**: WebView-based dashboard with user health data, insights, and bootcamp content
- **Tab 1 - Glucose**: Native SwiftUI view displaying HealthKit glucose data with interactive charts and statistics
  - Demonstrates native iOS functionality for App Store approval
  - Features Time In Range and Peak Glucose metrics
  - Real-time CGM data visualization
- **Tab 2 - Chat**: Placeholder UI (Phase 1) that will evolve into miniViiRaa AI coach chat (Phase 2)
- **Tab 3 - Settings**: Native settings screen with HealthKit permissions management and app information

**Implementation Notes**:

- Uses SwiftUI's `TabView` for native tab bar navigation
- Integrates with `AuthManager` via `@EnvironmentObject` for authentication state
- Integrates with `HealthKitManager` for glucose data access in Glucose tab
- Applies ViiRaa brand color (Sage Green #A8B79E) to selected tab items
- Each tab is independently implemented as a separate view component for modularity
- Glucose tab showcases native iOS capabilities to strengthen App Store approval case

```swift
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0
    @State private var isLoadingDashboard = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView(isLoading: $isLoadingDashboard)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)

            // Glucose Tab (Native HealthKit Integration)
            GlucoseView()
                .tabItem {
                    Label("Glucose", systemImage: "heart.text.square.fill")
                }
                .tag(1)

            // Chat Tab (WhatsApp Redirect for Phase 1)
            ChatWhatsAppView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(2)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .accentColor(Color("PrimaryColor")) // Sage green #A8B79E
    }
}

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isLoading: Bool

    private let dashboardURL = URL(string: "https://viiraa.com/dashboard")!

    var body: some View {
        NavigationView {
            ZStack {
                DashboardWebView(
                    url: dashboardURL,
                    authToken: authManager.session?.accessToken,
                    isLoading: $isLoading
                )

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ChatWhatsAppView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "message.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color("PrimaryColor"))

                Text("Chat with our Team")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Chat with our team on WhatsApp while we build our native chat feature")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: {
                    if let url = URL(string: "https://wa.me/18882087058") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.up.right")
                        Text("Open WhatsApp")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("PrimaryColor"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)

                Text("This is a temporary solution. Native chat coming soon!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SettingsView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var healthKitAuthStatus: HKAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationView {
            List {
                // HealthKit Permissions Section
                Section(header: Text("HealthKit Permissions")) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text("Health Data Access")
                                .font(.headline)
                            Text(healthKitStatusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        healthKitStatusIndicator
                    }

                    Button(action: {
                        openHealthKitSettings()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                            Text("Manage HealthKit Access")
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why HealthKit?")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("ViiRaa uses HealthKit to read your glucose data (CGM), weight, and activity information to provide personalized insights and track your wellness progress.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // App Information Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://www.viiraa.com/ViiRaa_Privacy_Policy_Notice_US_20250808.pdf")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                checkHealthKitAuthStatus()
            }
        }
    }

    private var healthKitStatusText: String {
        switch healthKitAuthStatus {
        case .sharingAuthorized:
            return "Access granted"
        case .sharingDenied:
            return "Access denied - tap to enable"
        case .notDetermined:
            return "Not configured"
        @unknown default:
            return "Unknown status"
        }
    }

    private var healthKitStatusIndicator: some View {
        Image(systemName: healthKitAuthStatus == .sharingAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            .foregroundColor(healthKitAuthStatus == .sharingAuthorized ? .green : .orange)
    }

    private func checkHealthKitAuthStatus() {
        // Check HealthKit authorization status
        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else { return }
        healthKitAuthStatus = healthKitManager.healthStore.authorizationStatus(for: glucoseType)
    }

    private func openHealthKitSettings() {
        // Open iOS Settings app to Health section
        if let url = URL(string: "x-apple-health://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        } else if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            // Fallback to general Settings if Health URL doesn't work
            UIApplication.shared.open(settingsUrl)
        }
    }
}
```

### 4.2 HealthKit Integration (Phase 2) - ✅ IMPLEMENTED

**Implementation Status**: Complete as of 2025-10-21

The HealthKit integration has been fully implemented with the following components:

1. **HealthKitManager.swift**: Complete manager for all HealthKit operations (glucose, weight, activity)
2. **HealthDataModels.swift**: Comprehensive data models with range classification and statistics
3. **GlucoseView.swift**: Native SwiftUI view for glucose data visualization
4. **MainTabView.swift**: Updated with dedicated Glucose tab navigation

### 4.2 HealthKit Integration Components

#### 4.2.1 HealthKit Manager (HealthKitManager.swift)

```swift
import Foundation
import HealthKit

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var latestGlucoseReading: HKQuantitySample?
    @Published var latestWeight: HKQuantitySample?

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]

        let typesToWrite: Set<HKSampleType> = []

        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)

        self.isAuthorized = true
    }

    // MARK: - Glucose Data

    func fetchLatestGlucose() async throws -> HKQuantitySample? {
        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else {
            throw HealthKitError.typeNotAvailable
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: glucoseType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            if let error = error {
                print("Error fetching glucose: \(error)")
                return
            }

            Task { @MainActor in
                self?.latestGlucoseReading = samples?.first as? HKQuantitySample
            }
        }

        healthStore.execute(query)
        return latestGlucoseReading
    }

    func fetchGlucoseHistory(startDate: Date, endDate: Date) async throws -> [HKQuantitySample] {
        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else {
            throw HealthKitError.typeNotAvailable
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: glucoseType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let glucoseSamples = samples as? [HKQuantitySample] ?? []
                continuation.resume(returning: glucoseSamples)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Weight Data

    func fetchLatestWeight() async throws -> HKQuantitySample? {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.typeNotAvailable
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            if let error = error {
                print("Error fetching weight: \(error)")
                return
            }

            Task { @MainActor in
                self?.latestWeight = samples?.first as? HKQuantitySample
            }
        }

        healthStore.execute(query)
        return latestWeight
    }

    // MARK: - Activity Data

    func fetchStepCount(for date: Date) async throws -> Double {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.typeNotAvailable
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let steps = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: steps)
            }

            healthStore.execute(query)
        }
    }
}

// MARK: - Errors

enum HealthKitError: Error {
    case notAvailable
    case typeNotAvailable
    case authorizationDenied
}
```

#### 4.2.2 Native Glucose Data Display View (GlucoseView.swift)

**File Location**: `251015-Xcode/Features/HealthKit/GlucoseView.swift`

**Implementation Features**:

1. **Latest Reading Card**: Displays most recent glucose value with color-coded range indicator
2. **CRITICAL Statistics Card** - Emphasizing Two Key Metrics:

   a. **🎯 TIME IN RANGE (70-180 mg/dL)** - **PRIMARY METRIC FOR WEIGHT LOSS**

   - Displayed with **LARGE, BOLD FONT** (size 32+)
   - Prominent percentage display (e.g., "85% IN RANGE")
   - Color-coded: Green (>70%), Yellow (50-70%), Red (<50%)
   - Supporting text: "Critical for weight management"

   b. **⚠️ PEAK GLUCOSE** - **MOST DAMAGING TO THE BODY**

   - Displayed with **LARGE, WARNING FONT** (size 28+)
   - Shows highest glucose value in selected time period
   - Color-coded: Red if >250 mg/dL, Orange if >200 mg/dL
   - Supporting text: "Peak glucose level - minimize for better health"

   c. **Secondary Statistics** (smaller display):

   - Average glucose (standard size)
   - Minimum glucose (standard size)
   - Standard deviation (small size)
3. **Glucose Trend Chart**: Interactive chart using Swift Charts framework (iOS 16+) showing:

   - Glucose readings over time as line chart
   - Target range (70-180 mg/dL) highlighted in green
   - Peak glucose points highlighted with warning markers
   - Color-coded data points based on range status
4. **Recent Readings List**: Scrollable list of last 10 readings with timestamps
5. **Time Range Selector**: Segmented control for Today/Week/Month views
6. **Error Handling**: Proper error states and retry functionality
7. **Empty State**: Helpful message when no glucose data is available

**Key UI Components**:

```swift
// Main view structure
struct GlucoseView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var glucoseReadings: [GlucoseReading] = []
    @State private var statistics: GlucoseStatistics?
    @State private var selectedTimeRange: TimeRange = .today

    enum TimeRange {
        case today, week, month
    }
}

// Supporting views - UPDATED WITH CRITICAL METRICS EMPHASIS
struct LatestGlucoseCard: View // Latest reading display

struct CriticalStatisticsCard: View {
    // PROMINENT DISPLAY OF TWO KEY METRICS:
    // 1. Time In Range (LARGE FONT - size 32+)
    // 2. Peak Glucose (LARGE FONT - size 28+)
    var timeInRangePercentage: Double
    var peakGlucoseValue: Double

    var body: some View {
        VStack {
            // Time In Range - PRIMARY METRIC
            VStack {
                Text("\(Int(timeInRangePercentage))%")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(rangeColor)
                Text("TIME IN RANGE")
                    .font(.caption)
                Text("Critical for weight loss")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Peak Glucose - MOST DAMAGING
            VStack {
                Text("\(Int(peakGlucoseValue)) mg/dL")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(peakColor)
                Text("PEAK GLUCOSE")
                    .font(.caption)
                Text("Minimize for better health")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct GlucoseChartView: View // Interactive chart with peak highlighting
struct ReadingsListView: View // List of recent readings
struct RangeIndicator: View // Color-coded range badge
```

**Integration with MainTabView**:

The glucose view is accessible via a dedicated tab in the main navigation:

```swift
TabView {
    DashboardView().tag(0)
    GlucoseView().tag(1) // New Glucose tab
    ChatPlaceholderView().tag(2)
}
```

**Data Flow**:

1. View loads → Requests HealthKit authorization if needed
2. Fetches glucose history using `HealthKitManager.shared.fetchGlucoseHistory()`
3. Converts HKQuantitySample to GlucoseReading models
4. Calculates statistics using GlucoseStatistics
5. Displays data in charts and lists
6. Tracks analytics events for data loading

**Analytics Integration**:

- `glucose_data_loaded`: Fired when data successfully loads
- `glucose_data_load_failed`: Fired on errors
- Properties tracked: readings_count, time_range

#### 4.2.3 Info.plist HealthKit Configuration

```xml
<key>NSHealthShareUsageDescription</key>
<string>ViiRaa needs access to your health data to provide personalized glucose insights and track your wellness progress.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>ViiRaa would like to save health insights to your Health app.</string>

<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
</array>

<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>healthkit</string>
</array>
```

### 4.3 Junction SDK Integration (Phase 2)

#### 4.3.1 Overview

Junction (formerly Vital) provides a unified API for health data integration. The Vital Mobile SDK enables ViiRaa to sync HealthKit data to Junction's cloud for ML model training.

**Key Capabilities**:

- Unified API supporting 300+ health devices
- Automated HealthKit data sync (hourly)
- HIPAA-compliant data storage
- Y Combinator-backed with $18M Series A funding

**Data Delay Note**: Apple HealthKit enforces a minimum 3-hour data delay. This is acceptable for ML training and historical analysis but not suitable for real-time alerts.

> ⚠️ **CRITICAL - Data Source Requirements (Bug #21 Finding)**:
>
> Junction can only sync data that **actively exists in HealthKit with proper source attribution**. The ViiRaa app currently uses **read-only** HealthKit permissions and does NOT write glucose data. This means:
>
> 1. **Read-only access ≠ Data source**: The app reads glucose data for display but doesn't generate or write data
> 2. **Junction syncs what exists**: Junction can only upload data that the SDK has been granted permission to read AND that exists from valid sources
> 3. **Manual entries may not sync**: Manually entered glucose data in Apple Health may have different source attribution that Junction doesn't recognize
> 4. **CGM data required**: For reliable sync, data should come from a connected CGM device (e.g., Abbott Lingo) that writes to HealthKit
> 5. **Verify at destination**: "Sync initiated" does NOT mean "Data delivered" - always verify data appears in Junction dashboard
>
> **Verification Steps**:
> - Check Junction dashboard 3+ hours after sync for historical data
> - If no data appears after 3+ hours, verify: (a) VitalHealthKitClient has glucose permission, (b) Source data exists in HealthKit from recognized device
>
> See [Bug #21 Analysis](Learnings_From_Doing.md) for detailed root cause and solutions.

#### 4.3.2 Junction SDK Integration (JunctionManager.swift)

```swift
import Foundation
import VitalHealth

@MainActor
class JunctionManager: ObservableObject {
    static let shared = JunctionManager()

    @Published var isConfigured = false
    @Published var syncStatus: SyncStatus = .idle

    enum SyncStatus {
        case idle, syncing, success, failed
    }

    private init() {}

    // MARK: - Configuration

    func configure(apiKey: String) {
        VitalHealth.configure(apiKey: apiKey)
        isConfigured = true
    }

    // MARK: - HealthKit Permissions

    func requestHealthKitPermissions() async throws {
        try await VitalHealth.shared.ask(
            readPermissions: [.glucose, .weight, .steps, .activeEnergyBurned],
            writePermissions: []
        )
    }

    // MARK: - Data Sync

    func syncHealthData() async throws {
        guard isConfigured else {
            throw JunctionError.notConfigured
        }

        syncStatus = .syncing

        do {
            // SDK automatically handles background sync
            // Data syncs hourly to Junction cloud
            try await VitalHealth.shared.syncData()
            syncStatus = .success
        } catch {
            syncStatus = .failed
            throw error
        }
    }
}

// MARK: - Errors

enum JunctionError: Error {
    case notConfigured
    case syncFailed
    case permissionDenied
}
```

#### 4.3.3 Info.plist Configuration for Junction

```xml
<!-- Required for Junction SDK background sync -->
<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
</array>

<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.viiraa.app.healthsync</string>
</array>
```

#### 4.3.4 Implementation Requirements

**Prerequisites**:

1. Sign contract and BAA (Business Associate Agreement) with Junction
2. Obtain Junction API key from dashboard
3. Add VitalHealth SDK via Swift Package Manager

**Swift Package Manager Dependency**:

```swift
.package(url: "https://github.com/tryVital/vital-ios.git", from: "1.0.0")
```

**Reference Documentation**: `/Users/barack/Downloads/Xcode/3rd_Party_Bio_Data_Integration_Report.md`

---

### 4.4 Bluetooth Low Energy (BLE) Follow Mode Integration (Phase 3)

#### 4.4.1 Overview

BLE Follow Mode is an optional enhancement to reduce glucose data latency from 3 hours (HealthKit limitation) to 1-5 minutes. This feature provides real-time glucose monitoring through Bluetooth Low Energy (BLE) monitoring of the official Abbott Lingo app.

**Implementation Strategy**: Follower Mode (NOT Master Mode)

- Monitors communication between official Abbott Lingo app and sensor
- Extracts glucose readings without breaking encryption
- Does NOT reverse-engineer proprietary protocols
- Legally compliant with manufacturer Terms of Service
- App Store compliant (similar approach to xDrip4iOS)

#### 4.4.2 Data Latency Comparison

| Data Source                    | Latency     | Use Case                         | Implementation Phase |
| ------------------------------ | ----------- | -------------------------------- | -------------------- |
| Apple HealthKit (via Junction) | 3 hours     | ML training, historical analysis | Phase 2 (Primary)    |
| BLE Follow Mode (Abbott Lingo) | 1-5 minutes | Real-time user insights          | Phase 3 (Optional)   |

#### 4.4.3 Supported CGM Device

**Abbott Lingo:**

- **Hardware**: Built on Abbott FreeStyle Libre technology (10+ million users)
- **Sensor Duration**: Up to 14 days
- **Measurement Frequency**: Measures glucose every minute
- **Transmission Method**: Streams continuously via Bluetooth
- **Warm-up Period**: 60-minute initial warm-up
- **Apple Health Integration**: Sends interstitial fluid glucose data to HealthKit
- **Follow Mode Compatibility**: Technically feasible with Follower Mode approach

#### 4.4.4 Hybrid Architecture Strategy

**Recommended Approach**: Use both Junction SDK AND BLE Follow Mode in parallel

Junction API Key is documented in `/Users/barack/Downloads/Xcode/Credentials.md`

```
┌─────────────────────────────────────────────────────┐
│              ViiRaa iOS App                         │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌───────────────────┐   ┌────────────────────┐   │
│  │  Junction SDK     │   │  BLE Follow Mode   │   │
│  │  (via HealthKit)  │   │  (Abbott Lingo)    │   │
│  ├───────────────────┤   ├────────────────────┤   │
│  │ Latency: 3 hours  │   │ Latency: 1-5 min   │   │
│  │ Use: ML training  │   │ Use: Real-time UI  │   │
│  │ Status: Primary   │   │ Status: Optional   │   │
│  └───────────────────┘   └────────────────────┘   │
│           │                       │                │
│           └───────┬───────────────┘                │
│                   ▼                                │
│         ┌──────────────────┐                       │
│         │  Data Validator  │                       │
│         │  Cross-validate  │                       │
│         │  both sources    │                       │
│         └──────────────────┘                       │
└─────────────────────────────────────────────────────┘
```

**Data Pipeline Roles:**

1. **Junction SDK (Primary)**

   - Historical data collection for ML model training
   - HIPAA-compliant cloud storage
   - Long-term data retention
   - Fallback when BLE unavailable
   - Works with all 300+ supported devices
2. **BLE Follow Mode (Real-time)**

   - Low-latency glucose readings for user-facing UI
   - Real-time alerts and notifications
   - Immediate user feedback
   - Enhanced user experience
   - Cross-validation against Junction data

#### 4.4.5 BLE Manager Implementation (BLEFollowManager.swift)

```swift
import Foundation
import CoreBluetooth
import Combine

@MainActor
class BLEFollowManager: NSObject, ObservableObject {
    static let shared = BLEFollowManager()

    @Published var isEnabled = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var latestGlucoseReading: GlucoseReading?
    @Published var lastUpdateTime: Date?

    private var centralManager: CBCentralManager?
    private var discoveredPeripherals: [CBPeripheral] = []
    private var cancellables = Set<AnyCancellable>()

    enum ConnectionStatus {
        case disconnected
        case scanning
        case connected
        case error(String)
    }

    struct GlucoseReading {
        let value: Double // mg/dL
        let timestamp: Date
        let trend: GlucoseTrend?
        let source: DataSource

        enum GlucoseTrend {
            case rapidlyRising    // ↑↑
            case rising          // ↑
            case stable          // →
            case falling         // ↓
            case rapidlyFalling  // ↓↓
        }

        enum DataSource {
            case bleFollowMode
            case healthKit
            case junction
        }
    }

    private override init() {
        super.init()
    }

    // MARK: - Configuration

    func enable() {
        guard !isEnabled else { return }
        isEnabled = true
        startMonitoring()
    }

    func disable() {
        guard isEnabled else { return }
        isEnabled = false
        stopMonitoring()
    }

    // MARK: - BLE Monitoring

    private func startMonitoring() {
        // Initialize Core Bluetooth
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )
        connectionStatus = .scanning
    }

    private func stopMonitoring() {
        centralManager?.stopScan()
        centralManager = nil
        connectionStatus = .disconnected
    }

    // MARK: - Data Processing

    private func processGlucoseData(_ data: Data) {
        // Parse BLE data packets from Abbott Lingo communication
        // Extract glucose value, timestamp, and trend
        // This follows Follower Mode approach - monitoring existing communication
        // NOT reverse engineering or decrypting proprietary protocols

        guard let glucoseValue = extractGlucoseValue(from: data),
              let timestamp = extractTimestamp(from: data) else {
            return
        }

        let trend = extractTrend(from: data)

        let reading = GlucoseReading(
            value: glucoseValue,
            timestamp: timestamp,
            trend: trend,
            source: .bleFollowMode
        )

        latestGlucoseReading = reading
        lastUpdateTime = Date()

        // Cross-validate with Junction data
        Task {
            await validateWithJunctionData(reading)
        }
    }

    private func extractGlucoseValue(from data: Data) -> Double? {
        // Implementation based on xDrip4iOS approach
        // Monitors public BLE advertisements
        // Does not decrypt proprietary data
        return nil // Placeholder
    }

    private func extractTimestamp(from data: Data) -> Date? {
        // Extract timestamp from BLE packet
        return nil // Placeholder
    }

    private func extractTrend(from data: Data) -> GlucoseReading.GlucoseTrend? {
        // Extract trend information if available
        return nil // Placeholder
    }

    // MARK: - Data Validation

    private func validateWithJunctionData(_ reading: GlucoseReading) async {
        // Cross-validate BLE reading with Junction/HealthKit data
        // Ensure accuracy > 95%
        // Log discrepancies for monitoring
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEFollowManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                startScanning()
            case .poweredOff:
                connectionStatus = .error("Bluetooth is powered off")
            case .unauthorized:
                connectionStatus = .error("Bluetooth access not authorized")
            case .unsupported:
                connectionStatus = .error("Bluetooth not supported on this device")
            default:
                connectionStatus = .disconnected
            }
        }
    }

    private func startScanning() {
        // Scan for Abbott Lingo app BLE communications
        // Monitor public BLE advertisements only
        centralManager?.scanForPeripherals(
            withServices: nil, // Monitor general BLE traffic
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        Task { @MainActor in
            // Filter for Abbott Lingo related peripherals
            // Process advertisement data
            if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
                processGlucoseData(manufacturerData)
            }
        }
    }
}

// MARK: - Errors

enum BLEFollowError: Error {
    case bluetoothUnavailable
    case unauthorizedAccess
    case connectionFailed
    case dataParsingFailed
    case validationFailed
}
```

#### 4.4.6 User Experience Flow

**User Onboarding:**

1. User downloads ViiRaa app from App Store
2. User completes standard authentication flow
3. App detects if user wants real-time glucose monitoring
4. If yes, app guides user to install official Abbott Lingo app
5. User pairs CGM sensor with official Abbott Lingo app first
6. User enables BLE Follow Mode in ViiRaa settings
7. ViiRaa monitors official app communications
8. Real-time glucose data appears in ViiRaa dashboard

**Settings UI Requirements:**

```swift
struct BLEFollowSettingsView: View {
    @StateObject private var bleManager = BLEFollowManager.shared
    @State private var showSetupGuide = false

    var body: some View {
        List {
            Section(header: Text("BLE Follow Mode")) {
                Toggle("Enable Real-time Glucose", isOn: $bleManager.isEnabled)
                    .onChange(of: bleManager.isEnabled) { newValue in
                        if newValue {
                            bleManager.enable()
                        } else {
                            bleManager.disable()
                        }
                    }

                if bleManager.isEnabled {
                    HStack {
                        Text("Status")
                        Spacer()
                        StatusIndicator(status: bleManager.connectionStatus)
                    }

                    if let lastUpdate = bleManager.lastUpdateTime {
                        HStack {
                            Text("Last Update")
                            Spacer()
                            Text(lastUpdate, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section(header: Text("Setup")) {
                Button(action: { showSetupGuide = true }) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Setup Instructions")
                    }
                }

                Link(destination: URL(string: "https://apps.apple.com/us/app/lingo-by-abbott/id6478821307")!) {
                    HStack {
                        Image(systemName: "arrow.down.app")
                        Text("Download Abbott Lingo App")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                    }
                }
            }

            Section(header: Text("Information")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("BLE Follow Mode provides real-time glucose readings (1-5 minute latency) by monitoring the official Abbott Lingo app.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Requires:")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Text("• Abbott Lingo app installed")
                        .font(.caption)
                    Text("• Abbott Lingo sensor paired")
                        .font(.caption)
                    Text("• Bluetooth enabled")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("BLE Follow Mode")
        .sheet(isPresented: $showSetupGuide) {
            BLESetupGuideView()
        }
    }
}

struct StatusIndicator: View {
    let status: BLEFollowManager.ConnectionStatus

    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
        }
    }

    private var statusColor: Color {
        switch status {
        case .connected:
            return .green
        case .scanning:
            return .orange
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }

    private var statusText: String {
        switch status {
        case .connected:
            return "Connected"
        case .scanning:
            return "Scanning..."
        case .disconnected:
            return "Disconnected"
        case .error(let message):
            return message
        }
    }
}
```

#### 4.4.7 Info.plist Configuration for BLE

```xml
<!-- Required for BLE Follow Mode -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>ViiRaa uses Bluetooth to receive real-time glucose readings from your CGM device for immediate health insights.</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>ViiRaa monitors Bluetooth communications to provide real-time glucose data updates.</string>

<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <string>processing</string>
</array>
```

#### 4.4.8 Implementation Phases

**Phase 2 (Week 2-4): Foundation**

- Deploy Junction SDK with HealthKit integration
- Collect user feedback on 3-hour data delay
- Assess impact on product/science goals
- **Decision Point**: Go/No-go for BLE Follow Mode

**Phase 3 (Week 7-12): BLE Follow Mode (Only if latency is blocker)**

- Research xDrip4iOS implementation approach
- Develop Follower Mode data interceptor
- Implement for Abbott Lingo (1-5 minute latency)
- Build user onboarding flow for dual-app setup
- Create settings UI for BLE configuration
- Test via TestFlight before App Store submission
- Deploy with feature flag for gradual rollout

#### 4.4.9 Legal & Compliance Considerations

**Approved Approach (Follower Mode):**

- ✅ No reverse engineering of proprietary protocols
- ✅ No decryption of manufacturer encryption
- ✅ Does not violate DMCA
- ✅ Complies with manufacturer Terms of Service
- ✅ App Store compliant (xDrip4iOS precedent)

**Prohibited Approach (Master Mode):**

- ❌ Direct BLE connection to CGM sensor (bypassing official app)
- ❌ Reverse engineering encryption protocols
- ❌ Breaking device authorization mechanisms
- ❌ High legal risk and App Store rejection risk

#### 4.4.10 Cost-Benefit Analysis

| Factor                 | Junction SDK Only | Junction + BLE Follow Mode |
| ---------------------- | ----------------- | -------------------------- |
| Development Time       | 1-2 weeks         | 3-4 months                 |
| Maintenance Complexity | Low               | Medium                     |
| Legal Risk             | None              | Low                        |
| Data Latency           | 3 hours           | 1-5 minutes                |
| User Setup Complexity  | Low (1 app)       | Medium (2 apps)            |
| ML Training Capability | Excellent         | Excellent                  |
| Real-time Alerts       | Limited           | Good                       |
| Device Compatibility   | 300+ devices      | Abbott Lingo only          |

#### 4.4.11 Success Metrics (Phase 3)

**Technical Metrics:**

- BLE data latency: <5 minutes average
- Data accuracy: >95% match with official Abbott Lingo app readings
- Cross-validation success rate: >98%
- Fallback to Junction: <5% of sessions

**User Metrics:**

- Dual-app setup completion rate: >60%
- BLE Follow Mode adoption rate: >30% of eligible users
- User satisfaction with real-time data: 4.0+ rating

**Business Metrics:**

- Reduced churn due to real-time insights
- Increased engagement with real-time alerts
- Improved ML model accuracy with higher-frequency data

#### 4.4.12 References

- xDrip4iOS Documentation: https://xdrip4ios.readthedocs.io/
- Third-Party Bio Data Integration Report: `/Users/barack/Downloads/Xcode/3rd_Party_Bio_Data_Integration_Report.md`
- Abbott Lingo Technical Specifications (PRD Section 12)
- BLE Implementation Recommendations (PRD Section 2.5)
- PRD Section 12 (Lines 805-1003): BLE Follow Mode Technical Specifications

---

### 4.5 Glucose Prediction Feature Integration (Phase 2)

#### 4.5.1 Overview

The Glucose Prediction feature enables users to view their glucose predictions and create new predictions directly from the iOS app. This feature leverages the existing web implementation via WebView integration, requiring no code rewrite.

#### 4.5.2 Feature Description

**User Journey:**

1. User navigates to Glucose Tab in iOS app
2. User accesses https://www.viiraa.com/predict-glucose to view all predictions or create new prediction
3. Backend generates prediction ID for each user operation
4. User views individual prediction charts at https://www.viiraa.com/predict-glucose/{prediction-id}

**Key Characteristics:**

- **Implementation**: WebView-based integration (no native code required)
- **Source Code Reference**: `/Users/barack/Downloads/251210-viiraalanding-main`
- **Entry Point**: Glucose Tab in MainTabView
- **URLs**:
  - Prediction List: `https://www.viiraa.com/predict-glucose`
  - Individual Prediction: `https://www.viiraa.com/predict-glucose/{prediction-id}`

#### 4.5.3 Implementation Approach - ✅ IMPLEMENTED

**Implemented Files:**

| File | Description |
|------|-------------|
| `Xcode/Features/HealthKit/GlucosePredictionWebView.swift` | New WebView component for glucose predictions |
| `Xcode/Features/HealthKit/GlucoseView.swift` | Updated with navigation link to predictions |
| `Xcode/Core/Navigation/MainTabView.swift` | Updated to pass authManager to GlucoseView |

**GlucosePredictionWebView.swift** (New File):

```swift
/// GlucosePredictionWebView - Displays glucose predictions via WebView
/// User Journey:
/// 1. User navigates to Glucose Tab in iOS app
/// 2. User taps "View Glucose Predictions" to access this view
/// 3. User can view all predictions or create new prediction
/// 4. User can view individual prediction charts
struct GlucosePredictionWebView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isLoading = true
    private let predictionURL = URL(string: "https://www.viiraa.com/predict-glucose")!

    var body: some View {
        ZStack {
            if let session = authManager.session {
                PredictionWebViewContainer(
                    url: predictionURL,
                    session: session,
                    isLoading: $isLoading
                )
            } else {
                // Handle unauthenticated state
                Text("Please sign in to view glucose predictions.")
            }
            if isLoading && authManager.session != nil {
                ProgressView()
            }
        }
        .navigationTitle("Glucose Predictions")
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

**GlucoseView.swift** (Updated - Navigation Link):

```swift
// Navigation link added after time range picker
NavigationLink(destination: GlucosePredictionWebView().environmentObject(authManager)) {
    HStack {
        Image(systemName: "chart.line.uptrend.xyaxis")
            .font(.title2)
            .foregroundColor(Color("PrimaryColor"))
        VStack(alignment: .leading, spacing: 4) {
            Text("Glucose Predictions")
                .font(.headline)
            Text("View and create glucose predictions")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        Spacer()
        Image(systemName: "chevron.right")
    }
}
```

**MainTabView.swift** (Updated - Environment Object):

```swift
// GlucoseView now receives authManager environment object
GlucoseView()
    .environmentObject(authManager)
    .tabItem {
        Label("Glucose", systemImage: "heart.text.square.fill")
    }
```

**Deep Link Support (GlucosePredictionDetailView)**:

```swift
/// View for displaying a specific prediction by ID
struct GlucosePredictionDetailView: View {
    let predictionId: String
    @EnvironmentObject var authManager: AuthManager
    private var predictionURL: URL {
        URL(string: "https://www.viiraa.com/predict-glucose/\(predictionId)")!
    }
    // ... WebView implementation with session injection
}
```

#### 4.5.4 Session Injection for Prediction Pages

The same session injection strategy used for the Dashboard WebView applies to the Glucose Prediction WebView:

1. Complete Supabase session injected into WebView's localStorage
2. Session key format: `sb-{supabase-project-id}-auth-token`
3. User authentication persists across Dashboard and Prediction views
4. No duplicate login prompts when navigating to prediction pages

#### 4.5.5 Related PRD References

- PRD Section 4.2 (Lines 192-199): Glucose Prediction Feature specification
- PRD Section 7 Development Plan (Lines 475-478): Milestone #15 for integration
- PRD Section 10 Success Criteria (Lines 589-592): Feature verification checkboxes
- PRD Section 12 Decisions Log (Lines 803-816): Decision rationale

---

### 4.6 Analytics Integration (PostHog)

#### 4.6.1 Analytics Manager (AnalyticsManager.swift)

```swift
import Foundation
import PostHog

@MainActor
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()

    private var posthog: PHGPostHog?

    private init() {}

    func initialize() {
        let configuration = PHGPostHogConfiguration(apiKey: Constants.posthogAPIKey, host: Constants.posthogHost)
        configuration.captureApplicationLifecycleEvents = true
        configuration.captureDeepLinks = true

        PHGPostHog.setup(with: configuration)
        posthog = PHGPostHog.shared()
    }

    func identify(userId: String, traits: [String: Any]? = nil) {
        posthog?.identify(userId, traits: traits)
    }

    func track(event: String, properties: [String: Any]? = nil) {
        posthog?.capture(event, properties: properties)
    }

    func screen(name: String, properties: [String: Any]? = nil) {
        posthog?.screen(name, properties: properties)
    }

    func reset() {
        posthog?.reset()
    }
}
```

### 4.7 Configuration & Constants

#### 4.7.1 Constants.swift

```swift
import Foundation

struct Constants {
    // App Information
    static let appName = "ViiRaa"
    static let bundleIdentifier = "com.viiraa.app"
    static let appStoreID = "YOUR_APP_STORE_ID"

    // API Configuration
    static let baseURL = "https://viiraa.com"
    static let dashboardPath = "/dashboard"
    static let apiPath = "/api"

    // Supabase Configuration
    static let supabaseURL = "https://efwiicipqhurfcpczmnw.supabase.co"
    static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"

    // PostHog Configuration
    static let posthogAPIKey = "YOUR_POSTHOG_API_KEY"
    static let posthogHost = "https://us.posthog.com"

    // Feature Flags
    static let isHealthKitEnabled = true
    static let isBLEFollowModeEnabled = false // Phase 3 - Optional
    static let isPushNotificationsEnabled = false

    // UI Colors (Sage Green Primary)
    static let primaryColorHex = "#A8B79E"
}
```

---

## 5. Security & Privacy

### 5.1 Authentication Security

#### Token Management

- **Storage**: All authentication tokens stored in iOS Keychain with `kSecAttrAccessibleAfterFirstUnlock`
- **Transmission**: Tokens passed to WebView via JavaScript injection (never via URL parameters)
- **Refresh**: Automatic token refresh handled by Supabase SDK
- **Expiration**: Session timeout enforced (7 days for refresh token, 1 hour for access token)

#### OAuth Security

- **Google OAuth**: System browser flow (ASWebAuthenticationSession) for enhanced security
- **PKCE**: Proof Key for Code Exchange implemented in OAuth flow
- **State Parameter**: Random state parameter to prevent CSRF attacks

### 5.2 Data Privacy

#### HealthKit Privacy

- **Permission Requests**: Explicit user consent required before accessing health data
- **Usage Descriptions**: Clear explanations in Info.plist for each data type
- **Data Minimization**: Only request necessary health data types
- **No Selling**: Health data never shared with third parties

#### User Data Handling

- **Encryption**: All data encrypted in transit (HTTPS) and at rest (Keychain, HealthKit)
- **Local Storage**: Minimal local data storage; rely on backend for persistence
- **Data Deletion**: User can delete account and all associated data
- **Privacy Policy**: Comprehensive privacy policy accessible from app

### 5.3 Network Security

#### HTTPS Enforcement

```swift
// App Transport Security (Info.plist)
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>viiraa.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
    </dict>
</dict>
```

#### Certificate Pinning (Optional Enhancement)

```swift
class NetworkManager {
    func setupCertificatePinning() {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        // Implement certificate pinning logic
    }
}
```

### 5.4 Code Security

#### Obfuscation

- **API Keys**: Store sensitive keys in environment variables, not hardcoded
- **Keychain**: Use for all sensitive data storage
- **No Logs**: Avoid logging sensitive information in production builds

#### Static Analysis

- Run SwiftLint for code quality checks
- Use Xcode's static analyzer regularly
- Regular dependency audits for security vulnerabilities

---

## 6. Development Workflow

### 6.1 Development Environment Setup

#### Prerequisites

```bash
# macOS Requirements
- macOS 13.0+ (Ventura or later)
- Xcode 14.0+
- CocoaPods or Swift Package Manager
- iOS 14.0+ device or simulator

# Install Xcode Command Line Tools
xcode-select --install

# Install CocoaPods (if using)
sudo gem install cocoapods

# Clone repository
git clone https://github.com/viiraa/viiraa-ios.git
cd viiraa-ios

# Install dependencies
pod install  # or use Swift Package Manager

# Open workspace
open ViiRaaApp.xcworkspace
```

#### Environment Configuration

```swift
// Create Config.xcconfig file for each environment

// Development.xcconfig
SUPABASE_URL = https://efwiicipqhurfcpczmnw.supabase.co
SUPABASE_ANON_KEY = your-dev-anon-key
POSTHOG_API_KEY = your-dev-posthog-key
BASE_URL = http://localhost:8081

// Production.xcconfig
SUPABASE_URL = https://efwiicipqhurfcpczmnw.supabase.co
SUPABASE_ANON_KEY = your-prod-anon-key
POSTHOG_API_KEY = your-prod-posthog-key
BASE_URL = https://viiraa.com
```

### 6.2 Branching Strategy

```
main (production)
  ├── develop (integration)
  │   ├── feature/auth-implementation
  │   ├── feature/webview-integration
  │   ├── feature/healthkit-integration
  │   └── bugfix/webview-crash
  └── release/1.0.0
```

#### Branch Naming Convention

- `feature/feature-name` - New features
- `bugfix/bug-description` - Bug fixes
- `hotfix/critical-issue` - Production hotfixes
- `release/version` - Release preparation

### 6.3 Commit Guidelines

```bash
# Commit Message Format
<type>(<scope>): <subject>

# Types
feat: New feature
fix: Bug fix
docs: Documentation changes
style: Code style changes (formatting)
refactor: Code refactoring
test: Adding tests
chore: Build process or auxiliary tool changes

# Examples
feat(auth): implement Google OAuth sign-in
fix(webview): resolve crash on deep link navigation
docs(readme): update installation instructions
```

### 6.4 Code Review Process

1. **Create Pull Request**:

   - Descriptive title and description
   - Link to related issues
   - Screenshots/videos for UI changes
2. **Automated Checks**:

   - Build success on CI
   - Unit tests passing
   - Code coverage threshold met
   - SwiftLint passing
3. **Manual Review**:

   - At least 1 approval required
   - Architecture review for significant changes
   - Security review for auth/data handling
4. **Merge**:

   - Squash and merge to keep clean history
   - Delete feature branch after merge

---

## 7. Testing Strategy

### 7.1 Unit Testing

#### Authentication Tests (AuthManagerTests.swift)

```swift
import XCTest
@testable import ViiRaaApp

class AuthManagerTests: XCTestCase {
    var authManager: AuthManager!

    override func setUp() {
        super.setUp()
        authManager = AuthManager.shared
    }

    func testSignInWithValidCredentials() async throws {
        // Given
        let email = "test@viiraa.com"
        let password = "ValidPassword123"

        // When
        try await authManager.signInWithPassword(email: email, password: password)

        // Then
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.user)
        XCTAssertNotNil(authManager.session)
    }

    func testSignInWithInvalidCredentials() async {
        // Given
        let email = "invalid@viiraa.com"
        let password = "WrongPassword"

        // When/Then
        do {
            try await authManager.signInWithPassword(email: email, password: password)
            XCTFail("Expected authentication error")
        } catch {
            XCTAssertFalse(authManager.isAuthenticated)
        }
    }

    func testSignOut() async throws {
        // Given
        try await authManager.signInWithPassword(email: "test@viiraa.com", password: "ValidPassword123")

        // When
        await authManager.signOut()

        // Then
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.user)
        XCTAssertNil(authManager.session)
    }
}
```

#### HealthKit Tests (HealthKitManagerTests.swift)

```swift
import XCTest
import HealthKit
@testable import ViiRaaApp

class HealthKitManagerTests: XCTestCase {
    var healthKitManager: HealthKitManager!

    override func setUp() {
        super.setUp()
        healthKitManager = HealthKitManager.shared
    }

    func testHealthKitAuthorization() async throws {
        // When
        try await healthKitManager.requestAuthorization()

        // Then
        XCTAssertTrue(healthKitManager.isAuthorized)
    }

    func testFetchGlucoseData() async throws {
        // Given
        try await healthKitManager.requestAuthorization()

        // When
        let glucose = try await healthKitManager.fetchLatestGlucose()

        // Then
        XCTAssertNotNil(glucose)
    }
}
```

### 7.2 Integration Testing

#### WebView Integration Tests

```swift
import XCTest
@testable import ViiRaaApp

class WebViewIntegrationTests: XCTestCase {
    var webView: DashboardWebView!

    func testWebViewLoadsDashboard() throws {
        // Given
        let url = URL(string: "https://viiraa.com/dashboard")!
        let expectation = XCTestExpectation(description: "WebView loads dashboard")

        // When
        webView = DashboardWebView(url: url, authToken: "mock-token", isLoading: .constant(false))

        // Wait for load
        wait(for: [expectation], timeout: 10.0)

        // Then
        // Verify WebView loaded successfully
    }

    func testJavaScriptBridgeCommunication() throws {
        // Test native <-> web communication
        // Verify logout message handling
        // Verify analytics message handling
    }
}
```

### 7.3 UI Testing

#### UI Test Suite (UITests.swift)

```swift
import XCTest

class ViiRaaAppUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAuthenticationFlow() {
        // Given
        let emailField = app.textFields["emailTextField"]
        let passwordField = app.secureTextFields["passwordTextField"]
        let signInButton = app.buttons["signInButton"]

        // When
        emailField.tap()
        emailField.typeText("test@viiraa.com")

        passwordField.tap()
        passwordField.typeText("ValidPassword123")

        signInButton.tap()

        // Then
        let dashboardTitle = app.navigationBars["Dashboard"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 5))
    }

    func testTabNavigation() {
        // Test tab switching
        // Verify dashboard tab shows WebView
        // Verify chat tab shows placeholder
    }
}
```

### 7.4 Testing Checklist

#### Phase 1: TestFlight MVP

- [ ] Authentication flow (Google OAuth)
- [ ] Authentication flow (Email/Password)
- [ ] Keychain token storage and retrieval
- [ ] WebView loads dashboard successfully
- [ ] WebView navigation works
- [ ] JavaScript bridge communication
- [ ] Tab navigation (Dashboard ↔ Chat)
- [ ] Sign out functionality (handled by web interface)
- [ ] Session persistence across app launches
- [ ] Network error handling
- [ ] Loading states
- [ ] Memory leak checks

#### Phase 2: App Store Submission

- [ ] HealthKit permission request
- [ ] HealthKit glucose data reading
- [ ] HealthKit weight data reading
- [ ] HealthKit activity data reading
- [ ] Background health data sync
- [ ] Privacy policy accessible
- [ ] App Store screenshots prepared
- [ ] App Store description finalized

---

## 8. Deployment & Release

### 8.1 Build Configuration

#### Xcode Build Settings

```ruby
# Build Configurations
- Debug: Development builds for testing
- Release: Production builds for App Store

# Code Signing
- Development: Apple Development certificate
- Distribution: Apple Distribution certificate

# Provisioning Profiles
- Development: Development provisioning profile
- App Store: App Store provisioning profile
```

#### Version Numbering

```
Version: 1.0.0 (CFBundleShortVersionString)
Build: 1 (CFBundleVersion)

Semantic Versioning: MAJOR.MINOR.PATCH
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes
```

### 8.2 MVP Dual Submission Strategy

**Lei's Strategy: Submit to Both TestFlight AND App Store Simultaneously**

Per Lei's feedback, we will pursue a dual submission approach:

1. **TestFlight**: For internal testing with Lei and team
2. **App Store**: To identify any gaps and requirements for approval

This parallel approach allows us to:

- Get immediate feedback from internal testers
- Understand App Store review requirements early
- Iterate quickly based on both sources of feedback

### 8.2.1 TestFlight Deployment (MVP)

#### Deployment Steps

```bash
# 1. Increment Build Number
# In Xcode: Target → General → Identity → Build

# 2. Archive Build
# Xcode → Product → Archive

# 3. Validate Archive
# Window - Organizer → Validate App
# - Check for errors and warnings

# 4. Upload to App Store Connect
# Organizer → Distribute App → App Store Connect

# 5. Configure TestFlight
# Login to https://appstoreconnect.apple.com/
# App Store Connect - Apps - ViiRaa → TestFlight
# - Add internal testers (up to 100)
# - No App Review required for internal testing
# - Provide test instructions

# 6. Distribute to Testers
# TestFlight → Internal Testing → Add Users
# - Send invitations
# - Testers receive TestFlight invite email
```

For the question `What type of encryption algorithms does your app implement?`, the answer should be `Standard encryption algorithms instead of, or in addition to, using or accessing the encryption within Apple's operating system`.

For the question `Is your app going to be available for distribution in France?`, the answer should be `No`.

#### TestFlight Setup for Lei (Manager)

**Adding Lei as Internal Tester**:

1. Navigate to App Store Connect → TestFlight → Internal Testing
2. Click "+" to add new tester
3. Add Lei's and Barack's Apple ID: **zl.stone1992@gmail.com** and **BarackLiu@icloud.com**
4. Assign role: "Admin" or "App Manager"
5. Send TestFlight invitation
6. Lei will receive email invitation to install TestFlight app

**TestFlight Testing Plan**

**Internal Testers**:

- Lei (Manager) - zl.stone1992@gmail.com
- Development team (5 members)
- Product team (3 members)
- QA team (2 members)

**Test Scenarios**:

1. First-time user sign-up and authentication
2. Returning user sign-in
3. Dashboard navigation and interaction
4. Session persistence
5. Sign-out and re-authentication
6. Network failure scenarios
7. App background/foreground behavior

**Feedback Collection**:

- TestFlight feedback tool
- Slack channel for bug reports
- Weekly feedback review meetings

### 8.3 App Store Submission (MVP - Immediate Submission)

#### Pre-Submission Checklist

- [ ] HealthKit integration complete and tested
- [ ] Privacy policy URL ready (required for HealthKit)
- [ ] App Store screenshots (6.5", 5.5", 12.9" iPad)
- [ ] App Store preview video (optional but recommended)
- [ ] App icon (1024x1024 PNG)
- [ ] App description and keywords
- [ ] Support URL and marketing URL
- [ ] Age rating questionnaire completed
- [ ] Export compliance documentation

#### App Store Connect Configuration

```
App Information:
- Name: ViiRaa
- Subtitle: From Weight Control, To Body Intelligence
- Category: Health & Fitness
- Age Rating: 4+ (no restricted content)

Privacy:
- Privacy Policy URL: https://www.viiraa.com/ViiRaa_Privacy_Policy_Notice_US_20250808.pdf
- Data Collection: Health data, user profile
- HealthKit Usage: CGM data, weight, activity tracking

Pricing:
- Free app (revenue via in-app services)

App Review Information:
- Contact: support@viiraa.com
- Demo account: dev@viiraa.com / [Password to be provided during submission]
- Notes: Demo account is our development account with test data.

Version Release:
- Manual release (recommended for v1.0)
```

#### Submission Process

```bash
# 1. Complete TestFlight testing
# - Resolve all critical bugs
# - Collect tester feedback

# 2. Create App Store version
# App Store Connect → My Apps → ViiRaa → + Version

# 3. Upload build
# Same as TestFlight upload process

# 4. Fill in metadata
# - Description, keywords, screenshots
# - Privacy policy, support URL
# - Age rating, export compliance

# 5. Submit for review
# App Store Connect → Submit for Review

# 6. Review process
# - Typical review time: 24-48 hours
# - Monitor App Store Connect for status updates
# - Respond promptly to any reviewer questions

# 7. Release
# - Upon approval, release manually or automatically
```

### 8.4 App Store Approval Strategy

#### Addressing Guideline 4.2 (Minimum Functionality)

**Our Approach**:

1. **HealthKit Integration**: Demonstrates native iOS functionality not available in web browsers
2. **Native UI Shell**: Tab navigation, authentication, native loading states
3. **Mobile-Optimized Experience**: Tailored for iOS with proper UI conventions
4. **Value Proposition**: Clear explanation in App Review Notes:

```
App Review Notes Template:

"ViiRaa is a health and wellness application that combines web-based content
delivery with native iOS functionality:

1. Apple HealthKit Integration:
   - Reads CGM (glucose) data from Health app
   - Reads weight and activity data
   - Provides personalized insights based on health metrics

2. Native iOS Features:
   - Secure Keychain-based authentication
   - Native tab navigation
   - Biometric authentication support (future)

3. Web Content Integration:
   - Dashboard uses WebView for rapid feature updates
   - Ensures consistency across platforms
   - Enables real-time data synchronization

The app provides genuine value to iOS users through HealthKit integration,
enabling comprehensive health tracking not possible through a web browser alone.

Demo Account:
Email: dev@viiraa.com
Password: [Will be provided during App Review]

Please note: HealthKit permissions required for full functionality."
```

#### Contingency Plan

If rejected for Guideline 4.2:

1. **Appeal**: Explain HealthKit value proposition more clearly
2. **Enhance**: Add more native features (biometric auth, native charts)
3. **Pivot**: Consider React Native for more native UI components

### 8.5 Post-Launch Monitoring

#### Crash Reporting

- **Tool**: Xcode Organizer, Firebase Crashlytics
- **Goal**: < 0.1% crash rate
- **Action**: Monitor daily, fix critical crashes within 24 hours

#### Analytics Monitoring

- **Tool**: PostHog
- **Key Metrics**:
  - Daily Active Users (DAU)
  - Session duration
  - Authentication success rate
  - WebView load time
  - HealthKit permission grant rate

#### User Feedback

- **Channels**: App Store reviews, in-app feedback, support email
- **Process**: Weekly review meeting, prioritize issues
- **Response**: Respond to critical reviews within 48 hours

#### App Updates

- **Bug Fixes**: Release within 1 week for critical issues
- **Minor Updates**: Bi-weekly or monthly
- **Major Updates**: Quarterly with new features

---

## 9. Appendices

### 9.1 Dependencies

#### Swift Package Manager Dependencies

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
    .package(url: "https://github.com/PostHog/posthog-ios.git", from: "3.0.0"),
    .package(url: "https://github.com/tryVital/vital-ios.git", from: "1.0.0")  // Junction SDK
]
```

#### CocoaPods Dependencies (Alternative)

```ruby
# Podfile
platform :ios, '14.0'
use_frameworks!

target 'ViiRaaApp' do
  pod 'Supabase', '~> 2.0'
  pod 'PostHog', '~> 3.0'
  pod 'VitalHealthKit', '~> 1.0'  # Junction SDK
end
```

### 9.2 API Endpoints Reference

#### Web Dashboard

```
Base URL: https://viiraa.com
Dashboard: /dashboard
Auth: /auth
Auth Callback: /auth/callback
```

#### Backend API

```
Base URL: https://api.viiraa.com (via Supabase edge function)
Create Checkout: POST /api/payment/create-checkout-session
Get Config: GET /api/config
```

#### Supabase

```
Project URL: https://efwiicipqhurfcpczmnw.supabase.co
Auth: /auth/v1/
Database: /rest/v1/
```

### 9.3 Design Assets

#### App Icon Specifications

**IMPORTANT**: Use square logo for all app icons and branding.

**Source Logo**: `/Users/barack/Downloads/Xcode/Xcode/ViiRaa-Logo-Square.png`

```
AppIcon.appiconset/
├── Icon-20@2x.png (40x40)
├── Icon-20@3x.png (60x60)
├── Icon-29@2x.png (58x58)
├── Icon-29@3x.png (87x87)
├── Icon-40@2x.png (80x80)
├── Icon-40@3x.png (120x120)
├── Icon-60@2x.png (120x120)
├── Icon-60@3x.png (180x180)
└── Icon-1024.png (1024x1024)

All icons must be generated from: ViiRaa-Logo-Square.png
```

**Icon Generation Steps**:

1. Start with ViiRaa-Logo-Square.png
2. Use design tool (Figma, Sketch) or online generator to create all required sizes
3. Ensure proper padding and centering for iOS guidelines
4. Export all sizes with transparency (PNG format)
5. Replace existing icons in Assets.xcassets/AppIcon.appiconset/

#### Design Resources

- **Figma Design**: https://www.figma.com/design/OWkLJuXufkbxxXw7xgReLK/Viirra-logo?node-id=0-1&t=OPJXyIv8zBjQPBdv-1
- **Website**: https://viiraa.com

#### Color Palette

```swift
// ViiRaa Brand Colors
Primary: #A8B79E (Sage Green)
Secondary: #F5F5F5 (Light Gray)
Accent: #2C3E50 (Dark Blue)
Text: #333333 (Dark Gray)
Background: #FFFFFF (White)
```

### 9.4 Glossary

| Term                 | Definition                                         |
| -------------------- | -------------------------------------------------- |
| **WKWebView**  | Apple's modern web rendering engine for iOS        |
| **Keychain**   | iOS secure storage for sensitive data              |
| **HealthKit**  | Apple's framework for health and fitness data      |
| **Supabase**   | Open-source Firebase alternative (auth + database) |
| **TestFlight** | Apple's beta testing platform                      |
| **SwiftUI**    | Apple's declarative UI framework                   |
| **PKCE**       | Proof Key for Code Exchange (OAuth security)       |
| **CGM**        | Continuous Glucose Monitor                         |
| **APNs**       | Apple Push Notification service                    |

### 9.5 Reference Documents

- [Product Requirements Document.md](./Product%20Requirements%20Document.md)
- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple HealthKit Documentation](https://developer.apple.com/documentation/healthkit)
- [Supabase Swift SDK Documentation](https://github.com/supabase/supabase-swift)
- [PostHog iOS Documentation](https://posthog.com/docs/libraries/ios)
- [ViiRaa Web Dashboard Source Code](./viiraalanding-main/)

### 9.6 Contact Information

**Development Team**:

- Technical Lead: [Your Name]
- Backend Developer: [Backend Dev Name]
- QA Engineer: [QA Name]

**External Resources**:

- Apple Developer Support: developer.apple.com/support
- Supabase Support: supabase.com/support
- PostHog Support: posthog.com/support

---

## 10. Critical Bugs and Known Issues

### 10.1 Authentication Issues

#### 10.1.1 Google Sign-In Crash

**Status**: 🔴 Critical Bug - Pending Fix

**Description**: The app crashes when users attempt to sign in using Google OAuth authentication.

**Symptoms**:

- App crashes immediately after selecting "Sign in with Google"
- No error message displayed to user
- App terminates unexpectedly

**Impact**: High - Prevents Google OAuth users from accessing the app

**Test Account**:

- Email: reviewer@viiraa.com
- Password: ReviewPassword123

**Root Cause**: To be investigated

**Mitigation Steps**:

1. Debug Google OAuth flow in AuthManager.swift
2. Check Supabase Google OAuth configuration
3. Verify URL scheme handling in Info.plist
4. Test with physical device (not just simulator)
5. Review crash logs in Xcode Organizer

**Action Items**:

- [ ] Reproduce crash consistently
- [ ] Collect crash logs and stack traces
- [ ] Fix OAuth URL callback handling
- [ ] Test with reviewer account credentials
- [ ] Verify fix on multiple iOS versions

#### 10.1.2 Duplicate Login Prompts

**Status**: 🟡 Partially Resolved - Race Condition Remains

**Description**: Users are asked to login twice - once in the native iOS login screen and again when the WebView loads.

**Symptoms**:

- User completes authentication in native iOS screen
- Dashboard WebView loads but shows login page again
- User must enter credentials a second time
- Poor user experience and confusion
- Logs show session injection happening successfully ("✅ Session injected successfully")
- However, web dashboard still prompts for login despite session being in localStorage

**Impact**: High - Severely degrades user experience and creates authentication friction

**Root Cause - Phase 1 (RESOLVED)**:

- ✅ Session injection infrastructure now correctly implemented
- ✅ Complete Supabase session object being injected (access_token, refresh_token, expires_in, user object)
- ✅ Correct localStorage key format: `sb-efwiicipqhurfcpczmnw-auth-token`
- ✅ Dual injection points: `.atDocumentStart` and post-load via `evaluateJavaScript`
- ✅ Custom events dispatched (`ios-auth-ready`, `storage`) to notify web app
- ✅ Proper JavaScript string escaping to prevent injection vulnerabilities

**Root Cause - Phase 2 (OUTSTANDING)**:

- ❌ **Race condition**: Web dashboard's Supabase client initializes and checks localStorage BEFORE session injection takes effect
- ❌ **Client caching**: Supabase client caches "unauthenticated" state and doesn't re-check after injection
- ❌ **WebKit privacy restrictions**: "Failed to request storage access quirks from WebPrivacy" errors indicate potential ITP/privacy interference
- ❌ **Multiple injection attempts**: Log shows 5+ injection attempts, suggesting WebView reloads or injection not persisting

**Expected Behavior**:

1. User authenticates once via native iOS login
2. iOS app receives full Supabase session (access_token, refresh_token, user data)
3. Session is injected into WebView's localStorage BEFORE Supabase client initializes
4. Web dashboard recognizes existing session
5. User is automatically logged in - NO second login required

**Current Implementation Analysis** (based on log output):

```
📊 Event tracked: user_signed_in
📊 Screen viewed: MainTabView
📊 Screen viewed: Dashboard
🔄 Injecting session for user: yanghongliu2013@outlook.com  ← iOS starts injection
Failed to resolve host network app id to config...           ← WebKit networking issue
🔄 Injecting session for user: yanghongliu2013@outlook.com  ← Multiple injection attempts
Failed to request storage access quirks from WebPrivacy      ← Privacy/ITP blocking
Failed to request query parameters from WebPrivacy           ← Privacy/ITP blocking
🔄 Injecting session for user: yanghongliu2013@outlook.com  ← Still trying...
✅ Session injected successfully after page load            ← Injection succeeds
```

The log indicates:

1. Session IS being injected successfully
2. Multiple attempts suggest timing issues or WebView reloads
3. WebKit privacy errors may be interfering with localStorage access
4. Web dashboard doesn't react to injected session

**Potential Solutions**:

**Option A: Delay Web App Initialization (Requires Web Team)**

- Modify web dashboard to wait for `window.iosAuthenticated` flag before initializing Supabase
- Add polling mechanism to check for iOS session injection before proceeding
- Ensures Supabase client never initializes without session present

**Option B: Pre-Authentication Loading Page**

- Load minimal HTML page first that waits for iOS session injection
- After confirming session in localStorage, redirect to actual dashboard
- Guarantees injection happens before any Supabase client code runs

**Option C: WKWebView Data Store Reset**

- Clear WKWebView data store before loading dashboard to prevent stale state
- Ensures fresh localStorage state for each authentication

**Option D: Force Client Reinitialization (Requires Web Team)**

- After injection, send message to web app to explicitly reinitialize Supabase client
- Client fetches fresh auth state from localStorage instead of using cached value

**Option E: Remove Native Login (Pragmatic)**

- Have users authenticate directly in WebView instead of native iOS screen
- Eliminates session-sharing complexity entirely
- Trade-off: Less "native" feel, but guaranteed to work

**Action Items**:

- [X] Add comprehensive logging to session injection code ✅
- [X] Verify complete session object is being injected ✅
- [X] Ensure timing of injection (before and after page load) ✅
- [X] Validate session format matches Supabase expectations ✅
- [ ] **NEXT: Coordinate with web team to implement Option A or D**
- [ ] Test Option B (pre-authentication loading page) as iOS-only solution
- [ ] Investigate WebKit Storage Access API for iOS 17.4+
- [ ] Add precise timestamps to all logs to track exact event sequence
- [ ] Consider Option E if other solutions prove too complex

**References**:

- Implementation: [DashboardWebView.swift](Xcode/Core/WebView/DashboardWebView.swift:73-150)
- Bug Analysis: [Learnings_From_Doing.md Bug 7](Xcode/Learnings_From_Doing.md:287-447)
- Log Evidence: See bug report log output

### 10.2 HealthKit Permission Issues

#### 10.2.1 HealthKit "Access Denied" Display Bug

**Status**: 🔴 Critical Bug - Pending Fix

**Description**: Settings screen shows "Access denied" even when HealthKit permissions have been granted by the user.

**Symptoms**:

- User grants HealthKit permissions during initial setup
- Settings screen displays "Access denied" status
- Permission status does not update correctly
- Status persists across app launches

**Impact**: High - Confuses users who have already granted permissions and prevents them from understanding their actual permission state

**Root Cause**: To be investigated

- Possible issues with HKAuthorizationStatus checking logic
- Authorization status retrieval may not be using correct API
- Permission status may not persist correctly across app sessions
- Edge cases with partial permissions not handled properly

**Expected Behavior**:

1. User grants HealthKit permissions
2. Settings screen accurately reflects "Access granted" status
3. Status persists across app launches
4. Correct status indicators displayed (green checkmark for granted, orange warning for denied)

**Investigation Steps**:

1. Review `checkHealthKitAuthStatus()` function in SettingsView
2. Verify correct usage of `healthStore.authorizationStatus(for:)` API
3. Test permission status retrieval timing (may need delay after grant)
4. Check if authorization status is cached incorrectly
5. Test across multiple iOS versions and devices
6. Verify proper handling of `.notDetermined`, `.sharingDenied`, `.sharingAuthorized` states

**Mitigation Steps**:

1. Add logging to track authorization status changes
2. Implement proper status refresh mechanism (pull-to-refresh or manual refresh button)
3. Add delay after permission grant before checking status
4. Test with all HealthKit data types (glucose, weight, activity)
5. Verify authorization status query happens on main thread

**Action Items**:

- [ ] Debug authorization status checking logic in SettingsView.swift
- [ ] Add comprehensive logging for permission state changes
- [ ] Test permission status persistence across app launches
- [ ] Implement proper error handling for authorization status queries
- [ ] Add manual refresh capability for permission status
- [ ] Test with reviewer account and multiple test scenarios
- [ ] Document correct HealthKit authorization status API usage

**Related Code**:

- Implementation: [MainTabView.swift - SettingsView](Software_Development_Document.md:959-1039)
- HealthKit Manager: [HealthKitManager.swift](Software_Development_Document.md:1057-1218)

### 10.3 Design and Branding Issues

#### 10.3.1 Logo Asset Update Required

**Status**: 🟡 Pending - Design Update

**Description**: App currently uses incorrect logo. Must use square logo asset for all branding.

**Impact**: Medium - Affects app branding and App Store presentation

**Asset Location**: `/Users/barack/Downloads/Xcode/Xcode/ViiRaa-Logo-Square.png`

**Update Required In**:

- [ ] App Icon (AppIcon.appiconset)
- [ ] Splash screen
- [ ] About section in Settings
- [ ] App Store screenshots

**Action Items**:

- [ ] Replace app icon with square logo
- [ ] Update splash screen design
- [ ] Regenerate all icon sizes (20pt to 1024pt)
- [ ] Update App Store Connect assets

### 10.4 Junction Sync Issues

#### 10.4.1 Bug #21: Glucose Data Not Syncing to Junction Dashboard

**Status**: 🔴 Active - Under Investigation

**Report Date**: 2025-12-11

**Description**: Blood glucose data exists in Apple Health but does NOT appear in Junction dashboard, despite Apple Health showing as "Connected" in Junction.

**User**: `dev@viiraa.com` (Junction user_id: `5c9657f5-c5cf-47fb-ac64-9f0774604445`)

**Symptoms**:

- Apple Health contains glucose readings (Dec 1: 120 mg/dL, Dec 2: 123 mg/dL, Dec 11: 124 mg/dL)
- Junction dashboard shows Apple Health as "Connected"
- Blood Glucose data section in Junction dashboard is empty
- App logs show "✅ Junction sync initiated" and "📊 Event tracked: junction_sync_success"
- No error messages in sync flow

**Impact**: High - Users cannot verify their glucose data is syncing to Junction for ML training

**Root Cause Analysis** (from [Learnings_From_Doing.md Bug #21](Learnings_From_Doing.md)):

1. **Read-Only HealthKit Permissions**: ViiRaa only has READ permissions for HealthKit, not WRITE permissions. The app reads glucose data for display but doesn't generate or write data to HealthKit.

2. **Data Source Attribution**: Junction may only sync data from recognized CGM device sources. Manually entered glucose data in Apple Health may have different source attribution that Junction doesn't recognize or filter out.

3. **Dual Permission System**: The app has TWO separate HealthKit permission flows:
   - `HealthKitManager.requestAuthorization()` - Direct HealthKit access for app display
   - `VitalHealthKitClient.shared.ask()` - Junction SDK access for cloud sync

   If user granted permissions through one system but declined the other, Junction won't receive glucose data.

4. **False Success Indicators**: The app marks sync as "success" immediately after calling `VitalHealthKitClient.shared.syncData()` without verifying data actually reached Junction's servers.

5. **3-Hour Delay Misunderstanding**: The 3-hour HealthKit delay only applies to recent readings. Historical data beyond 3 hours (Dec 1, Dec 2) should sync immediately but isn't appearing.

**Conflicts with SDD**:

- Line 1432: "Data Delay Note" - Doesn't explain data source requirements
- Line 1138: `typesToWrite: Set<HKSampleType> = []` - Read-only permissions not explained
- Line 1465: `writePermissions: []` - Same issue in Junction SDK example

**Potential Solutions** (Not Implemented Yet):

1. **Consolidate Permission Flows**: Use only `VitalHealthKitClient.shared.ask()` for all HealthKit permissions to ensure Junction SDK always has the same permissions as the app

2. **Add Sync Verification**: After `syncData()`, query Junction API to verify data exists:
   ```swift
   func verifySyncSuccess() async -> Bool {
       let glucoseCount = try? await fetchGlucoseFromCloud(
           startDate: Date().addingTimeInterval(-30*24*60*60),
           endDate: Date()
       )
       return (glucoseCount?.count ?? 0) > 0
   }
   ```

3. **Add Debug Logging**: Log VitalHealthKitClient permission status for glucose:
   ```swift
   let status = await VitalHealthKitClient.shared.authorizationStatus(for: .vitals(.glucose))
   print("🔍 VitalHealthKitClient glucose permission status: \(status)")
   ```

4. **Implement CGM Data Source (Phase 3)**: Implement BLE Follow Mode for Abbott Lingo to capture real-time glucose and write to HealthKit with ViiRaa source attribution

**Testing Recommendations**:

1. Add NEW glucose reading with timestamp > 3 hours old
2. Trigger manual sync via `JunctionManager.shared.syncHealthData()`
3. Wait 5 minutes for background upload
4. Check Junction dashboard - verify data appears
5. If missing: Check source attribution in Apple Health app

**Action Items**:

- [ ] Verify VitalHealthKitClient has glucose permission (`.vitals(.glucose)`)
- [ ] Add sync verification API call to confirm data reached Junction
- [ ] Add detailed logging for permission mismatches between HealthKitManager and VitalHealthKitClient
- [ ] Test with fresh glucose data that has timestamp > 3 hours old
- [ ] Query Junction API for sync error logs
- [ ] Consider Phase 3 BLE implementation for reliable data source

**Related Files**:

- Bug Analysis: [Learnings_From_Doing.md Bug #21](Learnings_From_Doing.md)
- Junction Manager: [JunctionManager.swift:536-554](Xcode/Services/Junction/JunctionManager.swift#L536-L554) - Permission request
- HealthKit Manager: [HealthKitManager.swift:41-76](Xcode/Services/HealthKit/HealthKitManager.swift#L41-L76) - Direct authorization
- Auth Manager: [AuthManager.swift:198-204](Xcode/Core/Authentication/AuthManager.swift#L198-L204) - Junction connection flow

**Key Learnings**:

1. "Connected" status only means provider link exists, NOT that data is flowing
2. Read-only HealthKit access ≠ Data source for Junction sync
3. "Sync success" in logs doesn't verify data reached Junction servers
4. Must verify at destination (Junction dashboard), not just at source

---

## 11. Build Issues and Troubleshooting

### 11.1 Common Build Errors

This section documents build errors encountered during initial project setup and their resolutions.

#### 11.1.1 Supabase SDK Integration Issues

**Issue**: Type name conflicts and incorrect API usage when integrating Supabase Swift SDK.

**Symptoms**:

- `'Client' is not a member type of class 'SupabaseClient'`
- `Cannot find type 'DatabaseClient' in scope`
- `Extra arguments at positions #2, #3 in call`

**Root Cause**:

- Class naming conflict: Custom `SupabaseClient` class conflicted with SDK's `SupabaseClient` type
- Incorrect type names: Using `DatabaseClient` instead of `PostgrestClient`
- Outdated API usage: Using deprecated initialization parameters

**Solution**:

1. Rename custom class to `SupabaseManager` to avoid naming conflicts
2. Use correct type `PostgrestClient` for database access
3. Simplify client initialization:
   ```swift
   client = SupabaseClient(
       supabaseURL: url,
       supabaseKey: Constants.supabaseAnonKey
   )
   ```
4. Update all references from `SupabaseClient.shared` to `SupabaseManager.shared`

#### 11.1.2 PostHog SDK Migration

**Issue**: Using deprecated PostHog Objective-C SDK instead of modern Swift SDK.

**Symptoms**:

- `Cannot find type 'PHGPostHog' in scope`
- `Cannot find 'PHGPostHogConfiguration' in scope`

**Root Cause**:

- Documentation referenced legacy Objective-C SDK (`PHGPostHog`)
- Modern PostHog iOS SDK uses different API (`PostHogSDK`)

**Solution**:

1. Update to PostHog Swift SDK v3.x
2. Replace initialization code:
   ```swift
   // Old (Objective-C SDK)
   PHGPostHog.setup(with: configuration)

   // New (Swift SDK)
   PostHogSDK.shared.setup(config)
   ```
3. Update API calls:
   - `posthog?.capture()` → `PostHogSDK.shared.capture()`
   - `posthog?.identify()` → `PostHogSDK.shared.identify()`
4. Remove unsupported config options like `captureDeepLinks`

#### 11.1.3 ObservableObject Conformance with @MainActor

**Issue**: `@MainActor` annotation on class preventing proper `ObservableObject` conformance.

**Symptoms**:

- `Type 'AnalyticsManager' does not conform to protocol 'ObservableObject'`
- Missing `objectWillChange` publisher

**Root Cause**:

- Swift concurrency requires explicit `objectWillChange` publisher when using `@MainActor` on ObservableObject classes
- Default synthesis doesn't work with actor isolation

**Solution**:

1. Add explicit `objectWillChange` publisher with `nonisolated` annotation:
   ```swift
   @MainActor
   class AnalyticsManager: ObservableObject {
       nonisolated let objectWillChange = ObservableObjectPublisher()
       // ... rest of class
   }
   ```
2. Import `Combine` framework for `ObservableObjectPublisher`

#### 11.1.4 Auth API Compatibility

**Issue**: Supabase Auth API changes causing type mismatches and compilation errors.

**Symptoms**:

- `Cannot find type 'AuthState' in scope`
- `Cannot convert value of type 'TimeInterval' to expected argument type 'Int'`
- `Cannot convert value of type 'Auth.User' to expected argument type 'User'`
- OAuth returning Session instead of URL

**Root Cause**:

- Supabase SDK v2.x changed auth state handling from `AuthState` to `AuthChangeEvent`
- Session properties changed types (expiresIn is now Double instead of Int)
- Custom User model differs from Supabase's Auth.User type
- OAuth flow changed to return Session directly

**Solution**:

1. Update auth state handling:

   ```swift
   // Old: AuthState
   case .signedIn(let session):

   // New: AuthChangeEvent
   case .signedIn, .tokenRefreshed, .initialSession:
   ```
2. Add conversion helpers:

   ```swift
   private func convertSession(_ supabaseSession: Supabase.Session) -> Session {
       return Session(
           accessToken: supabaseSession.accessToken,
           refreshToken: supabaseSession.refreshToken,
           expiresIn: Int(supabaseSession.expiresIn), // Convert Double to Int
           tokenType: supabaseSession.tokenType,
           user: convertUser(supabaseSession.user)
       )
   }

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
3. Update OAuth flow:

   ```swift
   func signInWithGoogle() async throws {
       let oauthSession = try await supabase.auth.signInWithOAuth(provider: .google)
       let session = convertSession(oauthSession)
       await handleSuccessfulAuth(session: session)
   }
   ```
4. Import UIKit for UIApplication:

   ```swift
   import UIKit
   ```

#### 11.1.5 Project Configuration Issues

**Issue**: Incorrect absolute path in Info.plist configuration causing build failure.

**Symptoms**:

- `Build input file cannot be found: '/251015-Xcode/251015-Xcode/Resources/Info.plist'`

**Root Cause**:

- Xcode project configuration had absolute path starting with `/` instead of relative path
- Path was incorrectly formatted as `/251015-Xcode/...` instead of `251015-Xcode/...`

**Solution**:

1. Update project.pbxproj with correct relative path:
   ```
   INFOPLIST_FILE = "251015-Xcode/Resources/Info.plist";
   ```
2. Ensure path is relative to project root, not absolute

### 11.2 Build Verification Checklist

After resolving build errors, verify the following:

- [ ] Project builds successfully for iOS Simulator
- [ ] All Swift Package dependencies resolved correctly
- [ ] Code signing configured properly
- [ ] Info.plist path is correct and file exists
- [ ] No compiler warnings related to deprecated APIs
- [ ] Authentication manager initializes without errors
- [ ] Analytics manager initializes without errors
- [ ] WebView configuration is valid

### 11.3 SDK Version Requirements

Ensure the following SDK versions are used to avoid compatibility issues:

| SDK                   | Minimum Version | Recommended Version |
| --------------------- | --------------- | ------------------- |
| Supabase Swift        | 2.5.1           | Latest 2.x          |
| PostHog iOS           | 3.34.0          | Latest 3.x          |
| Junction (Vital) iOS  | 1.0.0           | Latest 1.x          |
| iOS Deployment Target | 14.0            | 14.0+               |
| Swift                 | 5.0             | 5.9+                |
| Xcode                 | 14.0            | 15.0+               |

---

## Document History

| Version | Date       | Author      | Changes                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ------- | ---------- | ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0     | 2025-10-12 | Claude Code | Initial comprehensive SDD based on PRD                                                                                                                                                                                                                                                                                                                                                                                                                          |
| 1.1     | 2025-10-15 | Claude Code | Added build issues troubleshooting section with SDK integration fixes                                                                                                                                                                                                                                                                                                                                                                                           |
| 1.2     | 2025-10-20 | Claude Code | Updated based on Lei's feedback: simplified sign-out to web-only                                                                                                                                                                                                                                                                                                                                                                                                |
| 1.3     | 2025-10-27 | Claude Code | Updated per Lei's feedback: emphasized Time In Range & Peak Glucose metrics, added TestFlight setup for Lei (zl.stone1992@gmail.com), updated to MVP dual submission strategy                                                                                                                                                                                                                                                                                   |
| 1.4     | 2025-11-11 | Claude Code | Updated based on manager feedback: Added critical bugs section (Google Sign-In crash, duplicate login prompts), added Settings screen with HealthKit permissions management, updated app branding to reference square logo, added new Phase 2 requirements (FR-2.6 to FR-2.11)                                                                                                                                                                                  |
| 1.5     | 2025-11-20 | Claude Code | Updated based on November manager feedback: Added WhatsApp redirect for Chat tab (FR-1.6, lines 102, 868-957), added HealthKit "Access denied" bug documentation (FR-2.7, lines 2414-2468), updated ChatPlaceholderView to ChatWhatsAppView with WhatsApp integration (https://wa.me/18882087058)                                                                                                                                                               |
| 1.6     | 2025-11-25 | Claude Code | Added Junction SDK Integration per PRD update: Added FR-2.13 (line 121), added Third-Party Health Data Integration section (lines 87-93), added Section 4.3 Junction SDK Integration with JunctionManager.swift implementation (lines 1400-1507), updated dependencies (lines 2270, 2284), added Junction to SDK version requirements (line 2817)                                                                                                               |
| 1.7     | 2025-12-02 | Claude Code | Added BLE Follow Mode Integration per PRD Section 12 (lines 805-1003): Added Phase 3 requirements (FR-3.1 to FR-3.5), added Section 4.4 BLE Follow Mode Integration with BLEFollowManager.swift implementation, BLEFollowSettingsView UI, hybrid architecture with Junction SDK, legal compliance considerations, cost-benefit analysis, success metrics, Info.plist Bluetooth configuration, renumbered subsequent sections (4.5 Analytics, 4.6 Configuration) |
| 1.8     | 2025-12-10 | Claude Code | Added Glucose Prediction Feature per PRD update: Added FR-2.14 (line 131), added Section 4.5 Glucose Prediction Feature Integration with GlucosePredictionWebView implementation (lines 2042-2142), updated section numbering (4.6 Analytics, 4.7 Configuration), updated document status |
| 1.8.1   | 2025-12-10 | Claude Code | **IMPLEMENTED** Glucose Prediction Feature: Created GlucosePredictionWebView.swift (Xcode/Features/HealthKit/), updated GlucoseView.swift with NavigationLink to predictions, updated MainTabView.swift to pass authManager environment object, implemented PredictionWebViewContainer with session injection, added GlucosePredictionDetailView for deep linking support, added analytics tracking for prediction views |
| 1.9     | 2025-12-16 | Claude Code | **Bug #21 Root Cause Analysis**: Added Section 10.4 Junction Sync Issues with Bug #21 documentation (glucose data not syncing to Junction dashboard). Expanded Section 4.3.1 Data Delay Note with critical data source requirements (lines 1434-1448). Root causes identified: read-only HealthKit permissions, dual permission system, false success indicators, data source attribution issues. Added testing recommendations and potential solutions. References [Learnings_From_Doing.md Bug #21](Learnings_From_Doing.md) |

---

**End of Software Development Documentation**
