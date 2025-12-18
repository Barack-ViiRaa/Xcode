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
    //
    // ⚠️ IMPORTANT - API Key Environment Selection:
    // - SANDBOX keys (sk_us_*): Create test users only, data visible in sandbox dashboard
    // - PRODUCTION keys (pk_us_*): Create real users, requires signed BAA with Junction
    //
    // Current Status: Using SANDBOX key - real user accounts will NOT appear in Junction
    // To fix Bug #22 (Personal Account Not Found):
    //   1. Sign Business Associate Agreement (BAA) with Junction/Vital
    //   2. Get production API key from https://app.tryvital.io (starts with pk_us_)
    //   3. Replace the sandbox key below with your production key
    //   4. Change junctionEnvironment to "production"
    //
    // For testing only (current configuration):
    static let junctionAPIKey = "sk_us_Gb2bkO8kvbSw0-DtyUWedO26IvtkomiYRafF7RRHMus"  // Sandbox key - REPLACE WITH PRODUCTION KEY
    static let junctionEnvironment = "sandbox"  // Change to "production" after getting production API key
    //
    // For production (after signing BAA and obtaining production API key):
    // static let junctionAPIKey = "pk_us_YOUR_PRODUCTION_KEY_HERE"  // Production key from app.tryvital.io
    // static let junctionEnvironment = "production"  // Use production environment

    // Feature Flags
    static let isHealthKitEnabled = true
    static let isPushNotificationsEnabled = false
    static let isJunctionEnabled = true // Enable after Junction contract is signed

    // UI Colors (Sage Green Primary)
    static let primaryColorHex = "#A8B79E"

    // Computed Properties
    static var dashboardURL: String {
        return baseURL + dashboardPath
    }
}
