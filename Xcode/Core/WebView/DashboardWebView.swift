//
//  DashboardWebView.swift
//  ViiRaaApp
//
//  Created by ViiRaa Team
//  Copyright © 2025 ViiRaa. All rights reserved.
//

import SwiftUI
import WebKit

struct DashboardWebView: UIViewRepresentable {
    let url: URL
    let session: Session?
    @Binding var isLoading: Bool

    // Backward compatibility - kept for reference but using session now
    var authToken: String? {
        session?.accessToken
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Track whether session has been injected to prevent re-injection loop
    private static var injectedSessionUserId: String?

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        // Configure JavaScript message handlers
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "nativeApp")
        configuration.userContentController = contentController

        // Enable JavaScript (using non-deprecated approach)
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        // Allow inline media playback
        configuration.allowsInlineMediaPlayback = true

        // Create WebView
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        // Store webView reference in coordinator
        context.coordinator.webView = webView

        // Set background color
        webView.backgroundColor = .systemBackground
        webView.isOpaque = false

        // Inject session if available
        if let session = session {
            injectSession(webView: webView, session: session)
        }

        // Load dashboard URL
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        webView.load(request)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // ⚠️ DO NOT re-inject session here - causes infinite loop
        // Session is already injected in makeUIView and didFinish
        // Only inject if session user ID has changed (user switched accounts)
        if let session = session,
           DashboardWebView.injectedSessionUserId != session.user.id {
            print("⚠️ User account changed, re-injecting session")
            injectSession(webView: webView, session: session)
        }
    }

    private func injectSession(webView: WKWebView, session: Session) {
        // Escape tokens for safe JavaScript injection
        let escapedAccessToken = session.accessToken.replacingOccurrences(of: "'", with: "\\'")
        let escapedRefreshToken = session.refreshToken.replacingOccurrences(of: "'", with: "\\'")
        let escapedUserId = session.user.id.replacingOccurrences(of: "'", with: "\\'")
        let escapedUserEmail = session.user.email.replacingOccurrences(of: "'", with: "\\'")

        let script = """
        (function() {
            console.log('🔄 iOS Session Injection - Starting...');

            // Full Supabase session data
            const sessionData = {
                access_token: '\(escapedAccessToken)',
                refresh_token: '\(escapedRefreshToken)',
                expires_in: \(session.expiresIn),
                expires_at: Math.floor(Date.now() / 1000) + \(session.expiresIn),
                token_type: '\(session.tokenType)',
                user: {
                    id: '\(escapedUserId)',
                    email: '\(escapedUserEmail)',
                    aud: 'authenticated',
                    role: 'authenticated',
                    email_confirmed_at: new Date().toISOString(),
                    app_metadata: {},
                    user_metadata: {}
                }
            };

            // Store in the format Supabase expects
            const storageKey = 'sb-efwiicipqhurfcpczmnw-auth-token';

            try {
                // Store the full session in localStorage
                localStorage.setItem(storageKey, JSON.stringify(sessionData));
                console.log('✅ iOS Supabase session injected successfully');
                console.log('📝 Session data:', {
                    user_id: sessionData.user.id,
                    user_email: sessionData.user.email,
                    has_access_token: !!sessionData.access_token,
                    has_refresh_token: !!sessionData.refresh_token
                });

                // Set global flags for iOS app - CRITICAL for web app detection
                window.iosAuthenticated = true;
                window.iosSession = sessionData;
                window.isIOSApp = true;

                // Create a function to skip Google OAuth on web
                window.skipWebAuth = true;

                // Dispatch custom event to notify web app IMMEDIATELY
                window.dispatchEvent(new CustomEvent('ios-auth-ready', {
                    detail: {
                        session: sessionData,
                        authenticated: true,
                        source: 'ios-native'
                    }
                }));

                // Trigger storage event for Supabase client listening
                window.dispatchEvent(new StorageEvent('storage', {
                    key: storageKey,
                    newValue: JSON.stringify(sessionData),
                    url: window.location.href,
                    storageArea: localStorage
                }));

                // Verify storage
                const stored = localStorage.getItem(storageKey);
                if (stored) {
                    console.log('✅ Verified: Session successfully stored in localStorage');
                } else {
                    console.error('❌ Verification failed: Session not found in localStorage');
                }

                // ❌ REMOVED: Auto-reload causes infinite loop
                // The web app should detect ios-auth-ready event and react accordingly
                // Do NOT force reload from iOS side

            } catch (e) {
                console.error('❌ Failed to inject session:', e);
            }
        })();
        """

        let userScript = WKUserScript(
            source: script,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )

        webView.configuration.userContentController.addUserScript(userScript)

        // Log injection attempt in native code and track injected user
        print("🔄 Injecting session for user: \(session.user.email)")
        DashboardWebView.injectedSessionUserId = session.user.id
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: DashboardWebView
        weak var webView: WKWebView?
        var hasInjectedPostLoad = false  // Guard flag to prevent re-injection loop

        init(_ parent: DashboardWebView) {
            self.parent = parent
        }

        // MARK: - Navigation Delegate Methods

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }

            // ⚠️ GUARD: Only inject once per session to prevent infinite loop
            guard !hasInjectedPostLoad else {
                print("⏭️ Skipping post-load injection - already injected")
                return
            }

            // Inject session again after page load to ensure it's set
            if let session = parent.session {
                hasInjectedPostLoad = true  // Set flag BEFORE injection to prevent re-entry
                let escapedAccessToken = session.accessToken.replacingOccurrences(of: "'", with: "\\'")
                let escapedRefreshToken = session.refreshToken.replacingOccurrences(of: "'", with: "\\'")
                let escapedUserId = session.user.id.replacingOccurrences(of: "'", with: "\\'")
                let escapedUserEmail = session.user.email.replacingOccurrences(of: "'", with: "\\'")

                let script = """
                (function() {
                    const sessionData = {
                        access_token: '\(escapedAccessToken)',
                        refresh_token: '\(escapedRefreshToken)',
                        expires_in: \(session.expiresIn),
                        expires_at: Math.floor(Date.now() / 1000) + \(session.expiresIn),
                        token_type: '\(session.tokenType)',
                        user: {
                            id: '\(escapedUserId)',
                            email: '\(escapedUserEmail)',
                            aud: 'authenticated',
                            role: 'authenticated',
                            email_confirmed_at: new Date().toISOString(),
                            app_metadata: {},
                            user_metadata: {}
                        }
                    };

                    const storageKey = 'sb-efwiicipqhurfcpczmnw-auth-token';

                    try {
                        localStorage.setItem(storageKey, JSON.stringify(sessionData));
                        window.iosAuthenticated = true;
                        window.iosSession = sessionData;
                        window.isIOSApp = true;
                        window.skipWebAuth = true;
                        console.log('✅ Session re-injected after page load');

                        // Dispatch custom event
                        window.dispatchEvent(new CustomEvent('ios-auth-ready', {
                            detail: {
                                session: sessionData,
                                authenticated: true,
                                source: 'ios-native-postload'
                            }
                        }));

                        // Trigger storage event to notify Supabase client
                        window.dispatchEvent(new StorageEvent('storage', {
                            key: storageKey,
                            newValue: JSON.stringify(sessionData),
                            url: window.location.href,
                            storageArea: localStorage
                        }));

                        // ❌ REMOVED: Auto-reload causes infinite loop
                        // The web dashboard should listen for ios-auth-ready event
                        // and handle authentication without requiring reload
                    } catch (e) {
                        console.error('❌ Failed to re-inject session:', e);
                    }
                })();
                """
                webView.evaluateJavaScript(script) { result, error in
                    if let error = error {
                        print("❌ Error injecting session: \(error.localizedDescription)")
                    } else {
                        print("✅ Session injected successfully after page load")
                    }
                }
            }

            // Hide web dashboard logout button (iOS handles sign-out natively)
            hideWebLogoutButton(webView: webView)

            // Inject HealthKit data after page load if available
            injectHealthKitData(webView: webView)
        }

        private func injectHealthKitData(webView: WKWebView) {
            // Check if HealthKit is enabled and authorized
            guard Constants.isHealthKitEnabled,
                  HealthKitManager.shared.isAuthorized else {
                return
            }

            // Fetch health data asynchronously
            Task {
                do {
                    let healthSummary = try await HealthKitManager.shared.fetchTodayHealthSummary()

                    // Convert to JSON string
                    let jsonData = try JSONSerialization.data(withJSONObject: healthSummary)
                    guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                        return
                    }

                    // Inject health data into WebView
                    let script = """
                    (function() {
                        try {
                            window.iosHealthData = \(jsonString);
                            window.dispatchEvent(new CustomEvent('ios-health-data-ready', {
                                detail: window.iosHealthData
                            }));
                            console.log('✅ iOS HealthKit data injected successfully');
                        } catch (e) {
                            console.error('❌ Failed to inject health data:', e);
                        }
                    })();
                    """

                    await MainActor.run {
                        webView.evaluateJavaScript(script) { result, error in
                            if let error = error {
                                print("❌ Error injecting health data: \(error.localizedDescription)")
                            } else {
                                print("✅ HealthKit data injected successfully")
                            }
                        }
                    }

                    // Track successful health data injection
                    AnalyticsManager.shared.track(event: "healthkit_data_injected", properties: [
                        "data_types": Array(healthSummary.keys)
                    ])
                } catch {
                    print("❌ Error fetching health data: \(error.localizedDescription)")
                }
            }
        }

        private func hideWebLogoutButton(webView: WKWebView) {
            // Inject CSS and JavaScript to hide the web dashboard's logout button
            // Since iOS provides native sign-out in Settings and Dashboard menu,
            // we hide the web logout button to avoid redundancy and confusion
            let script = """
            (function() {
                console.log('🔒 iOS: Hiding web logout button (native sign-out available)');

                // Add CSS to hide logout/sign-out buttons
                const style = document.createElement('style');
                style.textContent = `
                    /* Hide logout button by common selectors */
                    button[data-testid*="logout"],
                    button[data-testid*="signout"],
                    button[data-testid*="sign-out"],
                    a[href*="logout"],
                    a[href*="signout"],
                    a[href*="sign-out"],
                    .logout-button,
                    .signout-button,
                    .sign-out-button,
                    #logout-button,
                    #signout-button,
                    #sign-out-button,
                    button:has-text("Log Out"),
                    button:has-text("Logout"),
                    button:has-text("Sign Out"),
                    button:has-text("Signout") {
                        display: none !important;
                        visibility: hidden !important;
                        opacity: 0 !important;
                        pointer-events: none !important;
                    }
                `;
                document.head.appendChild(style);

                // Also search DOM for logout buttons and hide them directly
                function hideLogoutButtons() {
                    const selectors = [
                        'button[data-testid*="logout"]',
                        'button[data-testid*="signout"]',
                        'button[data-testid*="sign-out"]',
                        'a[href*="logout"]',
                        'a[href*="signout"]',
                        'button',
                        'a'
                    ];

                    selectors.forEach(selector => {
                        document.querySelectorAll(selector).forEach(el => {
                            const text = el.textContent?.toLowerCase() || '';
                            const ariaLabel = el.getAttribute('aria-label')?.toLowerCase() || '';

                            if (text.includes('log out') ||
                                text.includes('logout') ||
                                text.includes('sign out') ||
                                text.includes('signout') ||
                                ariaLabel.includes('log out') ||
                                ariaLabel.includes('logout') ||
                                ariaLabel.includes('sign out') ||
                                ariaLabel.includes('signout')) {
                                el.style.display = 'none';
                                el.style.visibility = 'hidden';
                                el.style.opacity = '0';
                                el.style.pointerEvents = 'none';
                                console.log('🔒 Hidden logout element:', el);
                            }
                        });
                    });
                }

                // Run immediately
                hideLogoutButtons();

                // Run after DOM changes (for dynamically loaded content)
                const observer = new MutationObserver(() => {
                    hideLogoutButtons();
                });

                observer.observe(document.body, {
                    childList: true,
                    subtree: true
                });

                console.log('✅ Web logout button hiding initialized');
            })();
            """

            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("❌ Error hiding web logout button: \(error.localizedDescription)")
                } else {
                    print("✅ Web logout button hidden successfully")
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            print("WebView navigation error: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            print("WebView provisional navigation error: \(error.localizedDescription)")
        }

        // MARK: - JavaScript Message Handler

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
            case "logout":
                Task {
                    try? await AuthManager.shared.signOut()
                }

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

            case "error":
                if let errorMessage = payload as? String {
                    print("Web error: \(errorMessage)")
                }

            case "requestHealthData":
                // Web requesting fresh health data
                Task {
                    await refreshHealthData()
                }

            case "requestHealthKitAuth":
                // Web requesting HealthKit authorization
                Task {
                    await requestHealthKitPermission()
                }

            default:
                print("Unknown message type: \(type)")
            }
        }

        @MainActor
        private func refreshHealthData() async {
            guard let webView = self.webView else { return }
            injectHealthKitData(webView: webView)
        }

        @MainActor
        private func requestHealthKitPermission() async {
            do {
                try await HealthKitManager.shared.requestAuthorization()
                // After authorization, inject health data
                if let webView = self.webView {
                    injectHealthKitData(webView: webView)
                }
            } catch {
                print("❌ Failed to authorize HealthKit: \(error.localizedDescription)")
            }
        }
    }
}
