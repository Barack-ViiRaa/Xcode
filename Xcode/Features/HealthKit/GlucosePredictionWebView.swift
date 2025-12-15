//
//  GlucosePredictionWebView.swift
//  ViiRaaApp
//
//  Created by ViiRaa Team
//  Copyright © 2025 ViiRaa. All rights reserved.
//
//  Glucose Prediction Feature - WebView Integration
//  Reuses existing web implementation from viiraa.com/predict-glucose
//  See SDD Section 4.5 and PRD Section 4.2 (Lines 192-199)
//

import SwiftUI
import WebKit

/// GlucosePredictionWebView - Displays glucose predictions via WebView
///
/// User Journey:
/// 1. User navigates to Glucose Tab in iOS app
/// 2. User taps "View Glucose Predictions" to access this view
/// 3. User can view all predictions or create new prediction at viiraa.com/predict-glucose
/// 4. User can view individual prediction charts at viiraa.com/predict-glucose/{prediction-id}
///
/// Implementation: WebView-based integration (no native code rewrite required)
/// Source: /Users/barack/Downloads/251210-viiraalanding-main
struct GlucosePredictionWebView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    // URL for glucose prediction page
    private let predictionURL = URL(string: "https://www.viiraa.com/predict-glucose")!

    var body: some View {
        ZStack {
            // WebView with prediction page
            if let session = authManager.session {
                PredictionWebViewContainer(
                    url: predictionURL,
                    session: session,
                    isLoading: $isLoading
                )
            } else {
                // Handle case where session is not available
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)

                    Text("Authentication Required")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Please sign in to view glucose predictions.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(action: {
                        dismiss()
                    }) {
                        Text("Go Back")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color("PrimaryColor"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }

            // Loading overlay
            if isLoading && authManager.session != nil {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading predictions...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground).opacity(0.9))
            }
        }
        .navigationTitle("Glucose Predictions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Track analytics event
                    AnalyticsManager.shared.track(event: "glucose_prediction_refresh", properties: [:])
                    isLoading = true
                    // WebView will handle the refresh
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .onAppear {
            // Track when user views prediction page
            AnalyticsManager.shared.track(event: "glucose_prediction_viewed", properties: [
                "source": "glucose_tab"
            ])
        }
    }
}

/// Internal WebView container for glucose predictions
/// Reuses the same session injection pattern as DashboardWebView
struct PredictionWebViewContainer: UIViewRepresentable {
    let url: URL
    let session: Session
    @Binding var isLoading: Bool

    // Track whether session has been injected to prevent re-injection loop
    private static var injectedSessionUserId: String?

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

        // Inject session for authentication
        injectSession(webView: webView, session: session)

