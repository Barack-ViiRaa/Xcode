import SwiftUI

struct BLESetupGuideView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("BLE Follow Mode Setup")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Get real-time glucose readings with 1-5 minute latency")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)

                    // Requirements Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Requirements", icon: "checkmark.circle.fill")

                        RequirementRow(
                            icon: "app.badge",
                            title: "Abbott Lingo App",
                            description: "Install the official Abbott Lingo app from the App Store"
                        )

                        RequirementRow(
                            icon: "sensor.fill",
                            title: "Abbott Lingo Sensor",
                            description: "Active sensor paired with the Abbott Lingo app"
                        )

                        RequirementRow(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "Bluetooth Enabled",
                            description: "Keep Bluetooth on for continuous monitoring"
                        )
                    }

                    Divider()

                    // Setup Steps
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Setup Steps", icon: "list.number")

                        SetupStepRow(
                            number: 1,
                            title: "Install Abbott Lingo App",
                            description: "Download and install the official Abbott Lingo app from the App Store",
                            action: {
                                if let url = URL(string: "https://apps.apple.com/us/app/lingo-by-abbott/id6478821307") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        )

                        SetupStepRow(
                            number: 2,
                            title: "Pair Your Sensor",
                            description: "Use the Abbott Lingo app to pair your CGM sensor and complete the warm-up period (60 minutes)"
                        )

                        SetupStepRow(
                            number: 3,
                            title: "Enable BLE Follow Mode",
                            description: "Return to ViiRaa and toggle on 'Enable Real-time Glucose' in Settings"
                        )

                        SetupStepRow(
                            number: 4,
                            title: "Keep Both Apps Open",
                            description: "For best results, keep both Abbott Lingo and ViiRaa running in the background"
                        )
                    }

                    Divider()

                    // How It Works
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "How It Works", icon: "info.circle.fill")

                        InfoCard(
                            title: "Follower Mode Technology",
                            description: "ViiRaa monitors public Bluetooth communications from the Abbott Lingo app to provide real-time glucose updates. This approach is safe, legal, and respects Abbott's Terms of Service.",
                            color: .blue
                        )

                        InfoCard(
                            title: "Data Privacy",
                            description: "All glucose data stays on your device. ViiRaa uses the same privacy-first approach as the Abbott Lingo app.",
                            color: .green
                        )

                        InfoCard(
                            title: "Dual Data Sources",
                            description: "BLE Follow Mode provides real-time data (1-5 min latency), while Junction SDK provides historical data for ML training and long-term analysis.",
                            color: .purple
                        )
                    }

                    Divider()

                    // Troubleshooting
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Troubleshooting", icon: "wrench.and.screwdriver.fill")

                        TroubleshootingRow(
                            issue: "No devices found",
                            solution: "Ensure Abbott Lingo app is running and Bluetooth is enabled. Try restarting both apps."
                        )

                        TroubleshootingRow(
                            issue: "Connection failed",
                            solution: "Make sure your sensor is within Bluetooth range (about 20 feet). Check that the sensor is active in Abbott Lingo app."
                        )

                        TroubleshootingRow(
                            issue: "Outdated readings",
                            solution: "Ensure Abbott Lingo app has permission to run in background. Check Settings > General > Background App Refresh."
                        )
                    }

                    // Contact Support
                    VStack(alignment: .center, spacing: 12) {
                        Text("Need Help?")
                            .font(.headline)

                        Button(action: {
                            if let url = URL(string: "mailto:support@viiraa.com") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Contact Support")
                                    .bold()
                            }
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

struct RequirementRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.green)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SetupStepRow: View {
    let number: Int
    let title: String
    let description: String
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 30, height: 30)
                Text("\(number)")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let action = action {
                    Button(action: action) {
                        HStack(spacing: 4) {
                            Text("Open App Store")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}

struct InfoCard: View {
    let title: String
    let description: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct TroubleshootingRow: View {
    let issue: String
    let solution: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(issue)
                    .font(.body)
                    .fontWeight(.semibold)
            }

            Text(solution)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 28)
        }
    }
}

#Preview {
    BLESetupGuideView()
}
