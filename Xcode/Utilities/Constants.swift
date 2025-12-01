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

    // Junction (Vital) SDK Configuration
    // Reference: /Users/barack/Downloads/Xcode/3rd_Party_Bio_Data_Integration_Report.md
    // Note: Replace with actual API key after signing BAA with Junction
    static let junctionAPIKey = "YOUR_JUNCTION_API_KEY"
    static let junctionEnvironment = "sandbox" // "sandbox" or "production"

    // Feature Flags
    static let isHealthKitEnabled = true
    static let isPushNotificationsEnabled = false
    static let isJunctionEnabled = false // Enable after Junction contract is signed

    // UI Colors (Sage Green Primary)
    static let primaryColorHex = "#A8B79E"

    // Computed Properties
    static var dashboardURL: String {
        return baseURL + dashboardPath
    }
}
