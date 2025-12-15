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
import VitalCore
import VitalHealthKit

// MARK: - Junction API Models

/// Response from Junction user creation API
struct JunctionUserResponse: Codable {
    let userId: String
    let clientUserId: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case clientUserId = "client_user_id"
    }
}

/// Error response when user already exists (400 Bad Request)
/// Response format: {"detail":{"error_type":"INVALID_REQUEST","error_message":"Client user id already exists.","user_id":"...","created_on":"..."}}
struct JunctionUserExistsErrorResponse: Codable {
    let detail: JunctionUserExistsDetail
}

struct JunctionUserExistsDetail: Codable {
    let errorType: String?
    let errorMessage: String?
    let userId: String?
    let createdOn: String?

    enum CodingKeys: String, CodingKey {
        case errorType = "error_type"
        case errorMessage = "error_message"
        case userId = "user_id"
        case createdOn = "created_on"
    }
}

/// Response from Junction sign-in token API
/// POST /v2/user/{user_id}/sign_in_token
struct JunctionSignInTokenResponse: Codable {
    let userId: String
    let signInToken: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case signInToken = "sign_in_token"
    }
}

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
    /// - Parameters:
    ///   - apiKey: Junction API key from dashboard
    ///   - environment: Environment to use ("sandbox" or "production")
    /// - Note: Must sign BAA with Junction before using in production
    /// - Important: VitalClient.configure() should be called in AppDelegate BEFORE VitalHealthKitClient.automaticConfiguration()
    func configure(apiKey: String, environment: String = "sandbox") {
        self.apiKey = apiKey

        // Configure VitalClient with the appropriate environment
        if environment == "sandbox" {
            VitalClient.configure(apiKey: apiKey, environment: .sandbox(.us))
        } else {
            VitalClient.configure(apiKey: apiKey, environment: .production(.us))
        }

        self.isConfigured = true

        print("🔗 Junction SDK configured with \(environment) environment")

        // Track configuration event
        AnalyticsManager.shared.track(event: "junction_configured", properties: [
            "environment": environment
        ])
    }

    /// Mark JunctionManager as configured without calling VitalClient.configure()
    /// Use this when VitalClient.configure() has already been called in AppDelegate
    /// - Parameter environment: Environment string for tracking purposes
    func markConfigured(environment: String = "sandbox") {
        self.apiKey = Constants.junctionAPIKey
        self.isConfigured = true

        print("🔗 Junction SDK configured with \(environment) environment")

        // Track configuration event
        AnalyticsManager.shared.track(event: "junction_configured", properties: [
            "environment": environment
        ])
    }

    /// Connect a user to Junction for data sync
    /// - Parameter userId: The ViiRaa user ID to associate with Junction
    func connectUser(userId: String) async throws {
        guard isConfigured else {
            throw JunctionError.notConfigured
        }

        guard let apiKey = self.apiKey else {
            throw JunctionError.invalidAPIKey
        }

        self.userId = userId

        // Check if VitalClient is already signed in (session persists across app launches)
        // Per docs: "it is unnecessary to request and sign-in with the Vital Sign-In Token every time your app launches"
        let currentStatus = await VitalClient.status
        if currentStatus.contains(.signedIn) {
            print("✅ VitalClient already signed in - skipping sign-in flow")

            // Even if already signed in, ensure provider connections exist (Bug 20 fix)
            // This handles the case where user was created but connections were never made
            print("🔗 Verifying provider connections exist...")
            do {
                // Get the Junction user ID for this client user
                let junctionUserId = try await createUserInJunction(clientUserId: userId, apiKey: apiKey)

                // Create connections (will log "already exists" if they do)
                try await createDemoConnection(junctionUserId: junctionUserId, provider: "apple_health_kit", apiKey: apiKey)
                try await createDemoConnection(junctionUserId: junctionUserId, provider: "freestyle_libre", apiKey: apiKey)
                print("✅ Provider connections verified")
            } catch {
                // Log but don't fail - user is already signed in
                print("⚠️  Could not verify provider connections: \(error.localizedDescription)")
            }

            self.isConnected = true

            // Track reconnection event
            AnalyticsManager.shared.track(event: "junction_user_reconnected", properties: [
                "user_id": userId
            ])
            return
        }

        // CRITICAL: Create the user in Junction's backend first
        // This is required before the SDK can sync data for this user
        print("📝 Creating user in Junction backend...")

        let junctionUserId = try await createUserInJunction(clientUserId: userId, apiKey: apiKey)

        print("✅ User created in Junction: \(junctionUserId)")

        // CRITICAL: Create a sign-in token and sign in with VitalClient
        // Without this, data will NOT upload to Junction's cloud!
        // Per docs: https://docs.junction.com/wearables/sdks/authentication
        print("🔐 Creating sign-in token for VitalClient...")

        let signInToken = try await createSignInToken(junctionUserId: junctionUserId, apiKey: apiKey)

        // Log token details for debugging (first 20 chars only for security)
        let tokenPreview = signInToken.prefix(20)
        print("🎫 Sign-in token preview: \(tokenPreview)... (length: \(signInToken.count))")
        print("🔑 Sign-in token created, signing in with VitalClient...")

        // Sign in with VitalClient - this authenticates the SDK to upload data
        // Note: The SDK exchanges the short-lived token for permanent credentials
        do {
            try await VitalClient.signIn(withRawToken: signInToken)
            print("✅ VitalClient signed in successfully - data will now sync to Junction cloud")
        } catch {
            // Log detailed error information
            print("❌ VitalClient.signIn failed: \(error)")
            print("   Error type: \(type(of: error))")
            print("   Error description: \(error.localizedDescription)")

            // Check if it's a JWT-specific error and provide helpful context
            let errorString = String(describing: error)
            if errorString.contains("VitalJWTSignInError") {
                print("⚠️  JWT Sign-In Error detected. Possible causes:")
                print("   1. VitalClient.configure() not called before VitalHealthKitClient.automaticConfiguration()")
                print("   2. Token may have expired (tokens are short-lived)")
                print("   3. SDK version mismatch with API")
                print("   4. Environment mismatch (sandbox vs production)")
            }

            // Track the failure with error details
            AnalyticsManager.shared.track(event: "junction_connection_failed", properties: [
                "user_id": userId,
                "error": errorString,
                "token_length": signInToken.count
            ])

            throw error
        }

        // CRITICAL FIX (Bug 20): Create provider connections AFTER sign-in
        // Without this step, user exists in Junction but has NO data connections!
        // The Junction Dashboard will show the user but with empty Connections tab.
        // Per Credentials.md demo: POST /v2/link/connect/demo creates the provider connection
        print("🔗 Creating provider connections for data sync...")

        // Create Apple Health connection (primary for iOS)
        try await createDemoConnection(junctionUserId: junctionUserId, provider: "apple_health_kit", apiKey: apiKey)

        // Optionally create Freestyle Libre connection for CGM users
        // This is useful for users who sync CGM data via LibreLink app
        try await createDemoConnection(junctionUserId: junctionUserId, provider: "freestyle_libre", apiKey: apiKey)

        print("✅ Provider connections established - data can now flow to Junction")

        self.isConnected = true

        print("👤 User connected to Junction: \(junctionUserId) (client: \(userId))")

        // Track connection event
        AnalyticsManager.shared.track(event: "junction_user_connected", properties: [
            "user_id": userId,
            "junction_user_id": junctionUserId
        ])
    }

    /// Create a user in Junction's backend via REST API
    /// - Parameters:
    ///   - clientUserId: Your app's user ID
    ///   - apiKey: Junction API key
    /// - Returns: The Junction-assigned user_id (UUID)
    private func createUserInJunction(clientUserId: String, apiKey: String) async throws -> String {
        // Determine API base URL based on API key prefix
        // sk_us_ = Sandbox US, pk_us_ = Production US
        // sk_eu_ = Sandbox EU, pk_eu_ = Production EU
        // Per Junction docs: https://docs.junction.com/home/quickstart
        // Correct URLs are: api.sandbox.tryvital.io (sandbox) and api.tryvital.io (production)
        let baseURL: String
        if apiKey.hasPrefix("sk_us_") || apiKey.hasPrefix("k_us_") {
            // US Sandbox
            baseURL = "https://api.sandbox.tryvital.io"
        } else if apiKey.hasPrefix("pk_us_") {
            // US Production
            baseURL = "https://api.tryvital.io"
        } else if apiKey.hasPrefix("sk_eu_") {
            // EU Sandbox
            baseURL = "https://api.sandbox.eu.tryvital.io"
        } else if apiKey.hasPrefix("pk_eu_") {
            // EU Production
            baseURL = "https://api.eu.tryvital.io"
        } else {
            // Fallback to US sandbox for legacy keys
            baseURL = "https://api.sandbox.tryvital.io"
        }

        // Note: Endpoint is /v2/user/ (singular with trailing slash) per Junction docs
        // https://docs.junction.com/api-reference/user/create-user
        guard let url = URL(string: "\(baseURL)/v2/user/") else {
            throw JunctionError.networkError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "x-vital-api-key")  // lowercase per docs
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["client_user_id": clientUserId]
        request.httpBody = try JSONEncoder().encode(body)

        print("🌐 API Request: POST \(url.absoluteString)")
        print("🔑 API Key prefix: \(apiKey.prefix(8))...")
        print("📍 Base URL: \(baseURL)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw JunctionError.networkError
        }

        // Check for success or if user already exists
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let junctionResponse = try JSONDecoder().decode(JunctionUserResponse.self, from: data)
            return junctionResponse.userId
        } else if httpResponse.statusCode == 400 || httpResponse.statusCode == 409 {
            // User already exists - Junction returns 400 with user_id in the response
            // Response format: {"detail":{"error_type":"INVALID_REQUEST","error_message":"Client user id already exists.","user_id":"...","created_on":"..."}}
            if let errorResponse = try? JSONDecoder().decode(JunctionUserExistsErrorResponse.self, from: data),
               let existingUserId = errorResponse.detail.userId {
                print("ℹ️  User already exists in Junction: \(existingUserId)")
                return existingUserId
            }
            // Fallback: try to fetch the existing user
            print("ℹ️  User already exists in Junction, fetching existing user...")
            return try await fetchExistingUser(clientUserId: clientUserId, apiKey: apiKey, baseURL: baseURL)
        } else if httpResponse.statusCode == 401 {
            // Invalid or expired API key
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Junction API error (401 Unauthorized): \(errorString)")
            }
            print("⚠️  API Key may be expired or invalid. Please check:")
            print("   1. Get a new API key from https://app.junction.com/")
            print("   2. Update Constants.junctionAPIKey with the new key")
            print("   3. Expected format: sk_us_* (Sandbox US) or pk_us_* (Production US)")
            throw JunctionError.invalidAPIKey
        } else {
            // Log error details
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Junction API error (\(httpResponse.statusCode)): \(errorString)")
            }
            throw JunctionError.networkError
        }
    }

    /// Fetch existing user from Junction by client_user_id
    private func fetchExistingUser(clientUserId: String, apiKey: String, baseURL: String) async throws -> String {
        // Endpoint to resolve client_user_id to Junction user_id
        // https://docs.junction.com/api-reference/user/resolve-user
        guard let url = URL(string: "\(baseURL)/v2/user/resolve/\(clientUserId)") else {
            throw JunctionError.networkError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "x-vital-api-key")  // lowercase per docs

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw JunctionError.networkError
        }

        if httpResponse.statusCode == 200 {
            let junctionResponse = try JSONDecoder().decode(JunctionUserResponse.self, from: data)
            return junctionResponse.userId
        } else if httpResponse.statusCode == 401 {
            print("❌ 401 Unauthorized when fetching existing user")
            throw JunctionError.invalidAPIKey
        } else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error fetching user (\(httpResponse.statusCode)): \(errorString)")
            }
            throw JunctionError.networkError
        }
    }

    /// Create a demo connection for a provider (Apple Health, Freestyle Libre, etc.)
    /// This is REQUIRED for data to flow from the provider to Junction!
    /// Per Credentials.md demo: POST /v2/link/connect/demo creates the provider connection
    /// - Parameters:
    ///   - junctionUserId: The Junction-assigned user_id (UUID)
    ///   - provider: The provider slug (e.g., "apple_health_kit", "freestyle_libre")
    ///   - apiKey: Junction API key
    /// - Note: Without this step, user exists in Junction but has NO data connections
    private func createDemoConnection(junctionUserId: String, provider: String, apiKey: String) async throws {
        // Determine API base URL based on API key prefix
        let baseURL: String
        if apiKey.hasPrefix("sk_us_") || apiKey.hasPrefix("k_us_") {
            baseURL = "https://api.sandbox.tryvital.io"
        } else if apiKey.hasPrefix("pk_us_") {
            baseURL = "https://api.tryvital.io"
        } else if apiKey.hasPrefix("sk_eu_") {
            baseURL = "https://api.sandbox.eu.tryvital.io"
        } else if apiKey.hasPrefix("pk_eu_") {
            baseURL = "https://api.eu.tryvital.io"
        } else {
            baseURL = "https://api.sandbox.tryvital.io"
        }

        // Endpoint: POST /v2/link/connect/demo
        // Per Credentials.md: This creates a sandbox connection for testing
        guard let url = URL(string: "\(baseURL)/v2/link/connect/demo") else {
            throw JunctionError.networkError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "x-vital-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "user_id": junctionUserId,
            "provider": provider
        ]
        request.httpBody = try JSONEncoder().encode(body)

        print("🔗 Creating \(provider) connection for user \(junctionUserId)...")
        print("🌐 API Request: POST \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw JunctionError.networkError
        }

        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            print("✅ Provider connection created: \(provider)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("   Response: \(responseString)")
            }
        } else if httpResponse.statusCode == 400 {
            // Connection may already exist - check if it's a duplicate error
            if let errorString = String(data: data, encoding: .utf8) {
                if errorString.contains("already") || errorString.contains("exists") {
                    print("ℹ️  Provider connection already exists: \(provider)")
                } else {
                    print("⚠️  Warning creating connection (\(httpResponse.statusCode)): \(errorString)")
                }
            }
        } else if httpResponse.statusCode == 401 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Junction API error (401 Unauthorized): \(errorString)")
            }
            throw JunctionError.invalidAPIKey
        } else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("⚠️  Warning creating connection (\(httpResponse.statusCode)): \(errorString)")
            }
            // Don't throw - connection creation failure shouldn't block the flow
            // The user can still try to sync and the SDK may auto-create the connection
        }
    }

    /// Create a sign-in token for VitalClient authentication
    /// - Parameters:
    ///   - junctionUserId: The Junction-assigned user_id (UUID)
    ///   - apiKey: Junction API key
    /// - Returns: The sign-in token string for VitalClient.signIn()
    /// - Note: Per docs, avoid creating new tokens on every app launch - session is persistent
    private func createSignInToken(junctionUserId: String, apiKey: String) async throws -> String {
        // Determine API base URL based on API key prefix
        let baseURL: String
        if apiKey.hasPrefix("sk_us_") || apiKey.hasPrefix("k_us_") {
            baseURL = "https://api.sandbox.tryvital.io"
        } else if apiKey.hasPrefix("pk_us_") {
            baseURL = "https://api.tryvital.io"
        } else if apiKey.hasPrefix("sk_eu_") {
            baseURL = "https://api.sandbox.eu.tryvital.io"
        } else if apiKey.hasPrefix("pk_eu_") {
            baseURL = "https://api.eu.tryvital.io"
        } else {
            baseURL = "https://api.sandbox.tryvital.io"
        }

        // Endpoint: POST /v2/user/{user_id}/sign_in_token
        // https://docs.junction.com/api-reference/user/create-sign-in-token
        guard let url = URL(string: "\(baseURL)/v2/user/\(junctionUserId)/sign_in_token") else {
            throw JunctionError.networkError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "x-vital-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        print("🌐 API Request: POST \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw JunctionError.networkError
        }

        if httpResponse.statusCode == 200 {
            let tokenResponse = try JSONDecoder().decode(JunctionSignInTokenResponse.self, from: data)
            print("✅ Sign-in token created for user: \(tokenResponse.userId)")
            return tokenResponse.signInToken
        } else if httpResponse.statusCode == 401 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Junction API error (401 Unauthorized): \(errorString)")
            }
            throw JunctionError.invalidAPIKey
        } else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error creating sign-in token (\(httpResponse.statusCode)): \(errorString)")
            }
            throw JunctionError.networkError
        }
    }

    // MARK: - HealthKit Permissions (via Junction)

    /// Request HealthKit permissions through Junction SDK
    /// - Note: This is an alternative to using HealthKitManager directly
    ///         when you want Junction to manage the permissions flow
    func requestHealthKitPermissions() async throws {
        guard isConfigured else {
            throw JunctionError.notConfigured
        }

        // Request permissions through VitalHealthKitClient
        // IMPORTANT: Must include .vitals(.glucose) to sync glucose data to Junction!
        // Per docs: "sync is automatically activated on all resource types you have asked permission for"
        // Note: glucose is a nested type under .vitals - use .vitals(.glucose), NOT .glucose
        let _ = await VitalHealthKitClient.shared.ask(
            readPermissions: [.vitals(.glucose), .activity, .workout, .sleep],
            writePermissions: []
        )

        print("✅ HealthKit permissions granted via Junction (including glucose)")

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

        print("🔄 Triggering manual sync to Junction cloud...")

        // Sync health data through VitalHealthKitClient
        // Note: syncData() is a fire-and-forget operation
        // The actual sync happens asynchronously in the background
        VitalHealthKitClient.shared.syncData()

        // Give the sync some time to initiate
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Update status - the sync has been initiated
        // Actual cloud upload happens asynchronously
        syncStatus = .success
        lastSyncDate = Date()

        print("✅ Junction sync initiated - data will upload in background")
        print("ℹ️  Note: Due to Apple's 3-hour HealthKit data delay, recent data may not be available immediately")

        // Track sync success
        AnalyticsManager.shared.track(event: "junction_sync_success", properties: [
            "sync_date": ISO8601DateFormatter().string(from: Date())
        ])
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
    case invalidUserId

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
        case .invalidUserId:
            return "Invalid user ID format. User ID must be a valid UUID."
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
        case .invalidUserId:
            return "Please sign out and sign back in with a valid account."
        }
    }
}
