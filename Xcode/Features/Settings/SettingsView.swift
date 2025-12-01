//
//  SettingsView.swift
//  Xcode
//
//  Created by Claude Code on 11/11/25.
//  Updated: 2025-11-20 - Fixed HealthKit permission status bug
//

import SwiftUI
import HealthKit

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var healthKitAuthStatus: HKAuthorizationStatus = .notDetermined
    @State private var hasGlucoseData = false
    @State private var isCheckingPermissions = false
    @State private var showSignOutConfirmation = false
    @State private var isSigningOut = false

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
                        if isCheckingPermissions {
                            ProgressView()
                        } else {
                            healthKitStatusIndicator
                        }
                    }

                    Button(action: {
                        requestHealthKitPermissions()
                    }) {
                        HStack {
                            Image(systemName: "heart.circle")
                            Text("Request HealthKit Access")
                        }
                    }

                    Button(action: {
                        openHealthKitSettings()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                            Text("Manage in iOS Settings")
                        }
                    }

                    Button(action: {
                        refreshPermissionStatus()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Status")
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

                    // Privacy Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About Permission Status")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Due to Apple's privacy protections, the permission status may not always reflect the actual access granted. If you've granted access and can see glucose data in the Glucose tab, your permissions are working correctly.")
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

                // Account Section with Sign Out
                Section {
                    Button(role: .destructive, action: {
                        showSignOutConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)

                            if isSigningOut {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                    }
                    .disabled(isSigningOut)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                checkHealthKitAuthStatus()
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    handleSignOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    private func handleSignOut() {
        isSigningOut = true
        Task {
            do {
                try await authManager.signOut()
                AnalyticsManager.shared.track(event: "user_signed_out", properties: ["source": "settings"])
            } catch {
                print("Error signing out: \(error.localizedDescription)")
            }
            await MainActor.run {
                isSigningOut = false
            }
        }
    }

    private var healthKitStatusText: String {
        // IMPORTANT: Due to Apple's privacy model, authorizationStatus for read permissions
        // may return .notDetermined even when access is granted.
        // We check if we can actually fetch data to determine real status.

        if hasGlucoseData {
            return "Access verified - Data available"
        }

        switch healthKitAuthStatus {
        case .sharingAuthorized:
            return "Access granted"
        case .sharingDenied:
            return "Access denied"
        case .notDetermined:
            return "Not determined - Check Glucose tab"
        @unknown default:
            return "Unknown status"
        }
    }

    private var healthKitStatusIndicator: some View {
        Group {
            if hasGlucoseData {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if healthKitAuthStatus == .sharingDenied {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            } else {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.orange)
            }
        }
    }

    private func checkHealthKitAuthStatus() {
        isCheckingPermissions = true

        // Check API authorization status
        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else {
            isCheckingPermissions = false
            return
        }
        let healthStore = HKHealthStore()
        healthKitAuthStatus = healthStore.authorizationStatus(for: glucoseType)

        // Try to fetch actual data to verify real access
        // This is the only reliable way to check read permissions
        Task {
            do {
                let glucose = try await healthKitManager.fetchLatestGlucose()
                await MainActor.run {
                    hasGlucoseData = (glucose != nil)
                    isCheckingPermissions = false
                }
            } catch {
                print("Error checking glucose data: \(error.localizedDescription)")
                await MainActor.run {
                    hasGlucoseData = false
                    isCheckingPermissions = false
                }
            }
        }
    }

    private func requestHealthKitPermissions() {
        Task {
            do {
                try await healthKitManager.requestAuthorization()
                // Wait a moment for permissions to register
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                checkHealthKitAuthStatus()

                AnalyticsManager.shared.track(event: "healthkit_permission_requested", properties: [
                    "from": "settings"
                ])
            } catch {
                print("Error requesting HealthKit permissions: \(error.localizedDescription)")
            }
        }
    }

    private func refreshPermissionStatus() {
        checkHealthKitAuthStatus()
        AnalyticsManager.shared.track(event: "healthkit_status_refreshed")
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

#Preview {
    SettingsView()
}
