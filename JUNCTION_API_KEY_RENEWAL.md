# Junction API Key Renewal Guide

## Problem

The current Junction API key in `Constants.swift` is **expired**. According to [Credentials.md](Credentials.md), the key was created on November 27th, 2025 with only 1 week shelf life, and it's now December 2nd.

Error in logs:
```
❌ Junction API error (401): {"detail":"invalid token"}
⚠️ Failed to connect to Junction: Network error. Please check your connection and try again.
```

## Solution: Get a New API Key

### Step 1: Log in to Junction Dashboard

1. Go to https://app.junction.com/
2. Sign in with Google SSO using `barack.liu@viiraa.com`
3. Navigate to your team settings

### Step 2: Create a New API Key

1. In the Junction dashboard, go to **Settings** → **API Keys**
2. Click **"Create New API Key"**
3. Select environment:
   - **Sandbox** (for testing) - creates keys with prefix `sk_us_*`
   - **Production** (for live app) - creates keys with prefix `pk_us_*`
4. Copy the new API key immediately (it won't be shown again)

### Step 3: Update Constants.swift

Replace the expired key in [Xcode/Utilities/Constants.swift](Xcode/Utilities/Constants.swift):

```swift
// OLD (expired)
static let junctionAPIKey = "k_us_ppzw0ZYK-NeiBAF3qSNA5Fddg45-40bnDWFXAaKvZOM"

// NEW (example - replace with your actual key)
static let junctionAPIKey = "sk_us_YOUR_NEW_API_KEY_HERE"
```

### Step 4: Update Credentials.md

Update [Credentials.md](Credentials.md) with:
- New API key
- Date created
- Expiration date (if applicable)

### Step 5: Rebuild and Test

```bash
# Clean build
xcodebuild clean -project Xcode.xcodeproj -scheme Xcode

# Rebuild
xcodebuild -project Xcode.xcodeproj -scheme Xcode build
```

## API Key Format Reference

Junction API keys have specific prefixes:

| Environment | Region | Prefix | Example |
|------------|--------|--------|---------|
| Sandbox | US | `sk_us_*` | `sk_us_abc123...` |
| Production | US | `pk_us_*` | `pk_us_xyz789...` |
| Sandbox | EU | `sk_eu_*` | `sk_eu_def456...` |
| Production | EU | `pk_eu_*` | `pk_eu_uvw012...` |

**Note:** The old prefix `k_us_*` is non-standard and may have been a temporary/test format.

## What Was Fixed in the Code

The following changes were made to [Xcode/Services/Junction/JunctionManager.swift](Xcode/Services/Junction/JunctionManager.swift):

### 1. Updated API Base URL

**Before:**
```swift
let baseURL = "https://api.sandbox.tryvital.io"
```

**After:**
```swift
let baseURL = "https://api.us.junction.com"  // Correct modern endpoint
```

### 2. Fixed API Endpoint

**Before:**
```swift
let url = URL(string: "\(baseURL)/v2/user")  // Wrong: singular
```

**After:**
```swift
let url = URL(string: "\(baseURL)/v2/users")  // Correct: plural
```

### 3. Fixed Header Capitalization

**Before:**
```swift
request.setValue(apiKey, forHTTPHeaderField: "x-vital-api-key")
```

**After:**
```swift
request.setValue(apiKey, forHTTPHeaderField: "X-Vital-API-Key")  // Capital X
```

### 4. Added 401 Error Detection

```swift
else if httpResponse.statusCode == 401 {
    print("⚠️ API Key may be expired or invalid. Please check:")
    print("   1. Get a new API key from https://app.junction.com/")
    print("   2. Update Constants.junctionAPIKey with the new key")
    print("   3. Expected format: sk_us_* (Sandbox US) or pk_us_* (Production US)")
    throw JunctionError.invalidAPIKey
}
```

## Testing After Key Renewal

Once you have a new API key:

1. **Update Constants.swift** with the new key
2. **Rebuild the app**
3. **Sign in** to the app
4. **Check logs** for:
   ```
   📝 Creating user in Junction backend...
   ✅ User created in Junction: [uuid]
   👤 User connected to Junction: [uuid]
   ```
5. **Verify in Junction Dashboard**:
   - Go to https://app.junction.com/team/[team-id]/sandbox/users
   - You should now see the user listed

## Preventing Future Expiration

**Recommendation:** Use API keys without expiration for development environments, or set up a reminder to renew keys before they expire.

To set up monitoring:
1. Add expiration date to [Credentials.md](Credentials.md)
2. Create a calendar reminder 2-3 days before expiration
3. Consider using environment variables for production deployments

## Additional Resources

- [Junction Authentication Documentation](https://docs.junction.com/api-details)
- [How to Authenticate with Vital's API](https://tryvital.medium.com/how-to-authenticate-with-vitals-api-10a015505edc)
- [Junction Quickstart Guide](https://docs.junction.com/home/quickstart)
