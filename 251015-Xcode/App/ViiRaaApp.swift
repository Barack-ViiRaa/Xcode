
import SwiftUI
import UIKit

@main
struct ViiRaaApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var analyticsManager = AnalyticsManager.shared

    init() {
        setupApp()
    }

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
    }

    private func setupApp() {
        // Initialize services
        SupabaseManager.shared.initialize()
        AnalyticsManager.shared.initialize()
        configureAppearance()
    }

    private func configureAppearance() {
        // Keep appearance minimal and safe (no custom extensions required)
        UITabBar.appearance().backgroundColor = .systemBackground
        UITabBar.appearance().tintColor = .label
    }
}
