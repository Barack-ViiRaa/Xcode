//
//  HealthDataModels.swift
//  ViiRaa
//
//  Created by Claude on 2025-10-21.
//  Health data models for easier consumption and serialization
//

import Foundation
import HealthKit

// MARK: - Glucose Data

struct GlucoseReading: Codable, Identifiable {
    let id: String
    let value: Double // mg/dL
    let timestamp: Date
    let source: String
    let trend: GlucoseTrend?
    let dataSource: DataSource?

    // MARK: - Glucose Trend
    enum GlucoseTrend: String, Codable {
        case rapidlyRising    // ↑↑
        case rising          // ↑
        case stable          // →
        case falling         // ↓
        case rapidlyFalling  // ↓↓

        var symbol: String {
            switch self {
            case .rapidlyRising: return "↑↑"
            case .rising: return "↑"
            case .stable: return "→"
            case .falling: return "↓"
            case .rapidlyFalling: return "↓↓"
            }
        }

        var description: String {
            switch self {
            case .rapidlyRising: return "Rapidly Rising"
            case .rising: return "Rising"
            case .stable: return "Stable"
            case .falling: return "Falling"
            case .rapidlyFalling: return "Rapidly Falling"
            }
        }
    }

    // MARK: - Data Source
    enum DataSource: String, Codable {
        case bleFollowMode = "ble_follow"
        case healthKit = "healthkit"
        case junction = "junction"

        var displayName: String {
            switch self {
            case .bleFollowMode: return "BLE Follow Mode"
            case .healthKit: return "HealthKit"
            case .junction: return "Junction"
            }
        }
    }

    init(from sample: HKQuantitySample) {
        self.id = sample.uuid.uuidString
        self.value = sample.quantity.doubleValue(for: HKUnit(from: "mg/dL"))
        self.timestamp = sample.endDate
        self.source = sample.sourceRevision.source.name
        self.trend = nil
        self.dataSource = .healthKit
    }

    init(id: String = UUID().uuidString, value: Double, timestamp: Date, source: String, trend: GlucoseTrend? = nil, dataSource: DataSource? = nil) {
        self.id = id
        self.value = value
        self.timestamp = timestamp
        self.source = source
        self.trend = trend
        self.dataSource = dataSource
    }
}

extension GlucoseReading {
    /// Glucose range classification
    enum Range: String {
        case veryLow = "very_low"    // < 54 mg/dL
        case low = "low"              // 54-69 mg/dL
        case normal = "normal"        // 70-180 mg/dL
        case high = "high"            // 181-250 mg/dL
        case veryHigh = "very_high"   // > 250 mg/dL
    }

    var range: Range {
        switch value {
        case ..<54:
            return .veryLow
        case 54..<70:
            return .low
        case 70...180:
            return .normal
        case 181...250:
            return .high
        default:
            return .veryHigh
        }
    }

    var isInRange: Bool {
        return range == .normal
    }

    // MARK: - BLE-specific helper methods
    var isRecent: Bool {
        let now = Date()
        let timeInterval = now.timeIntervalSince(timestamp)
        return timeInterval < 900 // Less than 15 minutes
    }

    var formattedValue: String {
        return String(format: "%.0f mg/dL", value)
    }

    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - BLE Follow Error
enum BLEFollowError: Error, LocalizedError {
    case bluetoothUnavailable
    case unauthorizedAccess
    case connectionFailed
    case dataParsingFailed
    case validationFailed
    case sensorNotFound
    case timeout

    var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable:
            return "Bluetooth is not available on this device"
        case .unauthorizedAccess:
            return "Bluetooth access is not authorized. Please enable it in Settings."
        case .connectionFailed:
            return "Failed to connect to the glucose sensor"
        case .dataParsingFailed:
            return "Failed to parse glucose data from the sensor"
        case .validationFailed:
            return "Glucose reading validation failed"
        case .sensorNotFound:
            return "No Abbott Lingo sensor found nearby"
        case .timeout:
            return "Connection timeout. Please ensure the sensor is nearby."
        }
    }
}

// MARK: - Weight Data

struct WeightReading: Codable, Identifiable {
    let id: String
    let valuePounds: Double
    let valueKilograms: Double
    let timestamp: Date
    let source: String

    init(from sample: HKQuantitySample) {
        self.id = sample.uuid.uuidString
        self.valuePounds = sample.quantity.doubleValue(for: .pound())
        self.valueKilograms = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
        self.timestamp = sample.endDate
        self.source = sample.sourceRevision.source.name
    }
}

// MARK: - Activity Data

struct ActivitySummary: Codable {
    let date: Date
    let steps: Int
    let activeEnergyKcal: Double
    let exerciseMinutes: Int
    let standHours: Int?

    init(date: Date, steps: Int, activeEnergy: Double, exerciseMinutes: Int, standHours: Int? = nil) {
        self.date = date
        self.steps = steps
        self.activeEnergyKcal = activeEnergy
        self.exerciseMinutes = exerciseMinutes
        self.standHours = standHours
    }
}

extension ActivitySummary {
    /// Check if user met recommended daily goals
    var metStepsGoal: Bool {
        return steps >= 10000
    }

    var metExerciseGoal: Bool {
        return exerciseMinutes >= 30
    }

    var metCalorieGoal: Bool {
        return activeEnergyKcal >= 400
    }
}

// MARK: - Health Summary

struct HealthSummary: Codable {
    let timestamp: Date
    let glucose: GlucoseReading?
    let weight: WeightReading?
    let activity: ActivitySummary?

