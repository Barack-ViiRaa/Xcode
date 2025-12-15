import SwiftUI

struct BLEFollowSettingsView: View {
    @StateObject private var bleManager = BLEFollowManager.shared
    @State private var showSetupGuide = false
    @State private var showDeviceList = false
    @State private var showError = false

    var body: some View {
        List {
            // Main Toggle Section
            Section {
                Toggle("Enable Real-time Glucose", isOn: $bleManager.isEnabled)
                    .onChange(of: bleManager.isEnabled) { newValue in
                        if newValue {
                            bleManager.enable()
                        } else {
                            bleManager.disable()
                        }
                    }

                if bleManager.isEnabled {
                    HStack {
                        Text("Status")
                        Spacer()
                        StatusIndicator(status: bleManager.connectionStatus)
                    }

                    if let lastUpdate = bleManager.lastUpdateTime {
                        HStack {
                            Text("Last Update")
                            Spacer()
                            Text(lastUpdate, style: .relative)
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }

                    if bleManager.connectionStatus == .connected {
                        Button(action: {
                            bleManager.disconnectCurrentDevice()
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Disconnect Device")
                            }
                            .foregroundColor(.red)
                        }
                    } else if bleManager.connectionStatus == .disconnected {
                        Button(action: {
                            showDeviceList = true
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Scan for Devices")
                            }
                        }
                    }
                }
            } header: {
                Text("BLE Follow Mode")
            } footer: {
                if bleManager.isEnabled {
                    Text("Provides real-time glucose readings with 1-5 minute latency by monitoring the Abbott Lingo app.")
                        .font(.caption)
                }
            }

            // Current Reading Section
            if let reading = bleManager.latestGlucoseReading {
                Section("Current Reading") {
                    GlucoseReadingCard(reading: reading)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            }

            // Device Management Section
            if bleManager.isEnabled && !bleManager.discoveredDevices.isEmpty {
                Section("Nearby Devices") {
                    ForEach(bleManager.discoveredDevices) { device in
                        DeviceListRow(
                            device: device,
                            isConnected: bleManager.connectionStatus == .connected,
                            onConnect: {
                                bleManager.connectToDevice(device.id)
                            }
                        )
                    }
                }
            }

            // Setup & Information Section
            Section("Setup") {
                Button(action: { showSetupGuide = true }) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Setup Instructions")
                            .foregroundColor(.primary)
                    }
                }

                Link(destination: URL(string: "https://apps.apple.com/us/app/lingo-by-abbott/id6478821307")!) {
                    HStack {
                        Image(systemName: "arrow.down.app")
                            .foregroundColor(.blue)
                        Text("Download Abbott Lingo App")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }

            // Requirements Section
            Section("Requirements") {
                VStack(alignment: .leading, spacing: 12) {
                    RequirementItem(
                        icon: "app.badge",
                        text: "Abbott Lingo app installed"
                    )

                    RequirementItem(
                        icon: "sensor.fill",
                        text: "Abbott Lingo sensor paired"
                    )

                    RequirementItem(
                        icon: "antenna.radiowaves.left.and.right",
                        text: "Bluetooth enabled"
                    )
                }
                .padding(.vertical, 4)
            }

            // Technical Details Section
            Section("Technical Details") {
                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(label: "Latency", value: "1-5 minutes")
                    DetailRow(label: "Update Frequency", value: "Every minute")
                    DetailRow(label: "Method", value: "BLE Follower Mode")
                    DetailRow(label: "Compatibility", value: "Abbott Lingo only")
                }
            }

            // Error Display Section
            if let error = bleManager.error {
                Section("Error") {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("BLE Follow Mode")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSetupGuide) {
            BLESetupGuideView()
        }
        .sheet(isPresented: $showDeviceList) {
            DeviceListSheet(bleManager: bleManager)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = bleManager.error {
                Text(error.localizedDescription)
            }
        }
        .onChange(of: bleManager.error) { newError in
            if newError != nil {
                showError = true
            }
        }
    }
}

// MARK: - Supporting Views

struct RequirementItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct DeviceListSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var bleManager: BLEFollowManager

    var body: some View {
        NavigationView {
            List {
                Section {
                    if bleManager.discoveredDevices.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)

                            Text("Scanning for devices...")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text("Make sure the Abbott Lingo app is running and Bluetooth is enabled.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(bleManager.discoveredDevices) { device in
                            DeviceListRow(
                                device: device,
                                isConnected: bleManager.connectionStatus == .connected,
                                onConnect: {
                                    bleManager.connectToDevice(device.id)
                                    dismiss()
                                }
                            )
                        }
                    }
                } header: {
                    Text("Nearby Devices")
                } footer: {
                    Text("Devices must be running the Abbott Lingo app to appear here.")
                        .font(.caption)
                }
            }
            .navigationTitle("Select Device")
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

#Preview {
    NavigationView {
        BLEFollowSettingsView()
    }
}
