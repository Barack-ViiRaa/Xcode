# HealthKit Quick Start Guide

**5-Minute Setup Guide for ViiRaa iOS HealthKit Integration**

---

## 🚀 Quick Setup (3 Steps)

### Step 1: Enable HealthKit in Xcode (REQUIRED)

1. Open `251015-Xcode.xcodeproj` in Xcode
2. Select target → **Signing & Capabilities** tab
3. Click **+ Capability** → Add **HealthKit**
4. Done! ✅

### Step 2: Build and Run

```bash
# In Xcode:
Cmd+Shift+K  # Clean
Cmd+R        # Run
```

### Step 3: Test Permission Flow

1. App launches → Wait 1 second → Permission sheet appears
2. Tap "Allow Access" → iOS HealthKit prompt → Grant permissions
3. Done! HealthKit is now active ✅

---

## 📱 Adding Test Data

### In iOS Simulator:

1. Open **Health** app
2. Go to **Browse** tab
3. Search for:
   - "Blood Glucose" → Add Data → 120 mg/dL
   - "Body Mass" → Add Data → 150 lbs
   - "Steps" → Add Data → 5000 steps
4. Return to ViiRaa app

### Verify Data Injection:

1. Open Web Inspector (Safari → Develop → Simulator)
2. In console, type: `window.iosHealthData`
3. You should see:
```javascript
{
  glucose_mg_dl: 120,
  glucose_timestamp: 1729555200,
  weight_lbs: 150,
  weight_timestamp: 1729555200,
  steps: 5000,
  active_energy_kcal: 0,
  exercise_minutes: 0
}
```

---

## 💻 Using in Swift

### Fetch Health Data:

```swift
import SwiftUI

struct MyHealthView: View {
    @StateObject private var healthKit = HealthKitManager.shared
    @State private var glucose: Double?

    var body: some View {
        VStack {
            if let glucose = glucose {
                Text("Glucose: \(glucose, specifier: "%.1f") mg/dL")
            } else {
                Text("No data")
            }
        }
        .task {
            do {
                if let sample = try await healthKit.fetchLatestGlucose() {
                    glucose = sample.quantity.doubleValue(for: HKUnit(from: "mg/dL"))
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
}
```

---

## 🌐 Using in Web Dashboard

### Listen for Health Data:

```javascript
window.addEventListener('ios-health-data-ready', (event) => {
  const health = event.detail;
  console.log('Health data received:', health);

  // Update UI
  document.getElementById('glucose').textContent =
    `${health.glucose_mg_dl} mg/dL`;
});
```

### Request Fresh Data:

```javascript
function refreshHealth() {
  window.webkit.messageHandlers.nativeApp.postMessage({
    type: 'requestHealthData'
  });
}
```

---

## 📋 Quick Checklist

### Before Testing:
- [ ] HealthKit capability enabled in Xcode
- [ ] App builds without errors
- [ ] Running on iOS 14+ simulator or device

### During Testing:
- [ ] Permission prompt appears on first launch
- [ ] Can grant HealthKit permissions
- [ ] Test data added to Health app
- [ ] Console logs show "✅ iOS HealthKit data injected successfully"
- [ ] `window.iosHealthData` is defined in web inspector

### Before App Store:
- [ ] Tested on physical device
- [ ] Privacy policy updated
- [ ] App Review Notes prepared (see [`HEALTHKIT_INTEGRATION_GUIDE.md`](HEALTHKIT_INTEGRATION_GUIDE.md))
- [ ] Screenshots showing HealthKit features

---

## 🐛 Troubleshooting

### Build Error: "Cannot find type 'HKHealthStore'"
**Fix**: Enable HealthKit capability (Step 1 above)

### Permission prompt never appears
**Fix**:
1. Check `Constants.isHealthKitEnabled == true`
2. Delete app and reinstall
3. Check `@AppStorage("healthKitPermissionShown")` in UserDefaults

### No data in `window.iosHealthData`
**Fix**:
1. Check if permissions were granted (Settings → Privacy → Health → ViiRaa)
2. Add test data in Health app
3. Check console for errors

### Data is always empty/null
**Fix**: Add test data manually in Health app (see "Adding Test Data" above)

---

## 📚 Full Documentation

For complete documentation, see:

- [`HEALTHKIT_INTEGRATION_GUIDE.md`](HEALTHKIT_INTEGRATION_GUIDE.md) - Complete integration guide (500+ lines)
- [`HEALTHKIT_IMPLEMENTATION_SUMMARY.md`](HEALTHKIT_IMPLEMENTATION_SUMMARY.md) - Implementation details
- [`Software_Development_Document.md`](Software_Development_Document.md) - Original specifications

---

## 🎯 Key Files

| File | Purpose |
|------|---------|
| [`Services/HealthKit/HealthKitManager.swift`](251015-Xcode/Services/HealthKit/HealthKitManager.swift) | Core HealthKit service (480 lines) |
| [`Services/HealthKit/HealthDataModels.swift`](251015-Xcode/Services/HealthKit/HealthDataModels.swift) | Data models (350 lines) |
| [`Features/HealthKit/HealthKitPermissionView.swift`](251015-Xcode/Features/HealthKit/HealthKitPermissionView.swift) | Permission UI (250 lines) |
| [`Core/WebView/DashboardWebView.swift`](251015-Xcode/Core/WebView/DashboardWebView.swift) | WebView integration (updated) |
| [`Resources/251015-Xcode.entitlements`](251015-Xcode/Resources/251015-Xcode.entitlements) | HealthKit entitlements |

---

## ✅ That's It!

You're ready to test HealthKit integration. If you run into issues, check the troubleshooting section above or see the full integration guide.

**Questions?** See [`HEALTHKIT_INTEGRATION_GUIDE.md`](HEALTHKIT_INTEGRATION_GUIDE.md)

---

**Version**: 1.0
**Last Updated**: October 21, 2025