    init(timestamp: Date = Date(), glucose: GlucoseReading? = nil, weight: WeightReading? = nil, activity: ActivitySummary? = nil) {
        self.timestamp = timestamp
        self.glucose = glucose
        self.weight = weight
        self.activity = activity
    }
}

extension HealthSummary {
    /// Convert to dictionary for JavaScript injection
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "timestamp": timestamp.timeIntervalSince1970
        ]

        if let glucose = glucose {
            dict["glucose"] = [
                "value": glucose.value,
                "timestamp": glucose.timestamp.timeIntervalSince1970,
                "range": glucose.range.rawValue,
                "source": glucose.source
            ]
        }

        if let weight = weight {
            dict["weight"] = [
                "value_lbs": weight.valuePounds,
                "value_kg": weight.valueKilograms,
                "timestamp": weight.timestamp.timeIntervalSince1970,
                "source": weight.source
            ]
        }

        if let activity = activity {
            dict["activity"] = [
                "date": activity.date.timeIntervalSince1970,
                "steps": activity.steps,
                "active_energy_kcal": activity.activeEnergyKcal,
                "exercise_minutes": activity.exerciseMinutes,
                "met_steps_goal": activity.metStepsGoal,
                "met_exercise_goal": activity.metExerciseGoal,
                "met_calorie_goal": activity.metCalorieGoal
            ]
        }

        return dict
    }

    /// Convert to JSON string for JavaScript injection
    func toJSONString() -> String? {
        guard let jsonData = try? JSONEncoder().encode(self),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
}

// MARK: - HealthKit Authorization Status

struct HealthKitAuthorizationStatus {
    let isAvailable: Bool
    let glucoseAuthorized: Bool
    let weightAuthorized: Bool
    let activityAuthorized: Bool

    var allAuthorized: Bool {
        return isAvailable && glucoseAuthorized && weightAuthorized && activityAuthorized
    }

    static func check(healthStore: HKHealthStore) -> HealthKitAuthorizationStatus {
        guard HKHealthStore.isHealthDataAvailable() else {
            return HealthKitAuthorizationStatus(
                isAvailable: false,
                glucoseAuthorized: false,
                weightAuthorized: false,
                activityAuthorized: false
            )
        }

        let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose)!
        let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount)!

        return HealthKitAuthorizationStatus(
            isAvailable: true,
            glucoseAuthorized: healthStore.authorizationStatus(for: glucoseType) == .sharingAuthorized,
            weightAuthorized: healthStore.authorizationStatus(for: weightType) == .sharingAuthorized,
            activityAuthorized: healthStore.authorizationStatus(for: stepsType) == .sharingAuthorized
        )
    }
}

// MARK: - Glucose Statistics

struct GlucoseStatistics: Codable {
    let averageGlucose: Double
    let minimumGlucose: Double
    let maximumGlucose: Double
    let standardDeviation: Double
    let timeInRange: Double // Percentage (0-100)
    let readingsCount: Int
    let period: DateInterval

    init(readings: [GlucoseReading], period: DateInterval) {
        self.period = period
        self.readingsCount = readings.count

        guard !readings.isEmpty else {
            self.averageGlucose = 0
            self.minimumGlucose = 0
            self.maximumGlucose = 0
            self.standardDeviation = 0
            self.timeInRange = 0
            return
        }

        let values = readings.map { $0.value }

        // Calculate average
        let avg = values.reduce(0, +) / Double(values.count)
        self.averageGlucose = avg

        // Calculate min/max
        self.minimumGlucose = values.min() ?? 0
        self.maximumGlucose = values.max() ?? 0

        // Calculate standard deviation
        let variance = values.map { pow($0 - avg, 2) }.reduce(0, +) / Double(values.count)
        self.standardDeviation = sqrt(variance)

        // Calculate time in range (70-180 mg/dL)
        let inRangeCount = readings.filter { $0.isInRange }.count
        self.timeInRange = (Double(inRangeCount) / Double(readingsCount)) * 100
    }
}

extension GlucoseStatistics {
    /// Convert to dictionary for display
    func toDictionary() -> [String: Any] {
        return [
            "average_glucose": averageGlucose,
            "minimum_glucose": minimumGlucose,
            "maximum_glucose": maximumGlucose,
            "standard_deviation": standardDeviation,
            "time_in_range_percent": timeInRange,
            "readings_count": readingsCount,
            "period_start": period.start.timeIntervalSince1970,
            "period_end": period.end.timeIntervalSince1970
        ]
    }
}

// MARK: - Weight Trend

struct WeightTrend: Codable {
    let readings: [WeightReading]
    let currentWeight: Double
    let startWeight: Double
    let weightChange: Double
    let trend: TrendDirection
    let period: DateInterval

    enum TrendDirection: String, Codable {
        case increasing = "increasing"
        case decreasing = "decreasing"
        case stable = "stable"
    }

    init(readings: [WeightReading], period: DateInterval) {
        self.readings = readings.sorted { $0.timestamp < $1.timestamp }
        self.period = period

        if let first = self.readings.first, let last = self.readings.last {
            self.startWeight = first.valuePounds
            self.currentWeight = last.valuePounds
            self.weightChange = currentWeight - startWeight

            if abs(weightChange) < 1.0 {
                self.trend = .stable
            } else if weightChange > 0 {
                self.trend = .increasing
            } else {
                self.trend = .decreasing
            }
        } else {
            self.startWeight = 0
            self.currentWeight = 0
            self.weightChange = 0
            self.trend = .stable
        }
    }

    var percentageChange: Double {
        guard startWeight > 0 else { return 0 }
        return (weightChange / startWeight) * 100
    }
}
