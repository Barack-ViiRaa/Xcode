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
        // Update WebView if needed
        // Check if we need to update the session
        if let session = session {
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
            // Full Supabase session data
            const sessionData = {
                access_token: '\(escapedAccessToken)',
                refresh_token: '\(escapedRefreshToken)',
                expires_in: \(session.expiresIn),
                token_type: '\(session.tokenType)',
                user: {
                    id: '\(escapedUserId)',
                    email: '\(escapedUserEmail)',
                    aud: 'authenticated',
                    role: 'authenticated'
                }
            };

            // Store in the format Supabase expects
            const storageKey = 'sb-efwiicipqhurfcpczmnw-auth-token';

            try {
                // Store the full session in localStorage
                localStorage.setItem(storageKey, JSON.stringify(sessionData));
                console.log('✅ iOS Supabase session injected successfully');

                // Also set global flags for iOS app
                window.iosAuthenticated = true;
                window.iosSession = sessionData;

                // Dispatch custom event to notify web app
                window.dispatchEvent(new CustomEvent('ios-auth-ready', {
                    detail: {
                        session: sessionData,
                        authenticated: true
                    }
                }));
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
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: DashboardWebView
        weak var webView: WKWebView?

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

            // Inject session again after page load to ensure it's set
            if let session = parent.session {
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
                        token_type: '\(session.tokenType)',
                        user: {
                            id: '\(escapedUserId)',
                            email: '\(escapedUserEmail)',
                            aud: 'authenticated',
                            role: 'authenticated'
                        }
                    };

                    const storageKey = 'sb-efwiicipqhurfcpczmnw-auth-token';

                    try {
                        localStorage.setItem(storageKey, JSON.stringify(sessionData));
                        window.iosAuthenticated = true;
                        window.iosSession = sessionData;
                        console.log('✅ Session re-injected after page load');

                        // Trigger storage event to notify Supabase client
                        window.dispatchEvent(new Event('storage'));
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
