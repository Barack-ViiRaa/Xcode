//
//  AppDelegate.swift
//  ViiRaa
//
//  Created by Claude on 2025-12-02.
//  Required for Vital Health SDK background delivery and automatic sync
//

import UIKit
import VitalCore
import VitalHealthKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // CRITICAL: Configure VitalClient FIRST before VitalHealthKitClient
        // The SDK requires this order: VitalClient.configure() -> VitalHealthKitClient.automaticConfiguration()
        // Without this order, JWT sign-in will fail with VitalJWTSignInError
        // Bug 19: https://docs.junction.com/wearables/sdks/authentication
        //
        // NOTE: VitalClient.configure() is deprecated in favor of new authentication API
        // However, this is still the documented initialization method. Code is functional despite warnings.
        // TODO: Update to new SDK initialization when migration documentation is available
        if Constants.isJunctionEnabled {
            if Constants.junctionEnvironment == "sandbox" {
                VitalClient.configure(apiKey: Constants.junctionAPIKey, environment: .sandbox(.us))
            } else {
                VitalClient.configure(apiKey: Constants.junctionAPIKey, environment: .production(.us))
            }
            print("🔗 VitalClient configured with \(Constants.junctionEnvironment) environment (AppDelegate)")
        }

        // THEN configure VitalHealthKitClient for background delivery
        // This MUST be called synchronously before this method returns
        // Without this, background delivery will not work and data won't sync to Junction
        VitalHealthKitClient.automaticConfiguration()

        print("✅ VitalHealthKitClient configured for background delivery")

        return true
    }
}
