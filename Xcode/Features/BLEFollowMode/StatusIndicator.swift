import SwiftUI

struct StatusIndicator: View {
    let status: BLEFollowManager.ConnectionStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var statusColor: Color {
        switch status {
        case .connected:
            return .green
        case .scanning, .connecting:
            return .orange
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }

    private var statusText: String {
        switch status {
        case .connected:
            return "Connected"
        case .scanning:
            return "Scanning..."
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .error(let message):
            return message
        }
    }
}

struct GlucoseReadingCard: View {
    let reading: GlucoseReading

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Glucose")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(reading.formattedValue)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(glucoseColor(for: reading.value))

                        if let trend = reading.trend {
                            Text(trend.symbol)
                                .font(.system(size: 24))
                                .foregroundColor(glucoseColor(for: reading.value))
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: sourceIcon(for: reading.dataSource ?? .healthKit))
                        .font(.system(size: 20))
                        .foregroundColor(.blue)

                    Text((reading.dataSource ?? .healthKit).displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            HStack {
                Label(reading.formattedTimestamp, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if reading.isRecent {
                    Label("Recent", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Label("Outdated", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }

    private func glucoseColor(for value: Double) -> Color {
        switch value {
        case ..<70:
            return .red
        case 70..<180:
            return .green
        default:
            return .orange
        }
    }

    private func sourceIcon(for source: GlucoseReading.DataSource) -> String {
        switch source {
        case .bleFollowMode:
            return "antenna.radiowaves.left.and.right"
        case .healthKit:
            return "heart.fill"
        case .junction:
            return "cloud.fill"
        }
    }
}

struct DeviceListRow: View {
    let device: BLEFollowManager.DiscoveredDevice
    let isConnected: Bool
    let onConnect: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Label("\(device.rssi) dBm", systemImage: "wifi")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(device.lastSeen, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isConnected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button(action: onConnect) {
                    Text("Connect")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        StatusIndicator(status: .connected)
        StatusIndicator(status: .scanning)
        StatusIndicator(status: .disconnected)
        StatusIndicator(status: .error("Connection failed"))

        GlucoseReadingCard(reading: GlucoseReading(
            value: 120,
            timestamp: Date(),
            source: "Abbott Lingo",
            trend: .stable,
            dataSource: .bleFollowMode
        ))

        DeviceListRow(
            device: BLEFollowManager.DiscoveredDevice(
                id: UUID(),
                name: "Abbott Lingo Sensor",
                rssi: -45,
                lastSeen: Date()
            ),
            isConnected: false,
            onConnect: {}
        )
    }
    .padding()
}
