//
//  AnalyticsManager.swift
//  ViiRaaApp
//
//  Created by ViiRaa Team
//  Copyright © 2025 ViiRaa. All rights reserved.
//

import Foundation
import Combine
import PostHog

@MainActor
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()

    nonisolated let objectWillChange = ObservableObjectPublisher()

    private init() {}

    func initialize() {
        let config = PostHogConfig(
            apiKey: Constants.posthogAPIKey,
            host: Constants.posthogHost
        )

        // Capture app lifecycle events
        config.captureApplicationLifecycleEvents = true

        // Capture screen views
        config.captureScreenViews = true

        // Setup PostHog
        PostHogSDK.shared.setup(config)

        print("✅ PostHog Analytics initialized")
    }

    func identify(userId: String, traits: [String: Any]? = nil) {
        PostHogSDK.shared.identify(userId, userProperties: traits)
        print("📊 User identified: \(userId)")
    }

    func track(event: String, properties: [String: Any]? = nil) {
        PostHogSDK.shared.capture(event, properties: properties)
        print("📊 Event tracked: \(event)")
    }

    func screen(name: String, properties: [String: Any]? = nil) {
        PostHogSDK.shared.screen(name, properties: properties)
        print("📊 Screen viewed: \(name)")
    }

    func reset() {
        PostHogSDK.shared.reset()
        print("📊 Analytics reset")
    }

    // Convenience methods for common events
    func trackAppLaunch() {
        track(event: "app_launched", properties: [
            "platform": "ios",
            "version": Bundle.main.appVersion
        ])
    }

    func trackSignIn(method: String) {
        track(event: "user_signed_in", properties: [
            "method": method
        ])
    }

    func trackSignOut() {
        track(event: "user_signed_out")
    }

    func trackError(error: String, context: [String: Any]? = nil) {
        var properties = context ?? [:]
        properties["error"] = error

        track(event: "error_occurred", properties: properties)
    }
}

// MARK: - Bundle Extension for App Version

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}
