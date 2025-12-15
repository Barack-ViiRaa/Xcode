import Foundation
import CoreBluetooth
import Combine

@MainActor
class BLEFollowManager: NSObject, ObservableObject {
    static let shared = BLEFollowManager()

    // MARK: - Published Properties
    @Published var isEnabled = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var latestGlucoseReading: GlucoseReading?
    @Published var lastUpdateTime: Date?
    @Published var discoveredDevices: [DiscoveredDevice] = []
    @Published var error: BLEFollowError?

    // MARK: - Private Properties
    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var scanTimer: Timer?

    // Abbott Lingo CGM Service UUID (monitoring public advertisements)
    // Note: This is a placeholder - actual implementation would monitor
    // the official Abbott Lingo app's BLE communications
    private let abbottServiceUUID = CBUUID(string: "FFF0")
    private let glucoseCharacteristicUUID = CBUUID(string: "FFF1")

    // MARK: - Connection Status
    enum ConnectionStatus: Equatable {
        case disconnected
        case scanning
        case connecting
        case connected
        case error(String)

        static func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected),
                 (.scanning, .scanning),
                 (.connecting, .connecting),
                 (.connected, .connected):
                return true
            case (.error(let lhsMsg), .error(let rhsMsg)):
                return lhsMsg == rhsMsg
            default:
                return false
            }
        }
    }

    // MARK: - Discovered Device
    struct DiscoveredDevice: Identifiable {
        let id: UUID
        let name: String
        let rssi: Int
        let lastSeen: Date
    }

    // MARK: - Initialization
    private override init() {
        super.init()
        loadSavedState()
    }

    // MARK: - Configuration
    func enable() {
        guard !isEnabled else { return }
        isEnabled = true
        UserDefaults.standard.set(true, forKey: "bleFollowModeEnabled")
        startMonitoring()
    }

    func disable() {
        guard isEnabled else { return }
        isEnabled = false
        UserDefaults.standard.set(false, forKey: "bleFollowModeEnabled")
        stopMonitoring()
    }

    private func loadSavedState() {
        isEnabled = UserDefaults.standard.bool(forKey: "bleFollowModeEnabled")
        if isEnabled {
            startMonitoring()
        }
    }

    // MARK: - BLE Monitoring
    private func startMonitoring() {
        // Initialize Core Bluetooth
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )
        connectionStatus = .scanning
    }

    private func stopMonitoring() {
        scanTimer?.invalidate()
        scanTimer = nil
        centralManager?.stopScan()

        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }

        centralManager = nil
        connectedPeripheral = nil
        discoveredPeripherals.removeAll()
        discoveredDevices.removeAll()
        connectionStatus = .disconnected
    }

    private func startScanning() {
        guard let centralManager = centralManager else { return }

        // Scan for Abbott Lingo app BLE communications
        // Monitor public BLE advertisements only
        // Following the "Follower Mode" approach - not reverse engineering
        centralManager.scanForPeripherals(
            withServices: nil, // Monitor general BLE traffic
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )

        connectionStatus = .scanning

        // Auto-stop scanning after 30 seconds to save battery
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stopScanning()
            }
        }
    }

    private func stopScanning() {
        centralManager?.stopScan()
        scanTimer?.invalidate()
        scanTimer = nil

        if connectionStatus == .scanning {
            connectionStatus = .disconnected
        }
    }

    func connectToDevice(_ deviceId: UUID) {
        guard let peripheral = discoveredPeripherals[deviceId] else {
            error = .sensorNotFound
            return
        }

        connectionStatus = .connecting
        centralManager?.connect(peripheral, options: nil)
    }

    func disconnectCurrentDevice() {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }

    // MARK: - Data Processing
    private func processGlucoseData(_ data: Data, from peripheral: CBPeripheral) {
        // Parse BLE data packets from Abbott Lingo communication
        // Extract glucose value, timestamp, and trend
        // This follows Follower Mode approach - monitoring existing communication
        // NOT reverse engineering or decrypting proprietary protocols

        guard let glucoseValue = extractGlucoseValue(from: data),
              let timestamp = extractTimestamp(from: data) else {
            error = .dataParsingFailed
            return
        }

        let trend = extractTrend(from: data)

        let reading = GlucoseReading(
            value: glucoseValue,
            timestamp: timestamp,
            source: "BLE Follow Mode",
            trend: trend,
            dataSource: .bleFollowMode
        )

        latestGlucoseReading = reading
        lastUpdateTime = Date()
        error = nil

        // Cross-validate with Junction data
        Task {
            await validateWithJunctionData(reading)
        }

        // Track analytics
        trackGlucoseReading(reading)
    }

    private func extractGlucoseValue(from data: Data) -> Double? {
        // Implementation based on xDrip4iOS approach
        // Monitors public BLE advertisements
        // Does not decrypt proprietary data

        // Placeholder implementation - actual parsing would depend on
        // Abbott Lingo's public BLE advertisement format
        guard data.count >= 4 else { return nil }

        // Example parsing (simplified)
        let bytes = [UInt8](data)
        let rawValue = UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)
        return Double(rawValue) / 10.0 // Convert to mg/dL
    }

    private func extractTimestamp(from data: Data) -> Date? {
        // Extract timestamp from BLE packet
        // Placeholder implementation
        return Date()
    }

    private func extractTrend(from data: Data) -> GlucoseReading.GlucoseTrend? {
        // Extract trend information if available
        // Placeholder implementation
        guard data.count >= 5 else { return nil }

        let trendByte = data[4]
        switch trendByte {
        case 1: return .rapidlyFalling
        case 2: return .falling
        case 3: return .stable
        case 4: return .rising
        case 5: return .rapidlyRising
        default: return nil
        }
    }

    // MARK: - Data Validation
    private func validateWithJunctionData(_ reading: GlucoseReading) async {
        // Cross-validate BLE reading with Junction/HealthKit data
        // Ensure accuracy > 95%
        // Log discrepancies for monitoring

        // This would integrate with JunctionManager to compare readings
        // For now, placeholder implementation
    }

    private func trackGlucoseReading(_ reading: GlucoseReading) {
        // Track analytics event
        // This would integrate with AnalyticsManager
        // Placeholder for now
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEFollowManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                startScanning()
            case .poweredOff:
                connectionStatus = .error("Bluetooth is powered off")
                error = .bluetoothUnavailable
            case .unauthorized:
                connectionStatus = .error("Bluetooth access not authorized")
                error = .unauthorizedAccess
            case .unsupported:
                connectionStatus = .error("Bluetooth not supported on this device")
                error = .bluetoothUnavailable
            case .resetting:
                connectionStatus = .disconnected
            case .unknown:
                connectionStatus = .disconnected
            @unknown default:
                connectionStatus = .disconnected
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        Task { @MainActor in
            // Filter for Abbott Lingo related peripherals
            // Check manufacturer data or service UUIDs
            let name = peripheral.name ?? "Unknown Device"

            // Only track Abbott-related devices
            // This is a simplified check - actual implementation would be more sophisticated
            guard name.contains("Abbott") || name.contains("Lingo") ||
                  advertisementData[CBAdvertisementDataServiceUUIDsKey] != nil else {
                return
            }

            // Update discovered peripherals
            discoveredPeripherals[peripheral.identifier] = peripheral

            // Update discovered devices list
            let device = DiscoveredDevice(
                id: peripheral.identifier,
                name: name,
                rssi: RSSI.intValue,
                lastSeen: Date()
            )

            if let index = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
                discoveredDevices[index] = device
            } else {
                discoveredDevices.append(device)
            }

            // Process advertisement data for glucose readings
            if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
                processGlucoseData(manufacturerData, from: peripheral)
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        Task { @MainActor in
            connectedPeripheral = peripheral
            peripheral.delegate = self
            connectionStatus = .connected

            // Discover services
            peripheral.discoverServices([abbottServiceUUID])
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            connectionStatus = .error("Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
            self.error = .connectionFailed
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            if peripheral.identifier == connectedPeripheral?.identifier {
                connectedPeripheral = nil
            }

            if let error = error {
                connectionStatus = .error("Disconnected: \(error.localizedDescription)")
            } else {
                connectionStatus = .disconnected
            }
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BLEFollowManager: CBPeripheralDelegate {
    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        Task { @MainActor in
            guard error == nil else {
                self.error = .connectionFailed
                return
            }

            // Discover characteristics
            if let services = peripheral.services {
                for service in services {
                    peripheral.discoverCharacteristics(
                        [glucoseCharacteristicUUID],
                        for: service
                    )
                }
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        Task { @MainActor in
            guard error == nil else {
                self.error = .connectionFailed
                return
            }

            // Subscribe to glucose characteristic notifications
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    if characteristic.uuid == glucoseCharacteristicUUID {
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                }
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task { @MainActor in
            guard error == nil,
                  let data = characteristic.value else {
                self.error = .dataParsingFailed
                return
            }

            // Process the glucose data
            processGlucoseData(data, from: peripheral)
        }
    }
}
