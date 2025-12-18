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
    @StateObject private var junctionManager = JunctionManager.shared
    @State private var healthKitAuthStatus: HKAuthorizationStatus = .notDetermined
    @State private var hasGlucoseData = false
    @State private var isCheckingPermissions = false
    @State private var showSignOutConfirmation = false
    @State private var isSigningOut = false
    @State private var isSyncingJunction = false
    @State private var isRunningDiagnostic = false

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

                // BLE Follow Mode Section
                Section(header: Text("Real-time Glucose")) {
                    NavigationLink(destination: BLEFollowSettingsView()) {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("BLE Follow Mode")
                                    .font(.headline)
                                Text("Real-time glucose with 1-5 min latency")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("About BLE Follow Mode")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Monitor real-time glucose readings from your Abbott Lingo sensor via Bluetooth. Requires Abbott Lingo app and active sensor.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Junction Cloud Sync Section
                if Constants.isJunctionEnabled {
                    Section(header: Text("Cloud Sync")) {
                        HStack {
                            Image(systemName: "cloud.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("Junction Sync")
                                    .font(.headline)
                                Text(junctionManager.statusMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            junctionStatusIndicator
                        }

                        // Manual Sync Button
                        Button(action: {
                            syncJunctionData()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise.cloud")
                                Text("Sync Now")
                                Spacer()
                                if isSyncingJunction || junctionManager.syncStatus.isInProgress {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                }
                            }
                        }
                        .disabled(!junctionManager.isReady || isSyncingJunction || junctionManager.syncStatus.isInProgress)

                        // Sync Details
                        if let lastSync = junctionManager.lastSyncDate {
                            HStack {
                                Text("Last Sync")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(lastSync, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Connection Status
                        HStack {
                            Text("Connection")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(junctionManager.isConnected ? "Connected" : "Not Connected")
                                .font(.caption)
                                .foregroundColor(junctionManager.isConnected ? .green : .red)
                        }

                        // User Account Status
                        HStack {
                            Text("User Account")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(junctionManager.userId != nil ? "Created" : "Not Created")
                                .font(.caption)
                                .foregroundColor(junctionManager.userId != nil ? .green : .red)
                        }

                        // Show User ID for Junction Dashboard search
                        if let userId = junctionManager.userId {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Client User ID")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(userId)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .textSelection(.enabled)
                                Button(action: {
                                    UIPasteboard.general.string = userId
                                }) {
                                    HStack {
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption)
                                        Text("Copy User ID")
                                            .font(.caption)
                                    }
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 4)

                            Text("💡 Tip: Search for this ID in Junction Dashboard → Users → Search by \"Client User ID\"")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }

                        // Manual Connection Button (for Bug #22 fix)
                        if !junctionManager.isConnected {
                            Button(action: {
                                manuallyConnectToJunction()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath.circle")
                                        .foregroundColor(.orange)
                                    Text("Retry Junction Connection")
                                }
                            }

                            if let error = junctionManager.syncError {
                                Text("Last error: \(error.localizedDescription)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("About Cloud Sync")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Junction automatically syncs your health data to the cloud every hour for ML training. Note: HealthKit enforces a 3-hour data delay.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // Debug Section for Bug #21
                        Divider()

                        Text("Troubleshooting")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)

                        // Run Diagnostic Button
                        Button(action: {
                            runJunctionDiagnostic()
                        }) {
                            HStack {
                                Image(systemName: "stethoscope")
                                    .foregroundColor(.orange)
                                Text("Run Sync Diagnostic")
                                Spacer()
                                if isRunningDiagnostic {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                }
                            }
                        }
                        .disabled(isRunningDiagnostic)

                        // Force Glucose Permission Button
                        Button(action: {
                            forceGlucosePermission()
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundColor(.orange)
                                Text("Re-request Glucose Permission")
                            }
                        }

                        // Write Mock Data Button (for testing)
                        Button(action: {
                            writeMockGlucoseData()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.purple)
                                Text("Write Mock Glucose Data (Test)")
                            }
                        }

                        Text("⚠️ Simulator Limitation: Mock data will have ViiRaa as source. Junction may only sync data from real CGM devices (Abbott Lingo, Dexcom). Test on a physical iPhone with Lingo for production validation.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // View Error Log Button (Bug #22 fix)
                        NavigationLink(destination: ErrorLogView()) {
                            HStack {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .foregroundColor(.purple)
                                Text("View Error Log")
                            }
                        }

                        Button(action: {
                            clearErrorLog()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text("Clear Error Log")
                            }
                        }
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

    // MARK: - Junction Helpers

    private var junctionStatusIndicator: some View {
        Group {
            if junctionManager.isReady && junctionManager.syncStatus == .success {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if junctionManager.syncStatus == .failed {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
            } else if junctionManager.syncStatus == .syncing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if !junctionManager.isConnected {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            } else {
                Image(systemName: "cloud.fill")
                    .foregroundColor(.blue)
            }
        }
    }

    private func syncJunctionData() {
        guard !isSyncingJunction else { return }

        isSyncingJunction = true
        Task {
            do {
                try await junctionManager.syncHealthData()
                AnalyticsManager.shared.track(event: "junction_manual_sync", properties: [
                    "from": "settings"
                ])
            } catch {
                print("Error syncing Junction data: \(error.localizedDescription)")
            }
            await MainActor.run {
                isSyncingJunction = false
            }
        }
    }

    // MARK: - Bug #21 Diagnostic Functions

    private func runJunctionDiagnostic() {
        guard !isRunningDiagnostic else { return }

        isRunningDiagnostic = true
        Task {
            await junctionManager.runFullBug21Diagnostic()
            await MainActor.run {
                isRunningDiagnostic = false
            }
        }
    }

    private func forceGlucosePermission() {
        Task {
            await junctionManager.forceRequestGlucosePermission()
        }
    }

    private func writeMockGlucoseData() {
        Task {
            await junctionManager.writeMockGlucoseData()
        }
    }

    // MARK: - Manual Junction Connection (Bug #22 Fix)

    private func manuallyConnectToJunction() {
        Task {
            guard let userId = authManager.user?.id else {
                print("❌ No user ID available for Junction connection")
                return
            }

            print("🔄 Manually connecting to Junction...")
            print("   User ID: \(userId)")
            print("   Environment: \(Constants.junctionEnvironment)")
            print("   API Key prefix: \(Constants.junctionAPIKey.prefix(8))...")

            do {
                // Try to connect user to Junction
                try await junctionManager.connectUser(userId: userId)
                print("✅ Junction connection successful")

                // Request HealthKit permissions
                try await junctionManager.requestHealthKitPermissions()
                print("✅ HealthKit permissions requested")

                // Start automatic sync
                junctionManager.startAutomaticSync()
                print("✅ Automatic sync started")

                // Track success
                AnalyticsManager.shared.track(event: "junction_manual_connection_success", properties: [
                    "user_id": userId
                ])
            } catch {
                print("❌ Junction connection failed: \(error.localizedDescription)")
                print("   Error type: \(type(of: error))")

                // Track failure
                AnalyticsManager.shared.track(event: "junction_manual_connection_failed", properties: [
                    "user_id": userId,
                    "error": error.localizedDescription
                ])
            }
        }
    }

    private func clearErrorLog() {
        ErrorLogger.shared.clearLogs()
        ErrorLogger.shared.log("User cleared error log from Settings", category: "System")
    }
}

#Preview {
    SettingsView()
}
