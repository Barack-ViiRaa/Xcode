
import SwiftUI
import UIKit

@main
struct ViiRaaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var analyticsManager = AnalyticsManager.shared
    @StateObject private var junctionManager = JunctionManager.shared

    init() {
        setupApp()
    }

    var body: some Scene {
        WindowGroup {
            Group {
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
    }

    private func setupApp() {
        // Initialize services
        SupabaseManager.shared.initialize()
        AnalyticsManager.shared.initialize()

        // Initialize Junction SDK if enabled
        // Note: Using sandbox environment for testing (no BAA required)
        // VitalClient.configure() is called in AppDelegate FIRST (required order)
        // This just marks JunctionManager as configured and tracks analytics
        if Constants.isJunctionEnabled {
            JunctionManager.shared.markConfigured(environment: Constants.junctionEnvironment)
        }

        configureAppearance()
    }

    private func configureAppearance() {
        // Keep appearance minimal and safe (no custom extensions required)
        UITabBar.appearance().backgroundColor = .systemBackground
        UITabBar.appearance().tintColor = .label
    }
}
