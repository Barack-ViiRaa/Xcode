# HealthKit Integration Guide

## Overview

This guide provides comprehensive documentation for the HealthKit integration in the ViiRaa iOS app (Phase 2). HealthKit integration is **critical for App Store approval** under Apple's Guideline 4.2 (Minimum Functionality), as it demonstrates native iOS functionality beyond what a web browser can provide.

---

## Table of Contents

1. [Architecture](#architecture)
2. [Files Added](#files-added)
3. [Configuration](#configuration)
4. [Features Implemented](#features-implemented)
5. [Usage](#usage)
6. [Web Integration](#web-integration)
7. [Testing](#testing)
8. [Troubleshooting](#troubleshooting)

---

## Architecture

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      ViiRaa iOS App                          │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │            MainTabView (Entry Point)                   │  │
│  │  - Shows HealthKit permission prompt on first launch   │  │
│  │  - Checks if HealthKit is authorized                   │  │
│  └────────────────────┬───────────────────────────────────┘  │
│                       │                                       │
│  ┌────────────────────▼───────────────────────────────────┐  │
│  │       HealthKitPermissionView (Native UI)              │  │
│  │  - Explains data types (glucose, weight, activity)     │  │
│  │  - Requests user authorization                         │  │
│  │  - Dismisses on approval or skip                       │  │
│  └────────────────────┬───────────────────────────────────┘  │
│                       │                                       │
│  ┌────────────────────▼───────────────────────────────────┐  │
│  │         HealthKitManager (Singleton Service)           │  │
│  │  - Authorization management                            │  │
│  │  - Fetch glucose data (CGM readings)                   │  │
│  │  - Fetch weight data                                   │  │
│  │  - Fetch activity data (steps, energy, exercise)       │  │
│  │  - Background sync (future)                            │  │
│  └────────────────────┬───────────────────────────────────┘  │
│                       │                                       │
│                       ▼                                       │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              Apple HealthKit Framework                 │  │
│  │  - HKHealthStore for data access                       │  │
│  │  - HKQuantitySample for readings                       │  │
│  │  - HKStatisticsQuery for aggregated data               │  │
│  └────────────────────┬───────────────────────────────────┘  │
└────────────────────────┼───────────────────────────────────────┘
                         │
                         │ JavaScript Injection
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              DashboardWebView (WKWebView)                    │
│  - window.iosHealthData = { glucose, weight, activity }     │
│  - Event: 'ios-health-data-ready'                           │
│  - Web app reads health data from JavaScript global         │
└─────────────────────────────────────────────────────────────┘
```

---

## Files Added

### 1. **Services/HealthKit/HealthKitManager.swift**
   - **Purpose**: Core service for HealthKit operations
   - **Responsibilities**:
     - Request authorization for health data types
     - Fetch latest glucose readings (CGM data)
     - Fetch glucose history with date ranges
     - Fetch latest weight
     - Fetch weight history
     - Fetch activity data (steps, active energy, exercise minutes)
     - Provide convenience method for today's health summary
   - **Key Methods**:
     - `requestAuthorization() async throws`
     - `fetchLatestGlucose() async throws -> HKQuantitySample?`
     - `fetchGlucoseHistory(startDate:endDate:) async throws -> [HKQuantitySample]`
     - `fetchLatestWeight() async throws -> HKQuantitySample?`
     - `fetchWeightHistory(startDate:endDate:) async throws -> [HKQuantitySample]`
     - `fetchStepCount(for:) async throws -> Double`
     - `fetchActiveEnergy(for:) async throws -> Double`
     - `fetchExerciseMinutes(for:) async throws -> Double`
     - `fetchTodayHealthSummary() async throws -> [String: Any]`

### 2. **Services/HealthKit/HealthDataModels.swift**
   - **Purpose**: Data models for health data structures
   - **Models Included**:
     - `GlucoseReading`: Glucose measurement with value, timestamp, range classification
     - `WeightReading`: Weight measurement in pounds and kilograms
     - `ActivitySummary`: Daily activity data (steps, energy, exercise)
     - `HealthSummary`: Combined summary of glucose, weight, and activity
     - `GlucoseStatistics`: Statistics for glucose readings (average, min, max, time in range)
     - `WeightTrend`: Weight trend analysis over time
     - `HealthKitAuthorizationStatus`: Authorization status for data types
   - **Key Features**:
     - Glucose range classification (very low, low, normal, high, very high)
     - Activity goal checking (steps, exercise, calories)
     - JSON serialization for WebView injection
     - Statistical calculations (average, standard deviation, time in range)

### 3. **Features/HealthKit/HealthKitPermissionView.swift**
   - **Purpose**: Native SwiftUI view for requesting HealthKit permissions
   - **Features**:
     - Beautiful, informative UI explaining why permissions are needed
     - Lists all data types being requested (glucose, weight, steps, energy, exercise)
     - Privacy section with security guarantees
     - Link to privacy policy
     - "Allow Access" button that triggers authorization
     - "Maybe Later" button to skip (can be requested again from settings)
     - Error handling with alerts
     - Analytics tracking for permission grants/denials

### 4. **Core/WebView/DashboardWebView.swift** (Updated)
   - **Changes Made**:
     - Added `injectHealthKitData(webView:)` method to inject health data after page load
     - Health data injected as `window.iosHealthData` JavaScript global
     - Dispatches `ios-health-data-ready` custom event for web app
     - Added message handlers:
       - `requestHealthData`: Web can request fresh health data
       - `requestHealthKitAuth`: Web can trigger authorization prompt
     - Analytics tracking for successful health data injection

### 5. **Core/Navigation/MainTabView.swift** (Updated)
   - **Changes Made**:
     - Added `@StateObject private var healthKitManager = HealthKitManager.shared`
     - Added `@State private var showHealthKitPermission = false`
     - Added `@AppStorage("healthKitPermissionShown")` to track if permission was shown
     - Shows `HealthKitPermissionView` sheet on first launch if:
       - HealthKit is enabled in Constants
       - Permission hasn't been shown before
       - HealthKit is available on device
       - User hasn't authorized yet
     - 1-second delay to avoid showing immediately on app launch

---

## Configuration

### 1. **Info.plist** (Already Configured)

The Info.plist already includes the required HealthKit permissions:

```xml
<!-- Privacy - Health Share Usage Description -->
<key>NSHealthShareUsageDescription</key>
<string>ViiRaa needs access to your health data to provide personalized glucose insights and track your wellness progress.</string>

<!-- Privacy - Health Update Usage Description -->
<key>NSHealthUpdateUsageDescription</key>
<string>ViiRaa would like to save health insights to your Health app.</string>

<!-- Background Modes (for background health data sync) -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
</array>

<!-- Required Device Capabilities -->
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>healthkit</string>
</array>
```

### 2. **Xcode Project Capabilities**

**IMPORTANT**: You must manually enable the HealthKit capability in Xcode:

1. Open the project in Xcode: `251015-Xcode.xcodeproj`
2. Select the **251015-Xcode** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability** button
5. Search for and add **HealthKit**
6. Verify that the capability is enabled

This will:
- Add `HealthKit.framework` to the project
- Add the HealthKit entitlement to your app
- Update the `.entitlements` file

### 3. **Constants.swift** (Already Configured)

HealthKit feature flag is already set:

```swift
static let isHealthKitEnabled = true
```

To disable HealthKit (for testing), set to `false`.

---

## Features Implemented

### 1. **Glucose Data (CGM)**

#### Fetch Latest Glucose Reading
```swift
let latestGlucose = try await HealthKitManager.shared.fetchLatestGlucose()
if let glucose = latestGlucose {
    let value = glucose.quantity.doubleValue(for: HKUnit(from: "mg/dL"))
    print("Latest glucose: \(value) mg/dL")
}
```

#### Fetch Glucose History
```swift
let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
let endDate = Date()
let history = try await HealthKitManager.shared.fetchGlucoseHistory(
    startDate: startDate,
    endDate: endDate
)
print("Found \(history.count) glucose readings in the past 7 days")
```

#### Glucose Range Classification
The `GlucoseReading` model automatically classifies glucose values:
- **Very Low**: < 54 mg/dL
- **Low**: 54-69 mg/dL
- **Normal**: 70-180 mg/dL (target range)
- **High**: 181-250 mg/dL
- **Very High**: > 250 mg/dL

### 2. **Weight Data**

#### Fetch Latest Weight
```swift
let latestWeight = try await HealthKitManager.shared.fetchLatestWeight()
if let weight = latestWeight {
    let pounds = weight.quantity.doubleValue(for: .pound())
    print("Latest weight: \(pounds) lbs")
}
```

#### Fetch Weight History
```swift
let weightHistory = try await HealthKitManager.shared.fetchWeightHistory(
    startDate: startDate,
    endDate: endDate
)
```

### 3. **Activity Data**

#### Fetch Today's Steps
```swift
let steps = try await HealthKitManager.shared.fetchStepCount()
print("Steps today: \(steps)")
```

#### Fetch Active Energy
```swift
let energy = try await HealthKitManager.shared.fetchActiveEnergy()
print("Active energy burned: \(energy) kcal")
```

#### Fetch Exercise Minutes
```swift
let exercise = try await HealthKitManager.shared.fetchExerciseMinutes()
print("Exercise minutes: \(exercise)")
```

### 4. **Health Summary**

Fetch all health data at once:

```swift
let summary = try await HealthKitManager.shared.fetchTodayHealthSummary()
// Returns dictionary with:
// - glucose_mg_dl: Latest glucose value
// - glucose_timestamp: Unix timestamp
// - weight_lbs: Latest weight
// - weight_timestamp: Unix timestamp
// - steps: Today's step count
// - active_energy_kcal: Today's active energy
// - exercise_minutes: Today's exercise minutes
```

---

## Usage

### In Native Swift Code

```swift
import SwiftUI

struct HealthDashboardView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var glucoseValue: Double?
    @State private var steps: Double?

    var body: some View {
        VStack {
            if let glucose = glucoseValue {
                Text("Glucose: \(glucose, specifier: "%.1f") mg/dL")
            }

            if let steps = steps {
                Text("Steps: \(Int(steps))")
            }

            Button("Refresh Health Data") {
                Task {
                    await fetchHealthData()
                }
            }
        }
        .onAppear {
            Task {
                await fetchHealthData()
            }
        }
    }

    private func fetchHealthData() async {
        do {
            // Fetch glucose
            if let glucose = try await healthKitManager.fetchLatestGlucose() {
                glucoseValue = glucose.quantity.doubleValue(for: HKUnit(from: "mg/dL"))
            }

            // Fetch steps
            steps = try await healthKitManager.fetchStepCount()
        } catch {
            print("Error fetching health data: \(error)")
        }
    }
}
```

---

## Web Integration

### Receiving Health Data in Web Dashboard

Health data is automatically injected into the web dashboard after the page loads. The data is available via:

#### 1. **Global Variable**
```javascript
// Check if health data is available
if (window.iosHealthData) {
  console.log('Health data available:', window.iosHealthData);

  // Access glucose data
  if (window.iosHealthData.glucose_mg_dl) {
    const glucose = window.iosHealthData.glucose_mg_dl;
    const timestamp = window.iosHealthData.glucose_timestamp;
    console.log(`Latest glucose: ${glucose} mg/dL at ${new Date(timestamp * 1000)}`);
  }

  // Access weight data
  if (window.iosHealthData.weight_lbs) {
    const weight = window.iosHealthData.weight_lbs;
    console.log(`Latest weight: ${weight} lbs`);
  }

  // Access activity data
  const steps = window.iosHealthData.steps || 0;
  const energy = window.iosHealthData.active_energy_kcal || 0;
  const exercise = window.iosHealthData.exercise_minutes || 0;
  console.log(`Today: ${steps} steps, ${energy} kcal, ${exercise} min exercise`);
}
```

#### 2. **Custom Event Listener**
```javascript
window.addEventListener('ios-health-data-ready', (event) => {
  console.log('iOS health data received:', event.detail);

  // Process health data
  const healthData = event.detail;
  updateDashboardWithHealthData(healthData);
});
```

### Requesting Fresh Health Data from Web

The web app can request fresh health data at any time:

```javascript
// Request fresh health data from iOS
window.webkit.messageHandlers.nativeApp.postMessage({
  type: 'requestHealthData'
});

// Listen for the updated data
window.addEventListener('ios-health-data-ready', (event) => {
  console.log('Fresh health data:', event.detail);
});
```

### Triggering HealthKit Authorization from Web

If the user hasn't authorized HealthKit yet, the web app can trigger the permission prompt:

```javascript
// Request HealthKit authorization
window.webkit.messageHandlers.nativeApp.postMessage({
  type: 'requestHealthKitAuth'
});
```

### Health Data Structure

The health data object has the following structure:

```typescript
interface iOSHealthData {
  // Glucose data (if available)
  glucose_mg_dl?: number;          // Latest glucose value in mg/dL
  glucose_timestamp?: number;       // Unix timestamp (seconds)

  // Weight data (if available)
  weight_lbs?: number;              // Latest weight in pounds
  weight_timestamp?: number;        // Unix timestamp (seconds)

  // Activity data (for today)
  steps?: number;                   // Total steps today
  active_energy_kcal?: number;      // Active energy burned in kcal
  exercise_minutes?: number;        // Exercise minutes today
}
```

---

## Testing

### Manual Testing Checklist

#### Phase 1: Authorization
- [ ] Launch app for the first time
- [ ] Verify HealthKit permission view appears after ~1 second delay
- [ ] Tap "Allow Access" button
- [ ] Verify iOS HealthKit permission prompt appears
- [ ] Grant all permissions
- [ ] Verify permission view dismisses automatically
- [ ] Close app and reopen
- [ ] Verify permission view does NOT appear again

#### Phase 2: Data Reading
- [ ] Add test glucose data to Health app (use Health app or simulator)
- [ ] Add test weight data to Health app
- [ ] Add test activity data (steps, exercise) to Health app
- [ ] Open ViiRaa app dashboard
- [ ] Check browser console for logs:
   - "✅ iOS HealthKit data injected successfully"
   - Verify `window.iosHealthData` contains expected data
- [ ] Verify data appears in dashboard UI (if implemented)

#### Phase 3: Web Integration
- [ ] Open browser console in WebView
- [ ] Type `window.iosHealthData` and verify data is present
- [ ] Verify `ios-health-data-ready` event fires on page load
- [ ] Test requesting fresh data via message handler
- [ ] Verify data updates after request

### Unit Testing

Run the HealthKit Manager tests:

```bash
# In Xcode, press Cmd+U to run all tests
# Or run specific test:
xcodebuild test -scheme ViiRaaApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Simulator Testing

**Note**: HealthKit is available in the iOS Simulator, but data may be limited. Use the Health app in the simulator to add test data.

#### Adding Test Data in Simulator:
1. Open **Health** app in simulator
2. Go to **Browse** tab
3. Search for "Blood Glucose", "Body Mass", or "Steps"
4. Tap **Add Data** to manually enter test values
5. Save and return to ViiRaa app

---

## Troubleshooting

### Issue: "HealthKit is not available on this device"

**Cause**: Running on a device/simulator that doesn't support HealthKit.

**Solution**:
- Ensure you're using iOS 14.0+ simulator or device
- Check `HKHealthStore.isHealthDataAvailable()` returns `true`
- iPads may have limited HealthKit support

### Issue: Authorization prompt never appears

**Cause**: HealthKit capability not enabled in Xcode project.

**Solution**:
1. Open Xcode project
2. Select target → Signing & Capabilities
3. Add HealthKit capability
4. Clean build folder (Cmd+Shift+K)
5. Rebuild and run

### Issue: "Cannot find type 'HKHealthStore'"

**Cause**: HealthKit framework not imported.

**Solution**:
- Add `import HealthKit` to the file
- Ensure HealthKit capability is enabled

### Issue: Health data not appearing in web dashboard

**Cause**: Multiple possible reasons.

**Solutions**:
1. Check browser console for errors
2. Verify `window.iosHealthData` is defined
3. Ensure HealthKit authorization was granted
4. Add test data to Health app
5. Check Constants.isHealthKitEnabled is `true`
6. Verify HealthKitManager.shared.isAuthorized is `true`

### Issue: Authorization status always returns "notDetermined"

**Cause**: User hasn't been prompted or denied permission.

**Solution**:
- Delete app and reinstall to reset permissions
- Or go to Settings → Privacy → Health → ViiRaa and adjust permissions

### Issue: Readings are empty or nil

**Cause**: No health data exists in Health app.

**Solution**:
- Add test data manually in Health app
- Or use a CGM device/app that writes to HealthKit
- For simulator, manually add data via Health app

---

## Next Steps

### Future Enhancements

1. **Background Sync**
   - Implement background fetch to sync health data periodically
   - Use `UIBackgroundModes` already configured in Info.plist

2. **Health Data Writing**
   - Allow app to write health insights back to HealthKit
   - Requires updating authorization request to include write permissions

3. **Notifications**
   - Alert user when glucose is out of range
   - Require implementing push notifications (APNs)

4. **Charts and Visualizations**
   - Native SwiftUI charts for glucose trends
   - Weight tracking graphs
   - Activity ring visualizations

5. **Apple Watch Integration**
   - Sync health data from Apple Watch
   - Display real-time glucose on watch face

---

## App Store Submission Notes

### Addressing Guideline 4.2 (Minimum Functionality)

When submitting to App Store, include this in **App Review Notes**:

```
HealthKit Integration:

ViiRaa demonstrates significant native iOS functionality through comprehensive
HealthKit integration:

1. Glucose Monitoring (CGM):
   - Reads continuous glucose monitor data from Apple HealthKit
   - Provides personalized insights based on glucose patterns
   - Classifies readings (normal, low, high, very high)

2. Weight Tracking:
   - Tracks body mass measurements over time
   - Analyzes weight trends and progress

3. Activity Monitoring:
   - Reads daily step count
   - Tracks active energy burned
   - Monitors exercise minutes

The app combines native iOS health data access with web-based content delivery,
providing genuine value to iOS users that cannot be achieved through a web
browser alone.

Demo Account:
Email: dev@viiraa.com
Password: [Provided separately]

Please grant HealthKit permissions when prompted to fully test the health
data integration features.
```

### Privacy Policy Requirements

Ensure your privacy policy at https://www.viiraa.com/ViiRaa_Privacy_Policy_Notice_US_20250808.pdf includes:

- Types of health data collected (glucose, weight, activity)
- How health data is used (personalized insights, tracking)
- That health data is never sold to third parties
- How users can revoke access (Settings → Privacy → Health)
- Data retention policies

---

## Support

For questions or issues with HealthKit integration:

1. Check the [Apple HealthKit Documentation](https://developer.apple.com/documentation/healthkit)
2. Review [App Store Review Guidelines 4.2](https://developer.apple.com/app-store/review/guidelines/#minimum-functionality)
3. Contact the development team

---

**Version**: 1.0
**Last Updated**: 2025-10-21
**Author**: Claude Code
**Status**: Phase 2 Complete
