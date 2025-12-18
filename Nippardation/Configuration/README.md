# Environment Configuration Setup

This guide explains how to set up the build configurations in Xcode for staging and production environments.

## Initial Setup (First Time Only)

### 1. Generate Configuration Files from Templates

Run the setup script to create your local xcconfig files:

```bash
cd /path/to/Nippardation
./Scripts/setup-config.sh
```

This will create the following files from templates:
- `Staging.xcconfig`
- `Production.xcconfig`
- `Debug.xcconfig`

### 2. Configure Your Environment Values

Edit each generated xcconfig file and replace the placeholders:

1. **Staging.xcconfig**:
   - `YOUR_BUNDLE_ID_HERE.staging` → Your staging bundle ID
   - `YOUR_STAGING_API_URL_HERE` → Your staging API URL
   - `YOUR_TEAM_ID_HERE` → Your Apple Developer Team ID

2. **Production.xcconfig**:
   - `YOUR_BUNDLE_ID_HERE` → Your production bundle ID
   - `YOUR_PRODUCTION_API_URL_HERE` → Your production API URL
   - `YOUR_TEAM_ID_HERE` → Your Apple Developer Team ID

### 3. Add Configuration Files to Xcode

1. Open `Nippardation.xcodeproj` in Xcode
2. Right-click on the Nippardation folder in the project navigator
3. Select "Add Files to Nippardation..."
4. Navigate to the `Configuration` folder and add:
   - `AppConfiguration.swift`
   - `Staging.xcconfig` (⚠️ NOT the .template file)
   - `Production.xcconfig` (⚠️ NOT the .template file)
   - `Debug.xcconfig` (⚠️ NOT the .template file)
   - `Shared.xcconfig`
   - `GoogleService-Info-Staging.plist`
   - `GoogleService-Info-Prod.plist`
5. Add the `Info.plist` file from the Nippardation folder

### 2. Create Build Configurations

1. Select the project (blue icon) in the navigator
2. Select the project name under PROJECT (not TARGETS)
3. Go to the "Info" tab
4. Under "Configurations", you'll see Debug and Release
5. Click the "+" button and select "Duplicate 'Debug' Configuration"
6. Name it "Staging"
7. Click "+" again and select "Duplicate 'Release' Configuration"  
8. Name it "Production"

### 3. Assign Configuration Files

For each configuration (Debug, Staging, Production, Release):
1. Click the arrow next to the configuration name to expand
2. For the project row, click the dropdown and select:
   - Debug → Production.xcconfig
   - Release → Production.xcconfig
   - Staging → Staging.xcconfig
   - Production → Production.xcconfig

### 4. Add Build Phase Script

1. Select your app target
2. Go to "Build Phases" tab
3. Click "+" and select "New Run Script Phase"
4. Drag it to run after "Copy Bundle Resources"
5. Name it "Copy Firebase Config"
6. Add this script:
```bash
"${PROJECT_DIR}/Scripts/copy-firebase-config.sh"
```

### 5. Update Build Settings

1. Select your app target
2. Go to "Build Settings" tab
3. Search for "Other Swift Flags"
4. Add these flags:
   - Debug: `-D DEBUG`
   - Staging: `-D STAGING`
   - Production: `-D PRODUCTION`
   - Release: `-D PRODUCTION`

### 6. Create Schemes

1. Click on the scheme selector (next to the run/stop buttons)
2. Select "Manage Schemes..."
3. Select your current scheme and click "Duplicate"
4. Name it "Nippardation Staging"
5. Edit the new scheme:
   - Run → Info → Build Configuration → Staging
   - Test → Info → Build Configuration → Staging
   - Archive → Build Configuration → Staging

### 7. Update Bundle Identifiers and Team ID

1. Open `Staging.xcconfig` and `Production.xcconfig`
2. Replace `com.yourcompany.nippardation` with your actual bundle ID
3. Replace `YOUR_TEAM_ID` with your Apple Developer Team ID

### 8. Configure Info.plist in Build Settings

1. Select your app target
2. Go to "Build Settings" tab
3. Search for "Info.plist File"
4. Set the value to `Nippardation/Info.plist`

### 9. Verify Environment Variables

The backend URLs are now configured in the xcconfig files.

These URLs are injected at build time through the environment variable.

## Usage

### Switching Environments

To switch between environments:
1. Select the appropriate scheme in Xcode (top bar)
2. Build and run

### Accessing Configuration in Code

```swift
// Get current environment
let environment = AppConfiguration.shared.environment

// Get backend URL (automatically uses the correct URL based on build configuration)
let baseURL = AppConfiguration.shared.baseURL

// Alternative: Direct access to the API URL from Info.plist
if let apiURL = Bundle.main.infoDictionary?["API_BASE_URL"] as? String {
    print("API URL: \(apiURL)")
}

// Check environment
if AppConfiguration.shared.environment == .staging {
    // Staging-specific code
}
```

### Firebase Authentication

The app automatically loads the correct GoogleService-Info.plist based on the selected environment.

```swift
// Get Firebase auth token for backend requests
let token = try await AuthManager.shared.getIDToken()

// Example API call
let workouts = try await NetworkManager.shared.fetchWorkoutHistory()
```

## Important Notes

1. **Do NOT** add `GoogleService-Info.plist` (without suffix) to the project - it will be copied automatically
2. Keep your Firebase configuration files secure and don't commit sensitive data
3. The backend URLs in `AppConfiguration.swift` need to be updated with your actual endpoints
4. Make sure to configure matching apps in Firebase Console for both bundle IDs
