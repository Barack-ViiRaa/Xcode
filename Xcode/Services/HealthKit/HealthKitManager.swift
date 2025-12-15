//
//  HealthKitManager.swift
//  ViiRaa
//
//  Created by Claude on 2025-10-21.
//  Manager for Apple HealthKit integration - Phase 2
//

import Foundation
import HealthKit
import Combine

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    // Published properties for UI reactivity
    @Published var isAuthorized = false
    @Published var authorizationError: Error?
    @Published var latestGlucoseReading: HKQuantitySample?
    @Published var latestWeight: HKQuantitySample?
    @Published var todayStepCount: Double = 0
    @Published private(set) var isHealthKitAvailable: Bool = false

    // For conformance with ObservableObject when using @MainActor
    nonisolated let objectWillChange = ObservableObjectPublisher()

    private init() {
        // Check HealthKit availability at initialization
        self.isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Availability Check

    func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    /// Request authorization to read health data from HealthKit
    /// - Throws: HealthKitError if HealthKit is not available or authorization fails
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        // Define health data types to read
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!
        ]

        // We're only reading data, not writing
        let typesToWrite: Set<HKSampleType> = []

        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            self.isAuthorized = true
            self.authorizationError = nil

            // Track authorization event
            AnalyticsManager.shared.track(event: "healthkit_authorized")
        } catch {
            self.authorizationError = error
            self.isAuthorized = false

            // Track authorization failure
            AnalyticsManager.shared.track(event: "healthkit_authorization_failed", properties: [
                "error": error.localizedDescription
            ])

            throw error
        }
    }

    /// Check authorization status for a specific health data type
    /// - Parameter type: The health data type to check
    /// - Returns: Authorization status
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return healthStore.authorizationStatus(for: type)
    }

    // MARK: - Glucose Data (CGM)

    /// Fetch the most recent glucose reading from HealthKit
    /// - Returns: Latest HKQuantitySample for blood glucose, or nil if none found
    /// - Throws: HealthKitError if the data type is not available
    func fetchLatestGlucose() async throws -> HKQuantitySample? {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else {
            throw HealthKitError.typeNotAvailable
        }

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: glucoseType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let glucoseSample = samples?.first as? HKQuantitySample

                Task { @MainActor [weak self] in
                    self?.latestGlucoseReading = glucoseSample
                }

                continuation.resume(returning: glucoseSample)
            }

            self.healthStore.execute(query)
        }
    }

    /// Fetch glucose history for a specific date range
    /// - Parameters:
    ///   - startDate: Start date for the query
    ///   - endDate: End date for the query
    /// - Returns: Array of HKQuantitySample for blood glucose in the date range
    /// - Throws: HealthKitError if the data type is not available
    func fetchGlucoseHistory(startDate: Date, endDate: Date) async throws -> [HKQuantitySample] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else {
            throw HealthKitError.typeNotAvailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: glucoseType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let glucoseSamples = samples as? [HKQuantitySample] ?? []
                continuation.resume(returning: glucoseSamples)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Weight Data

    /// Fetch the most recent weight measurement from HealthKit
    /// - Returns: Latest HKQuantitySample for body mass, or nil if none found
    /// - Throws: HealthKitError if the data type is not available
    func fetchLatestWeight() async throws -> HKQuantitySample? {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.typeNotAvailable
        }

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let weightSample = samples?.first as? HKQuantitySample

                Task { @MainActor [weak self] in
                    self?.latestWeight = weightSample
                }

                continuation.resume(returning: weightSample)
            }

            self.healthStore.execute(query)
        }
    }

    /// Fetch weight history for a specific date range
    /// - Parameters:
    ///   - startDate: Start date for the query
    ///   - endDate: End date for the query
    /// - Returns: Array of HKQuantitySample for body mass in the date range
    /// - Throws: HealthKitError if the data type is not available
    func fetchWeightHistory(startDate: Date, endDate: Date) async throws -> [HKQuantitySample] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.typeNotAvailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let weightSamples = samples as? [HKQuantitySample] ?? []
                continuation.resume(returning: weightSamples)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Activity Data

    /// Fetch step count for a specific date
    /// - Parameter date: Date to query steps for (defaults to today)
    /// - Returns: Total step count for the date
    /// - Throws: HealthKitError if the data type is not available
    func fetchStepCount(for date: Date = Date()) async throws -> Double {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.typeNotAvailable
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { [weak self] _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let steps = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0

                Task { @MainActor [weak self] in
                    self?.todayStepCount = steps
                }

                continuation.resume(returning: steps)
            }

            self?.healthStore.execute(query)
        }
    }

    /// Fetch active energy burned for a specific date
    /// - Parameter date: Date to query active energy for (defaults to today)
    /// - Returns: Total active energy burned in kilocalories
    /// - Throws: HealthKitError if the data type is not available
    func fetchActiveEnergy(for date: Date = Date()) async throws -> Double {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.typeNotAvailable
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let energy = statistics?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: energy)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch exercise minutes for a specific date
    /// - Parameter date: Date to query exercise time for (defaults to today)
    /// - Returns: Total exercise minutes
    /// - Throws: HealthKitError if the data type is not available
    func fetchExerciseMinutes(for date: Date = Date()) async throws -> Double {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        guard let exerciseType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) else {
            throw HealthKitError.typeNotAvailable
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: exerciseType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let minutes = statistics?.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0
                continuation.resume(returning: minutes)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Convenience Methods

    /// Fetch all health data summaries for today
    /// - Returns: Dictionary with health data summaries
    func fetchTodayHealthSummary() async throws -> [String: Any] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        var summary: [String: Any] = [:]

        // Fetch all data in parallel
        async let glucose = try? fetchLatestGlucose()
        async let weight = try? fetchLatestWeight()
        async let steps = try? fetchStepCount()
        async let energy = try? fetchActiveEnergy()
        async let exercise = try? fetchExerciseMinutes()

        let (glucoseResult, weightResult, stepsResult, energyResult, exerciseResult) = await (
            glucose, weight, steps, energy, exercise
        )

        // Build summary dictionary
        if let glucoseSample = glucoseResult {
            let value = glucoseSample.quantity.doubleValue(for: HKUnit(from: "mg/dL"))
            summary["glucose_mg_dl"] = value
            summary["glucose_timestamp"] = glucoseSample.endDate.timeIntervalSince1970
        }

        if let weightSample = weightResult {
            let value = weightSample.quantity.doubleValue(for: HKUnit.pound())
            summary["weight_lbs"] = value
            summary["weight_timestamp"] = weightSample.endDate.timeIntervalSince1970
        }

        if let steps = stepsResult {
            summary["steps"] = steps
        }

        if let energy = energyResult {
            summary["active_energy_kcal"] = energy
        }

        if let exercise = exerciseResult {
            summary["exercise_minutes"] = exercise
        }

        return summary
    }
}

// MARK: - Error Types

enum HealthKitError: LocalizedError {
    case notAvailable
    case typeNotAvailable
    case authorizationDenied
    case queryFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device."
        case .typeNotAvailable:
            return "The requested health data type is not available."
        case .authorizationDenied:
            return "HealthKit authorization was denied. Please enable health data access in Settings."
        case .queryFailed(let error):
            return "Failed to query health data: \(error.localizedDescription)"
        }
    }
}
