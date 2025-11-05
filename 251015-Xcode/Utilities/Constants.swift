//
//  Constants.swift
//  ViiRaaApp
//
//  Created by ViiRaa Team
//  Copyright © 2025 ViiRaa. All rights reserved.
//

import Foundation

struct Constants {
    // App Information
    static let appName = "ViiRaa"
    static let bundleIdentifier = "com.viiraa.app"
    static let appStoreID = "YOUR_APP_STORE_ID"

    // API Configuration
    static let baseURL = "https://viiraa.com"
    static let dashboardPath = "/dashboard"
    static let apiPath = "/api"

    // Supabase Configuration
    static let supabaseURL = "https://efwiicipqhurfcpczmnw.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVmd2lpY2lwcWh1cmZjcGN6bW53Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxNzA1MjgsImV4cCI6MjA2MDc0NjUyOH0.J5CqHIgEpRrQgQI_Ngqp8tOlHe41nM5m9vMuOUlfy3Y"

    // PostHog Configuration
    static let posthogAPIKey = "phc_9mIgGbUnOuES2iboBHsZ8EWUDBk2bVAhSO4sxz4DSrA"
    static let posthogHost = "https://us.posthog.com"

    // Feature Flags
    static let isHealthKitEnabled = true
    static let isPushNotificationsEnabled = false

    // UI Colors (Sage Green Primary)
    static let primaryColorHex = "#A8B79E"

    // Computed Properties
    static var dashboardURL: String {
        return baseURL + dashboardPath
    }
}
