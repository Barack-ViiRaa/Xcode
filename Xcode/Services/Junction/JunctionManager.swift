//
//  JunctionManager.swift
//  ViiRaa
//
//  Created by Claude on 2025-11-25.
//  Manager for Junction (Vital) SDK integration - Phase 2
//  Enables HealthKit data sync to Junction cloud for ML training
//
//  Reference: /Users/barack/Downloads/Xcode/3rd_Party_Bio_Data_Integration_Report.md
//

import Foundation
import Combine

/// JunctionManager handles integration with Junction (formerly Vital) SDK
/// for unified health data access and HIPAA-compliant cloud synchronization.
///
/// Key Features:
/// - Unified API supporting 300+ health devices
/// - Automated HealthKit data sync (hourly)
/// - HIPAA-compliant data storage for ML model training
///
/// Note: Apple HealthKit enforces a minimum 3-hour data delay.
/// This is acceptable for ML training and historical analysis
/// but not suitable for real-time alerts.
@MainActor
class JunctionManager: ObservableObject {
    static let shared = JunctionManager()

    // MARK: - Published Properties

    @Published var isConfigured = false
    @Published var isConnected = false
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var syncError: JunctionError?

    // For conformance with ObservableObject when using @MainActor
    nonisolated let objectWillChange = ObservableObjectPublisher()

    // MARK: - Sync Status

    enum SyncStatus: String {
        case idle = "Idle"
        case syncing = "Syncing..."
        case success = "Sync Complete"
        case failed = "Sync Failed"

        var isInProgress: Bool {
            return self == .syncing
        }
    }

    // MARK: - Private Properties

    private var apiKey: String?
    private var userId: String?
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 3600 // 1 hour (matching Junction's hourly sync)

    private init() {}

    // MARK: - Configuration

    /// Configure the Junction SDK with API key
    /// - Parameter apiKey: Junction API key from dashboard
    /// - Note: Must sign BAA with Junction before using in production
    func configure(apiKey: String) {
        self.apiKey = apiKey

        // TODO: Replace with actual VitalHealth SDK initialization
        // when Junction SDK is added via Swift Package Manager
        //
        // VitalHealth.configure(apiKey: apiKey)

        self.isConfigured = true

        print("🔗 Junction SDK configured")

        // Track configuration event
        AnalyticsManager.shared.track(event: "junction_configured")
    }

    /// Connect a user to Junction for data sync
    /// - Parameter userId: The ViiRaa user ID to associate with Junction
    func connectUser(userId: String) async throws {
        guard isConfigured else {
            throw JunctionError.notConfigured
        }

        self.userId = userId

        // TODO: Replace with actual VitalHealth SDK user connection
        // when Junction SDK is added via Swift Package Manager
        //
        // try await VitalHealth.shared.connect(userId: userId)

        self.isConnected = true

        print("👤 User connected to Junction: \(userId)")

        // Track connection event
        AnalyticsManager.shared.track(event: "junction_user_connected", properties: [
            "user_id": userId
        ])
    }

    // MARK: - HealthKit Permissions (via Junction)

    /// Request HealthKit permissions through Junction SDK
    /// - Note: This is an alternative to using HealthKitManager directly
    ///         when you want Junction to manage the permissions flow
    func requestHealthKitPermissions() async throws {
        guard isConfigured else {
            throw JunctionError.notConfigured
        }

        // TODO: Replace with actual VitalHealth SDK permission request
        // when Junction SDK is added via Swift Package Manager
        //
        // try await VitalHealth.shared.ask(
        //     readPermissions: [.glucose, .weight, .steps, .activeEnergyBurned],
        //     writePermissions: []
        // )

        // For now, delegate to our existing HealthKitManager
        try await HealthKitManager.shared.requestAuthorization()

        print("✅ HealthKit permissions granted via Junction")

        // Track permission grant
        AnalyticsManager.shared.track(event: "junction_healthkit_authorized")
    }

    // MARK: - Data Sync

    /// Manually trigger a sync of HealthKit data to Junction cloud
    /// - Note: Junction SDK handles automatic hourly sync; this is for on-demand sync
    func syncHealthData() async throws {
        guard isConfigured else {
            throw JunctionError.notConfigured
        }

        guard isConnected else {
            throw JunctionError.userNotConnected
        }

        // Update status
        syncStatus = .syncing
        syncError = nil

        do {
            // TODO: Replace with actual VitalHealth SDK sync call
            // when Junction SDK is added via Swift Package Manager
            //
            // try await VitalHealth.shared.syncData()

            // Simulate sync for development (remove when SDK is integrated)
            try await simulateSyncForDevelopment()

            // Update status on success
            syncStatus = .success
            lastSyncDate = Date()

            print("✅ Health data synced to Junction cloud")

            // Track sync success
            AnalyticsManager.shared.track(event: "junction_sync_success", properties: [
                "sync_date": ISO8601DateFormatter().string(from: Date())
            ])

        } catch {
            // Update status on failure
            syncStatus = .failed
            let junctionError = JunctionError.syncFailed(error)
            syncError = junctionError

            print("❌ Junction sync failed: \(error.localizedDescription)")

            // Track sync failure
            AnalyticsManager.shared.track(event: "junction_sync_failed", properties: [
                "error": error.localizedDescription
            ])

            throw junctionError
        }
    }