        // Load prediction URL
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        webView.load(request)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only re-inject if session user ID has changed (user switched accounts)
        if PredictionWebViewContainer.injectedSessionUserId != session.user.id {
            print("⚠️ User account changed, re-injecting session for predictions")
            injectSession(webView: webView, session: session)
        }
    }

    private func injectSession(webView: WKWebView, session: Session) {
        // Same session injection logic as DashboardWebView
        // This ensures the user is authenticated when accessing prediction pages
        let escapedAccessToken = session.accessToken.replacingOccurrences(of: "'", with: "\\'")
        let escapedRefreshToken = session.refreshToken.replacingOccurrences(of: "'", with: "\\'")
        let escapedUserId = session.user.id.replacingOccurrences(of: "'", with: "\\'")
        let escapedUserEmail = session.user.email.replacingOccurrences(of: "'", with: "\\'")

        let script = """
        (function() {
            console.log('🔄 iOS Session Injection for Predictions - Starting...');

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
                console.log('✅ iOS Supabase session injected for predictions');

                window.iosAuthenticated = true;
                window.iosSession = sessionData;
                window.isIOSApp = true;
                window.skipWebAuth = true;

                window.dispatchEvent(new CustomEvent('ios-auth-ready', {
                    detail: {
                        session: sessionData,
                        authenticated: true,
                        source: 'ios-native-predictions'
                    }
                }));

                window.dispatchEvent(new StorageEvent('storage', {
                    key: storageKey,
                    newValue: JSON.stringify(sessionData),
                    url: window.location.href,
                    storageArea: localStorage
                }));

            } catch (e) {
                console.error('❌ Failed to inject session for predictions:', e);
            }
        })();
        """

        let userScript = WKUserScript(
            source: script,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )

        webView.configuration.userContentController.addUserScript(userScript)

        print("🔄 Injecting session for predictions - user: \(session.user.email)")
        PredictionWebViewContainer.injectedSessionUserId = session.user.id
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: PredictionWebViewContainer
        weak var webView: WKWebView?
        var hasInjectedPostLoad = false

        init(_ parent: PredictionWebViewContainer) {
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

            // Guard: Only inject once per session to prevent infinite loop
            guard !hasInjectedPostLoad else {
                print("⏭️ Skipping post-load injection for predictions - already injected")
                return
            }

            // Re-inject session after page load
            hasInjectedPostLoad = true
            let session = parent.session
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
                    console.log('✅ Session re-injected for predictions after page load');

                    window.dispatchEvent(new CustomEvent('ios-auth-ready', {
                        detail: {
                            session: sessionData,
                            authenticated: true,
                            source: 'ios-native-predictions-postload'
                        }
                    }));

                    window.dispatchEvent(new StorageEvent('storage', {
                        key: storageKey,
                        newValue: JSON.stringify(sessionData),
                        url: window.location.href,
                        storageArea: localStorage
                    }));
                } catch (e) {
                    console.error('❌ Failed to re-inject session for predictions:', e);
                }
            })();
            """
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("❌ Error injecting session for predictions: \(error.localizedDescription)")
                } else {
                    print("✅ Session injected for predictions after page load")
                }
            }

            // Track successful page load
            AnalyticsManager.shared.track(event: "glucose_prediction_page_loaded", properties: [
                "url": webView.url?.absoluteString ?? "unknown"
            ])
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            print("Prediction WebView navigation error: \(error.localizedDescription)")

            // Track error
            AnalyticsManager.shared.track(event: "glucose_prediction_load_error", properties: [
                "error": error.localizedDescription
            ])
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            print("Prediction WebView provisional navigation error: \(error.localizedDescription)")
        }

        // Handle navigation to individual prediction pages
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                let urlString = url.absoluteString

                // Allow navigation within viiraa.com domain
                if urlString.contains("viiraa.com") {
                    // Track navigation to specific prediction
                    if urlString.contains("/predict-glucose/") && !urlString.hasSuffix("/predict-glucose") {
                        // Extract prediction ID from URL
                        if let predictionId = urlString.components(separatedBy: "/predict-glucose/").last {
                            AnalyticsManager.shared.track(event: "glucose_prediction_detail_viewed", properties: [
                                "prediction_id": predictionId
                            ])
                        }
                    }
                    decisionHandler(.allow)
                    return
                }

                // Open external links in Safari
                if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }

            decisionHandler(.allow)
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
                    print("Prediction navigate to: \(url)")
                }

            case "analytics":
                if let event = payload as? [String: Any],
                   let eventName = event["name"] as? String,
                   let properties = event["properties"] as? [String: Any] {
                    AnalyticsManager.shared.track(event: eventName, properties: properties)
                }

            case "predictionCreated":
                // Handle when a new prediction is created
                if let predictionId = payload as? String {
                    AnalyticsManager.shared.track(event: "glucose_prediction_created", properties: [
                        "prediction_id": predictionId
                    ])
                }

            case "error":
                if let errorMessage = payload as? String {
                    print("Prediction web error: \(errorMessage)")
                }

            default:
                print("Unknown prediction message type: \(type)")
            }
        }
    }
}

// MARK: - Individual Prediction View (for deep linking)

/// View for displaying a specific prediction by ID
/// Accessible via viiraa.com/predict-glucose/{prediction-id}
struct GlucosePredictionDetailView: View {
    let predictionId: String
    @EnvironmentObject var authManager: AuthManager
    @State private var isLoading = true

    private var predictionURL: URL {
        URL(string: "https://www.viiraa.com/predict-glucose/\(predictionId)")!
    }

    var body: some View {
        ZStack {
            if let session = authManager.session {
                PredictionWebViewContainer(
                    url: predictionURL,
                    session: session,
                    isLoading: $isLoading
                )
            } else {
                Text("Please sign in to view this prediction.")
                    .foregroundColor(.secondary)
            }

            if isLoading && authManager.session != nil {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .navigationTitle("Prediction Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AnalyticsManager.shared.track(event: "glucose_prediction_detail_viewed", properties: [
                "prediction_id": predictionId,
                "source": "deep_link"
            ])
        }
    }
}

#Preview {
    NavigationView {
        GlucosePredictionWebView()
    }
}
