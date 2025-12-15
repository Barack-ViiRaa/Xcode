//
//  GlucoseView.swift
//  ViiRaaApp
//
//  Created by ViiRaa Team
//  Copyright © 2025 ViiRaa. All rights reserved.
//

import SwiftUI
import HealthKit
import Charts

struct GlucoseView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var glucoseReadings: [GlucoseReading] = []
    @State private var statistics: GlucoseStatistics?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTimeRange: TimeRange = .today
    @State private var showPredictions = false

    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "Week"
        case month = "Month"

        var startDate: Date {
            let calendar = Calendar.current
            switch self {
            case .today:
                return calendar.startOfDay(for: Date())
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Show unavailable state if HealthKit is not available on this device
                    if !healthKitManager.isHealthKitAvailable {
                        HealthKitUnavailableView()
                            .padding()
                    } else {
                        // Time range picker
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .onChange(of: selectedTimeRange) { _ in
                            Task {
                                await loadGlucoseData()
                            }
                        }

                        // MARK: - Glucose Predictions Navigation
                        // Navigate to glucose predictions WebView (PRD Section 4.2, Lines 192-199)
                        NavigationLink(destination: GlucosePredictionWebView().environmentObject(authManager)) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.title2)
                                    .foregroundColor(Color("PrimaryColor"))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Glucose Predictions")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("View and create glucose predictions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
                        }
                        .padding(.horizontal)

                        if isLoading {
                            ProgressView("Loading glucose data...")
                                .padding()
                        } else if let errorMessage = errorMessage {
                            ErrorView(message: errorMessage) {
                                Task {
                                    await loadGlucoseData()
                                }
                            }
                        } else {
                            // Latest reading card
                            if let latestReading = glucoseReadings.first {
                                LatestGlucoseCard(reading: latestReading)
                                    .padding(.horizontal)
                            }

                            // CRITICAL Statistics card - Emphasized metrics
                            if let statistics = statistics {
                                CriticalStatisticsCard(statistics: statistics)
                                    .padding(.horizontal)

                                // Secondary statistics (smaller)
                                SecondaryStatisticsCard(statistics: statistics)
                                    .padding(.horizontal)
                            }

                            // Glucose chart
                            if !glucoseReadings.isEmpty {
                                GlucoseChartView(readings: glucoseReadings)
                                    .frame(height: 300)
                                    .padding(.horizontal)
                            }

                            // Readings list
                            if !glucoseReadings.isEmpty {
                                ReadingsListView(readings: glucoseReadings)
                                    .padding(.horizontal)
                            } else {
                                EmptyStateView()
                                    .padding()
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Glucose Data")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await loadGlucoseData()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await loadGlucoseData()
        }
    }

    private func loadGlucoseData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Check authorization
            guard healthKitManager.isHealthDataAvailable() else {
                errorMessage = "HealthKit is not available on this device"
                isLoading = false
                return
            }

            // Request authorization if needed
            if !healthKitManager.isAuthorized {
                try await healthKitManager.requestAuthorization()
            }

            // Fetch glucose history
            let startDate = selectedTimeRange.startDate
            let endDate = Date()

            let samples = try await healthKitManager.fetchGlucoseHistory(
                startDate: startDate,
                endDate: endDate
            )

            // Convert to GlucoseReading models
            glucoseReadings = samples.map { GlucoseReading(from: $0) }

            // Calculate statistics
            let period = DateInterval(start: startDate, end: endDate)
            statistics = GlucoseStatistics(readings: glucoseReadings, period: period)

            // Track analytics
            AnalyticsManager.shared.track(event: "glucose_data_loaded", properties: [
                "readings_count": glucoseReadings.count,
                "time_range": selectedTimeRange.rawValue
            ])

        } catch {
            errorMessage = error.localizedDescription
            AnalyticsManager.shared.track(event: "glucose_data_load_failed", properties: [
                "error": error.localizedDescription
            ])
        }

        isLoading = false
    }
}

// MARK: - Latest Glucose Card

struct LatestGlucoseCard: View {
    let reading: GlucoseReading

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest Reading")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text("\(Int(reading.value))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(rangeColor)

                Text("mg/dL")
                    .font(.title3)
                    .foregroundColor(.secondary)

                Spacer()