    /// Start automatic background sync (hourly)
    func startAutomaticSync() {
        guard syncTimer == nil else { return }

        // Initial sync
        Task {
            try? await syncHealthData()
        }

        // Schedule hourly sync
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                try? await self?.syncHealthData()
            }
        }

        print("🔄 Junction automatic sync started (hourly)")
    }

    /// Stop automatic background sync
    func stopAutomaticSync() {
        syncTimer?.invalidate()
        syncTimer = nil

        print("⏹️ Junction automatic sync stopped")
    }

    // MARK: - Data Retrieval (from Junction Cloud)

    /// Fetch glucose data from Junction cloud
    /// - Parameters:
    ///   - startDate: Start date for the query
    ///   - endDate: End date for the query
    /// - Returns: Array of glucose readings from Junction
    func fetchGlucoseFromCloud(startDate: Date, endDate: Date) async throws -> [JunctionGlucoseReading] {
        guard isConfigured else {
            throw JunctionError.notConfigured
        }

        guard isConnected else {
            throw JunctionError.userNotConnected
        }

        // TODO: Replace with actual Junction API call
        // when Junction SDK is added via Swift Package Manager
        //
        // let readings = try await VitalHealth.shared.fetchGlucose(
        //     startDate: startDate,
        //     endDate: endDate
        // )
        // return readings.map { JunctionGlucoseReading(from: $0) }

        // Return empty array for development
        return []
    }

    // MARK: - Connection Status

    /// Check if Junction is properly configured and connected
    var isReady: Bool {
        return isConfigured && isConnected
    }

    /// Get a human-readable status message
    var statusMessage: String {
        if !isConfigured {
            return "Junction SDK not configured"
        }
        if !isConnected {
            return "User not connected to Junction"
        }
        switch syncStatus {
        case .idle:
            if let lastSync = lastSyncDate {
                let formatter = RelativeDateTimeFormatter()
                return "Last sync: \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
            }
            return "Ready to sync"
        case .syncing:
            return "Syncing health data..."
        case .success:
            return "Sync complete"
        case .failed:
            return syncError?.localizedDescription ?? "Sync failed"
        }
    }

    // MARK: - Disconnect

    /// Disconnect user from Junction
    func disconnect() {
        stopAutomaticSync()
        userId = nil
        isConnected = false
        syncStatus = .idle
        lastSyncDate = nil
        syncError = nil

        print("🔌 User disconnected from Junction")

        // Track disconnection
        AnalyticsManager.shared.track(event: "junction_user_disconnected")
    }

    // MARK: - Development Helpers

    /// Simulate sync for development/testing (remove when SDK is integrated)
    private func simulateSyncForDevelopment() async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        // Simulate occasional failure (10% chance) for testing error handling
        // Comment out for production testing
        // if Int.random(in: 1...10) == 1 {
        //     throw NSError(domain: "JunctionSimulation", code: -1,
        //                   userInfo: [NSLocalizedDescriptionKey: "Simulated sync failure"])
        // }
    }
}

// MARK: - Junction Data Models

/// Glucose reading from Junction cloud
struct JunctionGlucoseReading: Identifiable, Codable {
    let id: String
    let value: Double          // mg/dL
    let timestamp: Date
    let source: String         // Device source (e.g., "Dexcom G7", "Libre 3")

    /// Classification based on glucose value
    var classification: GlucoseClassification {
        switch value {
        case ..<70:
            return .low
        case 70..<180:
            return .inRange
        case 180..<250:
            return .high
        default:
            return .veryHigh
        }
    }

    enum GlucoseClassification: String {
        case low = "Low"
        case inRange = "In Range"
        case high = "High"
        case veryHigh = "Very High"
    }
}

// MARK: - Junction Errors

enum JunctionError: LocalizedError {
    case notConfigured
    case userNotConnected
    case permissionDenied
    case syncFailed(Error)
    case networkError
    case invalidAPIKey
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Junction SDK is not configured. Please contact support."
        case .userNotConnected:
            return "User is not connected to Junction. Please sign in again."
        case .permissionDenied:
            return "HealthKit permission denied. Please enable health data access in Settings."
        case .syncFailed(let error):
            return "Failed to sync health data: \(error.localizedDescription)"
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .invalidAPIKey:
            return "Invalid Junction API key. Please contact support."
        case .rateLimited:
            return "Too many sync requests. Please wait a moment and try again."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notConfigured:
            return "The app needs to be updated with Junction credentials."
        case .userNotConnected:
            return "Try signing out and signing back in."
        case .permissionDenied:
            return "Go to Settings > Privacy & Security > Health to enable access."
        case .syncFailed:
            return "Try again later or check your internet connection."
        case .networkError:
            return "Check your Wi-Fi or cellular connection."
        case .invalidAPIKey:
            return "This is an app configuration issue."
        case .rateLimited:
            return "Wait a few minutes before trying again."
        }
    }
}
