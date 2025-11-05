//
//  HealthKitPermissionView.swift
//  ViiRaa
//
//  Created by Claude on 2025-10-21.
//  Native UI for requesting HealthKit permissions
//

import SwiftUI
import HealthKit

struct HealthKitPermissionView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool

    @State private var isRequesting = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Benefits
                    benefitsSection

                    // Data Types
                    dataTypesSection

                    // Privacy Notice
                    privacySection

                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Health Data Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        isPresented = false
                    }
                    .foregroundColor(.secondary)
                }
            }
            .alert("Permission Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(Color(hex: Constants.primaryColorHex))

            Text("Connect Your Health Data")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("ViiRaa uses your health data to provide personalized insights and track your wellness journey.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What You'll Get")
                .font(.headline)

            benefitRow(
                icon: "drop.fill",
                title: "Glucose Insights",
                description: "Track your glucose levels and identify patterns"
            )

            benefitRow(
                icon: "figure.walk",
                title: "Activity Tracking",
                description: "Monitor your daily steps and exercise minutes"
            )

            benefitRow(
                icon: "scalemass.fill",
                title: "Weight Management",
                description: "Track your weight trends over time"
            )

            benefitRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Personalized Recommendations",
                description: "Get AI-powered insights based on your health data"
            )
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: Constants.primaryColorHex))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Data Types Section

    private var dataTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data We'll Read")
                .font(.headline)

            dataTypeRow(icon: "drop.fill", name: "Blood Glucose", description: "CGM readings")
            dataTypeRow(icon: "scalemass.fill", name: "Weight", description: "Body mass measurements")
            dataTypeRow(icon: "figure.walk", name: "Steps", description: "Daily step count")
            dataTypeRow(icon: "flame.fill", name: "Active Energy", description: "Calories burned")
            dataTypeRow(icon: "timer", name: "Exercise Time", description: "Workout minutes")
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    private func dataTypeRow(icon: String, name: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: Constants.primaryColorHex))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(Color(hex: Constants.primaryColorHex))

                Text("Your Privacy Matters")
                    .font(.headline)
            }

            Text("• Your health data is encrypted and stored securely")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("• We never sell or share your health data with third parties")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("• You can revoke access anytime in Settings")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: {
                // Open privacy policy URL
                if let url = URL(string: "https://www.viiraa.com/ViiRaa_Privacy_Policy_Notice_US_20250808.pdf") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Read Our Privacy Policy")
                    .font(.caption)
                    .foregroundColor(Color(hex: Constants.primaryColorHex))
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: requestPermission) {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Allow Access")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: Constants.primaryColorHex))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isRequesting)

            Button(action: {
                isPresented = false
            }) {
                Text("Maybe Later")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
            .disabled(isRequesting)
        }
        .padding(.top)
    }

    // MARK: - Actions

    private func requestPermission() {
        isRequesting = true

        Task {
            do {
                try await healthKitManager.requestAuthorization()

                // Track successful authorization
                AnalyticsManager.shared.track(event: "healthkit_permission_granted")

                // Dismiss the view after successful authorization
                await MainActor.run {
                    isPresented = false
                }
            } catch {
                // Handle error
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }

                // Track authorization failure
                AnalyticsManager.shared.track(event: "healthkit_permission_denied", properties: [
                    "error": error.localizedDescription
                ])
            }

            await MainActor.run {
                isRequesting = false
            }
        }
    }
}

// MARK: - Preview

struct HealthKitPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitPermissionView(isPresented: .constant(true))
    }
}
