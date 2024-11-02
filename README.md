# XCBuildKit

XCBuildKit is a powerful Swift package that provides a clean, type-safe wrapper around Xcode build commands. It enables you to programmatically manage Xcode builds with a modern Swift API.

[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 🛠 Type-safe wrapper around `xcodebuild` commands
- 🔍 Comprehensive build configuration validation
- 🚀 Async/await support for build operations

## Installation

Add XCBuildKit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/engali94/XCBuildKit.git", from: "0.0.1")
]
```

## Quick Start

```swift
import XCBuildKit

// Initialize the build system
let xcodeBuild = XcodeBuild()

// Configure build options using the convenience factory method
let options = XcodeBuildOptions.forBuild(
    project: "MyApp",
    scheme: "MyApp",
    configuration: "Release",
    sdk: .iPhoneOS,
    destination: .iOSSimulator(device: "iPhone 14")
)

// Execute the build and handle real-time output
for await state in xcodeBuild.execute(.build, options: options) {
    switch state {
    case .inProgress(let message):
        print("Building: \(message)")
    case .completed:
        print("Build completed successfully!")
    case .error(let message):
        print("Build failed: \(message)")
    }
}
```

## Advanced Usage

### Running Tests

```swift
// Configure test options
let testOptions = XcodeBuildOptions.forTesting(
    project: "MyApp",
    scheme: "MyApp",
    destination: .iOSSimulator(device: "iPhone 14"),
    testPlan: "MyTestPlan",
    testConfiguration: nil,
    testLanguage: nil,
    testRegion: nil,
    skipTesting: [],
    onlyTesting: ["MyAppTests/LoginTests"],
    testTargets: [],
    enableCodeCoverage: true
)

// Execute tests with real-time feedback
for await state in xcodeBuild.execute(.test(testPlan: "MyTestPlan"), options: testOptions) {
    switch state {
    case .inProgress(let message):
        print("Testing: \(message)")
    case .completed:
        print("Tests completed successfully!")
    case .error(let message):
        print("Tests failed: \(message)")
    }
}
```

### Creating Archives

```swift
// Configure archive options
let archivePath = try ArchivePath("path/to/output.xcarchive")
let archiveOptions = XcodeBuildOptions.forArchive(
    project: "MyApp",
    scheme: "MyApp",
    configuration: "Release",
    archivePath: archivePath,
    allowProvisioningUpdates: true
)

// Create archive
for await state in xcodeBuild.execute(.archive, options: archiveOptions) {
    switch state {
    case .inProgress(let message):
        print("Archiving: \(message)")
    case .completed:
        print("Archive created successfully!")
    case .error(let message):
        print("Archive failed: \(message)")
    }
}
```

### Exporting Archives

```swift
let exportOptions = try ExportOptions(
    archivePath: "path/to/archive.xcarchive",
    exportPath: "path/to/export",
    optionsPlist: "path/to/options.plist"
)

let options = XcodeBuildOptions.forExport(
    project: "MyApp",
    scheme: "MyApp",
    exportOptions: exportOptions,
    allowProvisioningUpdates: true
)

for await state in xcodeBuild.execute(.exportArchive, options: options) {
    switch state {
    case .inProgress(let message):
        print("Exporting: \(message)")
    case .completed:
        print("Export completed successfully!")
    case .error(let message):
        print("Export failed: \(message)")
    }
}
```

## Error Handling

XCBuildKit provides detailed error information through the `BuildState` enum:

```swift
for await state in xcodeBuild.execute(.build, options: options) {
    switch state {
    case .error(let message):
        if message.contains("No provisioning profile") {
            // Handle provisioning profile errors
        } else if message.contains("Code signing") {
            // Handle code signing errors
        } else {
            // Handle other build errors
        }
    default:
        break
    }
}
```

## Requirements

- Xcode 13.0+
- Swift 5.5+
- macOS 11.0+

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
