//
//  MainTabView.swift
//  ViiRaaApp
//
//  Created by ViiRaa Team
//  Copyright © 2025 ViiRaa. All rights reserved.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var selectedTab = 0
    @State private var showHealthKitPermission = false
    @AppStorage("healthKitPermissionShown") private var healthKitPermissionShown = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView()
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

            // Chat Tab (Placeholder for Phase 1)
            ChatPlaceholderView()
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
        .accentColor(Color(hex: Constants.primaryColorHex))
        .sheet(isPresented: $showHealthKitPermission) {
            HealthKitPermissionView(isPresented: $showHealthKitPermission)
        }
        .onAppear {
            // Track screen view
            AnalyticsManager.shared.screen(name: "MainTabView")

            // Show HealthKit permission prompt if enabled and not shown before
            if Constants.isHealthKitEnabled,
               !healthKitPermissionShown,
               healthKitManager.isHealthDataAvailable(),
               !healthKitManager.isAuthorized {
                // Delay to avoid showing immediately on app launch
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showHealthKitPermission = true
                    healthKitPermissionShown = true
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager.shared)
        .environmentObject(AnalyticsManager.shared)
}
