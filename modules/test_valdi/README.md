# Dates App - Native SwiftUI

Native iOS app built with SwiftUI and Bazel.

## Structure

```
DatesApp/
├── DatesApp.swift          # App entry point
├── Models/
│   └── DatePlan.swift      # Data model
├── Services/
│   └── DateStorageService.swift  # Local storage
└── Views/
    ├── ContentView.swift   # Main screen
    └── DateFormView.swift  # Add/edit form
```

## Build

```bash
# Build the app
bazel build //modules/test_valdi:DatesApp

# Output: bazel-bin/modules/test_valdi/DatesApp.ipa
```

## Test

```bash
# Quick test on iOS Simulator
./test_app.sh

# Manual testing
xcrun simctl boot "iPhone 14 Pro"
open -a Simulator
cd /tmp/dates_app && unzip -q ../../bazel-bin/modules/test_valdi/DatesApp.ipa
xcrun simctl install "iPhone 14 Pro" /tmp/dates_app/Payload/DatesApp.app
xcrun simctl launch "iPhone 14 Pro" com.dates.app
```

## Features

- ✅ SwiftUI native views
- ✅ Local storage via UserDefaults
- ✅ Date plan CRUD operations
- ✅ Status tracking (idea → planned)
- ✅ Vibe categorization
- ✅ Clean architecture (Models/Services/Views)

## Dependencies

- rules_swift (1.18.0)
- rules_apple (3.5.0)
- iOS 15.0+