                VStack(alignment: .trailing) {
                    RangeIndicator(range: reading.range)
                    Text(reading.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("Source: \(reading.source)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }

    private var rangeColor: Color {
        switch reading.range {
        case .veryLow, .low:
            return .red
        case .normal:
            return .green
        case .high, .veryHigh:
            return .orange
        }
    }
}

// MARK: - Range Indicator

struct RangeIndicator: View {
    let range: GlucoseReading.Range

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(rangeColor)
                .frame(width: 8, height: 8)
            Text(rangeText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(rangeColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(rangeColor.opacity(0.1))
        )
    }

    private var rangeColor: Color {
        switch range {
        case .veryLow, .low:
            return .red
        case .normal:
            return .green
        case .high, .veryHigh:
            return .orange
        }
    }

    private var rangeText: String {
        switch range {
        case .veryLow:
            return "Very Low"
        case .low:
            return "Low"
        case .normal:
            return "Normal"
        case .high:
            return "High"
        case .veryHigh:
            return "Very High"
        }
    }
}

// MARK: - CRITICAL Statistics Card (Emphasized Metrics)

struct CriticalStatisticsCard: View {
    let statistics: GlucoseStatistics

    // Color coding for Time In Range
    private var timeInRangeColor: Color {
        let percentage = statistics.timeInRange
        if percentage >= 70 {
            return .green
        } else if percentage >= 50 {
            return .yellow
        } else {
            return .red
        }
    }

    // Color coding for Peak Glucose
    private var peakGlucoseColor: Color {
        let peak = statistics.maximumGlucose
        if peak > 250 {
            return .red
        } else if peak > 200 {
            return .orange
        } else {
            return .yellow
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("CRITICAL METRICS")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            // Time In Range - PRIMARY METRIC FOR WEIGHT LOSS
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundColor(timeInRangeColor)
                    Text("TIME IN RANGE")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }

                // Large prominent display
                Text("\(Int(statistics.timeInRange))%")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(timeInRangeColor)

                Text("IN TARGET RANGE (70-180 mg/dL)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Critical for weight management")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(timeInRangeColor.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(timeInRangeColor.opacity(0.3), lineWidth: 2)
                    )
            )

            // Peak Glucose - MOST DAMAGING TO THE BODY
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(peakGlucoseColor)
                    Text("PEAK GLUCOSE")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }

                // Large warning display
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(statistics.maximumGlucose))")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(peakGlucoseColor)
                    Text("mg/dL")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Text("Highest reading in period")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Minimize for better health")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.1))
                    )
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(peakGlucoseColor.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(peakGlucoseColor.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Secondary Statistics Card (Smaller display)

struct SecondaryStatisticsCard: View {
    let statistics: GlucoseStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional Statistics")
                .font(.subheadline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatItem(
                    title: "Average",
                    value: "\(Int(statistics.averageGlucose))",
                    unit: "mg/dL",
                    fontSize: .body
                )
                StatItem(
                    title: "Minimum",
                    value: "\(Int(statistics.minimumGlucose))",
                    unit: "mg/dL",
                    fontSize: .body
                )
                StatItem(
                    title: "Std Dev",
                    value: String(format: "%.1f", statistics.standardDeviation),
                    unit: "",
                    fontSize: .caption
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let unit: String
    var fontSize: Font = .title3  // Default size, can be customized

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(fontSize)
                    .fontWeight(.semibold)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Glucose Chart View

struct GlucoseChartView: View {
    let readings: [GlucoseReading]

    // Find the peak glucose reading
    private var peakReading: GlucoseReading? {
        readings.max(by: { $0.value < $1.value })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Glucose Trend")
                    .font(.headline)
                Spacer()
                if let peak = peakReading {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Peak: \(Int(peak.value)) mg/dL")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.horizontal)

            if #available(iOS 16.0, *) {
                Chart {
                    // Target range area
                    RectangleMark(
                        xStart: .value("Start", readings.last?.timestamp ?? Date()),
                        xEnd: .value("End", readings.first?.timestamp ?? Date()),
                        yStart: .value("Low", 70),
                        yEnd: .value("High", 180)
                    )
                    .foregroundStyle(Color.green.opacity(0.1))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Target Range")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }

                    // Glucose readings
                    ForEach(readings) { reading in
                        LineMark(
                            x: .value("Time", reading.timestamp),
                            y: .value("Glucose", reading.value)
                        )
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Time", reading.timestamp),
                            y: .value("Glucose", reading.value)
                        )
                        .foregroundStyle(pointColor(for: reading))
                        .symbolSize(reading.id == peakReading?.id ? 100 : 50)

                        // Highlight peak glucose with annotation
                        if reading.id == peakReading?.id {
                            PointMark(
                                x: .value("Time", reading.timestamp),
                                y: .value("Glucose", reading.value)
                            )
                            .foregroundStyle(.red)
                            .symbolSize(150)
                            .symbol {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                            }
                            .annotation(position: .top) {
                                VStack(spacing: 2) {
                                    Text("PEAK")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                    Text("\(Int(reading.value))")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.red)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.red.opacity(0.1))
                                )
                            }
                        }
                    }
                }
                .chartYScale(domain: 40...300)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 250)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
            } else {
                Text("Chart requires iOS 16 or later")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }

    private func pointColor(for reading: GlucoseReading) -> Color {
        // Special color for peak reading
        if reading.id == peakReading?.id {
            return .red
        }

        switch reading.range {
        case .veryLow, .low:
            return .red
        case .normal:
            return .green
        case .high, .veryHigh:
            return .orange
        }
    }
}

// MARK: - Readings List View

struct ReadingsListView: View {
    let readings: [GlucoseReading]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Readings")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(readings.prefix(10)) { reading in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(Int(reading.value))")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text("mg/dL")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text(reading.timestamp, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(reading.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        RangeIndicator(range: reading.range)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemBackground))
                    )
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
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Glucose Data")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add glucose readings to the Health app to see them here.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 60)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Error Loading Data")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: retry) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

// MARK: - HealthKit Unavailable View

struct HealthKitUnavailableView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 70))
                .foregroundColor(.secondary)

            Text("HealthKit Not Available")
                .font(.title2)
                .fontWeight(.bold)

            Text("HealthKit is not available on this device. This feature requires an iPhone or iPad with HealthKit support.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HealthKit is available on:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("• iPhone (iOS devices)")
                            .font(.caption)
                        Text("• iPad (iPadOS devices)")
                            .font(.caption)
                    }
                }

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HealthKit is not available on:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("• Mac (macOS devices)")
                            .font(.caption)
                        Text("• Apple Vision Pro (visionOS)")
                            .font(.caption)
                        Text("• Apple Watch standalone")
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GlucoseView()
}
