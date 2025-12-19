# Xcode Build Configuration Setup Guide

This guide will help you complete the environment configuration setup in Xcode.

## Prerequisites Completed ✅

1. **xcconfig files created:**
   - `Debug.xcconfig` (uses localhost:3000)
   - `Staging.xcconfig` (uses https://nippardation-staging.herokuapp.com)
   - `Production.xcconfig` (uses https://nippardation-prod.herokuapp.com)
   
2. **Environment switching code implemented:**
   - `AppConfiguration.swift` properly reads environment
   - `NetworkManager.swift` uses the correct API URL
   - `WorkoutSyncService.swift` syncs workouts to backend

3. **Firebase configuration files in place:**
   - `GoogleService-Info-Staging.plist`
   - `GoogleService-Info-Prod.plist`

## Required Xcode Setup Steps

### 1. Add Configuration Files to Xcode Project

1. Open `Nippardation.xcodeproj` in Xcode
2. Right-click on the `Nippardation` folder in the project navigator
3. Select "Add Files to Nippardation..."
4. Navigate to the `Configuration` folder and add these files (if not already added):
   - `Debug.xcconfig`
   - `Staging.xcconfig`
   - `Production.xcconfig`
   - `Shared.xcconfig`
5. Make sure "Copy items if needed" is UNCHECKED
6. Make sure your target is selected

### 2. Create Build Configurations

1. Select the project (blue icon) in the navigator
2. Select the project name under PROJECT (not under TARGETS)
3. Go to the "Info" tab
4. Under "Configurations", you'll see Debug and Release
5. Click the "+" button and select "Duplicate 'Debug' Configuration"
6. Name it "Staging"
7. Click "+" again and select "Duplicate 'Release' Configuration"
8. Name it "Production"

### 3. Assign Configuration Files

For each configuration row:
1. Click the arrow next to the configuration name to expand it
2. For the project row (not target), click "None" and select:
   - **Debug** → `Debug.xcconfig`
   - **Release** → `Production.xcconfig`
   - **Staging** → `Staging.xcconfig`
   - **Production** → `Production.xcconfig`

### 4. Update Build Settings

1. Select your app target (under TARGETS)
2. Go to "Build Settings" tab
3. Click "All" and "Combined"
4. Search for "Other Swift Flags"
5. Click the arrow to expand it
6. For each configuration, ensure these flags are set:
   - **Debug**: `-D DEBUG -D PRODUCTION`
   - **Release**: `-D PRODUCTION`
   - **Staging**: `-D STAGING`
   - **Production**: `-D PRODUCTION`

### 5. Add Firebase Config Copy Script

1. Select your app target
2. Go to "Build Phases" tab
3. Click "+" and select "New Run Script Phase"
4. Drag it to run AFTER "Copy Bundle Resources"
5. Rename it to "Copy Firebase Config"
6. Add this script:
   ```bash
   "${PROJECT_DIR}/Scripts/copy-firebase-config.sh"
   ```
7. Make sure "Based on dependency analysis" is UNCHECKED

### 6. Create Schemes

1. Click on the scheme selector (next to the run/stop buttons)
2. Select "Manage Schemes..."
3. Select your current scheme and click the gear icon → "Duplicate"
4. Name it "Nippardation Staging"
5. Edit the new scheme:
   - **Run** → Info → Build Configuration → **Staging**
   - **Test** → Info → Build Configuration → **Staging**
   - **Profile** → Info → Build Configuration → **Staging**
   - **Analyze** → Info → Build Configuration → **Staging**
   - **Archive** → Build Configuration → **Staging**
6. Click "Close"

### 7. Update Backend URLs (if needed)

The URLs are currently set to:
- **Debug**: http://localhost:3000
- **Staging**: https://nippardation-staging.herokuapp.com
- **Production**: https://nippardation-prod.herokuapp.com

To update these:
1. Edit the respective `.xcconfig` files
2. Change the `API_BASE_URL` value

### 8. Test Environment Switching

1. Select "Nippardation" scheme → Build and run
2. Check console output for: "Firebase configured with production environment"
3. Select "Nippardation Staging" scheme → Build and run
4. Check console output for: "Firebase configured with staging environment"

### 9. Verify Workout Sync

1. Complete a workout in the app
2. Check console for sync messages:
   - Success: "✅ Workout synced to backend successfully"
   - Failure: "❌ Failed to sync workout: [error]"

## Troubleshooting

### If environment isn't switching:
1. Clean build folder (Cmd+Shift+K)
2. Delete derived data
3. Verify the scheme is using the correct build configuration

### If Firebase crashes on startup:
1. Verify GoogleService-Info files are in the correct location
2. Check that the copy script is running (look for echo statements in build log)

### If workout sync fails:
1. Verify the backend is running (for localhost)
2. Check that you're logged in (Firebase Auth token is required)
3. Verify the API URLs in the xcconfig files

## Backend Requirements

For the sync to work, ensure your backend is:
1. Running on the configured URL
2. Has the `/api/sync` endpoint implemented
3. Is configured with the same Firebase project for authentication

## Next Steps

After completing this setup:
1. The app will automatically use the correct environment based on the selected scheme
2. Workouts will sync to the backend when completed
3. You can switch between environments by changing schemes

Remember to use:
- **Debug** scheme for local development
- **Staging** scheme for testing
- **Production** scheme for releases