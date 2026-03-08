# Environment Configuration

## How It Works

The app environment (staging vs production) is determined **at compile time** via Swift compiler flags. This makes it physically impossible to ship staging URLs in a production binary.

### Build Configuration Matrix

| Config     | Compiler Flags    | URL        | Used By                          |
|------------|-------------------|------------|----------------------------------|
| Debug      | `DEBUG STAGING`   | staging    | Staging scheme Run               |
| Staging    | `DEBUG STAGING`   | staging    | Staging scheme Archive           |
| Release    | `PRODUCTION`      | production | Nippardation scheme Run/Archive  |
| Production | `PRODUCTION`      | production | Production scheme Run/Archive    |

### Switching Environments

Select the appropriate Xcode scheme:
- **Staging** scheme: Run and Archive both hit **staging**
- **Production** scheme: Run and Archive both hit **production**
- **Nippardation** scheme: Run and Archive both hit **production** (Release config)

### Accessing Configuration in Code

```swift
// Get current environment
let environment = AppConfiguration.shared.environment

// Get backend URL (compile-time constant based on build config)
let baseURL = AppConfiguration.shared.baseURL

// Check environment
if AppConfiguration.shared.environment == .staging {
    // Staging-specific code
}
```

### Staging Banner

In staging builds (`#if STAGING`), an orange "STAGING" capsule appears at the top of the screen so developers always know which environment is active. This is compiled out entirely in production builds.

### Firebase Authentication

The app automatically loads the correct GoogleService-Info.plist based on the environment.

## Important Notes

1. **Do NOT** add `GoogleService-Info.plist` (without suffix) to the project — it will be copied automatically
2. Keep your Firebase configuration files secure and don't commit sensitive data
3. URLs are defined in `AppConfiguration.swift` and selected via `#if STAGING` / `#else` compiler directives
4. Compiler flags are set in the project-level build configs in `project.pbxproj` — not in xcconfig files
5. Make sure to configure matching apps in Firebase Console for both bundle IDs
