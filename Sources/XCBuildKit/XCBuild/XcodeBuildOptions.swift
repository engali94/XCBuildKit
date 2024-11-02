//
//  XcodeBuildOptions.swift
//  XCBuildKit
//
//  Created by Ali Hilal on 02/11/2024.
//

import Foundation

/// Represents build destinations for Xcode projects.
///
/// This enum provides type-safe configuration for different build destinations,
/// including simulators and physical devices for various Apple platforms.
///
/// ## Example Usage
/// ```swift
/// let iPhoneDestination = Destination.iOSSimulator(device: "iPhone 14")
/// let macDestination = Destination.macOS
/// ```
public enum Destination: Sendable {
    /// iOS Simulator destination with optional device name.
    case iOSSimulator(device: String? = nil)
    /// Physical iOS device destination with optional device name.
    case iOSDevice(device: String? = nil)
    /// macOS destination.
    case macOS
    /// Mac Catalyst destination.
    case macCatalyst
    /// tvOS Simulator destination with optional device name.
    case tvOSSimulator(device: String? = nil)
    /// Physical tvOS device destination with optional device name.
    case tvOSDevice(device: String? = nil)
    /// watchOS Simulator destination with optional device name.
    case watchOSSimulator(device: String? = nil)
    /// Physical watchOS device destination with optional device name.
    case watchOSDevice(device: String? = nil)

    /// The xcodebuild-compatible string representation of the destination.
    var value: String {
        switch self {
        case .iOSSimulator(let device):
            let base = "platform=iOS Simulator"
            return device.map { "\(base),name=\($0)" } ?? base

        case .iOSDevice(let device):
            let base = "platform=iOS"
            return device.map { "\(base),name=\($0)" } ?? base

        case .macOS:
            return "platform=macOS"

        case .macCatalyst:
            return "platform=macOS,variant=Mac Catalyst"

        case .tvOSSimulator(let device):
            let base = "platform=tvOS Simulator"
            return device.map { "\(base),name=\($0)" } ?? base

        case .tvOSDevice(let device):
            let base = "platform=tvOS"
            return device.map { "\(base),name=\($0)" } ?? base

        case .watchOSSimulator(let device):
            let base = "platform=watchOS Simulator"
            return device.map { "\(base),name=\($0)" } ?? base

        case .watchOSDevice(let device):
            let base = "platform=watchOS"
            return device.map { "\(base),name=\($0)" } ?? base
        }
    }
}

/// Represents available SDKs for Xcode builds.
///
/// This enum provides type-safe configuration for different Apple platform SDKs.
public enum SDK: String, Sendable {
    /// iOS device SDK
    case iPhoneOS = "iphoneos"
    /// iOS simulator SDK
    case iPhoneSimulator = "iphonesimulator"
    /// macOS SDK
    case macOS = "macosx"
    /// Mac Catalyst SDK
    case macCatalyst = "maccatalyst"
    /// tvOS device SDK
    case tvOS = "appletvos"
    /// tvOS simulator SDK
    case tvSimulator = "appletvsimulator"
    /// watchOS device SDK
    case watchOS = "watchos"
    /// watchOS simulator SDK
    case watchSimulator = "watchsimulator"

    /// The xcodebuild-compatible string representation of the SDK.
    var value: String { rawValue }
}

/// Represents a path to an Xcode archive.
///
/// This struct validates that the archive path is not empty.
public struct ArchivePath: Sendable {
    /// The validated archive path.
    let path: String

    /// Creates a new archive path.
    ///
    /// - Parameter path: The path to the archive.
    /// - Throws: ``AnyError`` if the path is empty.
    public init(_ path: String) throws {
        guard !path.isEmpty else {
            throw AnyError("Archive path cannot be empty")
        }
        self.path = path
    }
}

/// Configuration options for exporting an Xcode archive.
///
/// This struct encapsulates all required parameters for exporting an archived app.
public struct ExportOptions: Sendable {
    /// The path to the archive to export.
    let archivePath: String
    /// The directory where the exported artifacts will be placed.
    let exportPath: String
    /// The path to the export options plist file.
    let optionsPlist: String

    /// Creates new export options.
    ///
    /// - Parameters:
    ///   - archivePath: The path to the archive to export.
    ///   - exportPath: The directory where exported artifacts will be placed.
    ///   - optionsPlist: The path to the export options plist file.
    /// - Throws: ``AnyError`` if any parameter is empty.
    public init(archivePath: String, exportPath: String, optionsPlist: String) throws {
        guard !archivePath.isEmpty else {
            throw AnyError("Archive path cannot be empty")
        }
        guard !exportPath.isEmpty else {
            throw AnyError("Export path cannot be empty")
        }
        guard !optionsPlist.isEmpty else {
            throw AnyError("Export options plist cannot be empty")
        }

        self.archivePath = archivePath
        self.exportPath = exportPath
        self.optionsPlist = optionsPlist
    }
}

/// Configuration options for Xcode build operations.
///
/// This struct provides a comprehensive set of options for configuring various
/// Xcode build operations, including building, testing, archiving, and exporting.
///
/// ## Example Usage
/// ```swift
/// // Configure options for building
/// let buildOptions = XcodeBuildOptions.forBuild(
///     project: "MyApp",
///     scheme: "MyApp",
///     configuration: "Release",
///     sdk: .iPhoneOS,
///     destination: .iOSDevice()
/// )
///
/// // Configure options for testing
/// let testOptions = XcodeBuildOptions.forTesting(
///     project: "MyApp",
///     scheme: "MyApp",
///     destination: .iOSSimulator(device: "iPhone 14"),
///     testPlan: "MyAppTests"
/// )
/// ```
public struct XcodeBuildOptions: Sendable {
    // MARK: - Project Details
    /// The name of the Xcode project (without .xcodeproj extension).
    public let project: String
    /// The scheme to build, test, or archive.
    public let scheme: String?
    /// A specific target to build.
    public let target: String?
    /// The build configuration (e.g., "Debug", "Release").
    public let configuration: String?
    /// The directory where the build command should be executed.
    public let workingDirectory: String?

    // MARK: - Build Configuration
    public let sdk: SDK?
    public let destination: Destination?
    public let derivedDataPath: String?
    public let xcconfig: String?

    // MARK: - Test Configuration
    public let testPlan: String?
    public let testConfiguration: String?
    public let testLanguage: String?
    public let testRegion: String?
    public let skipTesting: [String]
    public let onlyTesting: [String]
    public let testTargets: [String]

    // MARK: - Archive Configuration
    public let archivePath: ArchivePath?
    public let exportOptions: ExportOptions?

    // MARK: - Build Settings
    public let enableCodeCoverage: Bool
    public let enableThreadSanitizer: Bool
    public let enableAddressSanitizer: Bool
    public let enableUndefinedBehaviorSanitizer: Bool
    public let enableBitcode: Bool
    public let parallelizeTargets: Bool
    public let maximumActions: Int?
    public let jobs: Int?
    public let hideShellScript: Bool
    public let allowProvisioningUpdates: Bool

    // MARK: - Additional Settings
    public let extraArguments: [String]

    /// Creates a new build configuration with the specified options.
    ///
    /// - Parameters:
    ///   - project: The name of the Xcode project.
    ///   - scheme: The scheme to build, test, or archive.
    ///   - target: A specific target to build.
    ///   - configuration: The build configuration.
    ///   - workingDirectory: The directory where the build command should be executed.
    ///   - sdk: The SDK to build against.
    ///   - destination: The build destination.
    ///   - derivedDataPath: Custom path for derived data.
    ///   - xcconfig: Path to an xcconfig file.
    ///   - testPlan: The test plan to use.
    ///   - testConfiguration: The test configuration to use.
    ///   - testLanguage: The language to use for testing.
    ///   - testRegion: The region to use for testing.
    ///   - skipTesting: Test targets to skip.
    ///   - onlyTesting: Test targets to include exclusively.
    ///   - testTargets: Specific test targets to run.
    ///   - archivePath: Path where the archive will be created.
    ///   - exportOptions: Options for exporting the archive.
    ///   - enableCodeCoverage: Whether to enable code coverage.
    ///   - enableThreadSanitizer: Whether to enable the thread sanitizer.
    ///   - enableAddressSanitizer: Whether to enable the address sanitizer.
    ///   - enableUndefinedBehaviorSanitizer: Whether to enable the undefined behavior sanitizer.
    ///   - enableBitcode: Whether to enable bitcode.
    ///   - parallelizeTargets: Whether to parallelize target building.
    ///   - maximumActions: Maximum concurrent build actions.
    ///   - jobs: Number of parallel build jobs.
    ///   - hideShellScript: Whether to hide shell script environment variables.
    ///   - allowProvisioningUpdates: Whether to allow provisioning profile updates.
    ///   - extraArguments: Additional xcodebuild arguments.
    public init(
        project: String,
        scheme: String? = nil,
        target: String? = nil,
        configuration: String? = nil,
        workingDirectory: String? = nil,
        sdk: SDK? = nil,
        destination: Destination? = nil,
        derivedDataPath: String? = nil,
        xcconfig: String? = nil,
        testPlan: String? = nil,
        testConfiguration: String? = nil,
        testLanguage: String? = nil,
        testRegion: String? = nil,
        skipTesting: [String],
        onlyTesting: [String],
        testTargets: [String],
        archivePath: ArchivePath? = nil,
        exportOptions: ExportOptions? = nil,
        enableCodeCoverage: Bool,
        enableThreadSanitizer: Bool,
        enableAddressSanitizer: Bool,
        enableUndefinedBehaviorSanitizer: Bool,
        enableBitcode: Bool,
        parallelizeTargets: Bool,
        maximumActions: Int? = nil,
        jobs: Int? = nil,
        hideShellScript: Bool,
        allowProvisioningUpdates: Bool,
        extraArguments: [String]
    ) {
        self.project = project
        self.scheme = scheme
        self.target = target
        self.configuration = configuration
        self.workingDirectory = workingDirectory
        self.sdk = sdk
        self.destination = destination
        self.derivedDataPath = derivedDataPath
        self.xcconfig = xcconfig
        self.testPlan = testPlan
        self.testConfiguration = testConfiguration
        self.testLanguage = testLanguage
        self.testRegion = testRegion
        self.skipTesting = skipTesting
        self.onlyTesting = onlyTesting
        self.testTargets = testTargets
        self.archivePath = archivePath
        self.exportOptions = exportOptions
        self.enableCodeCoverage = enableCodeCoverage
        self.enableThreadSanitizer = enableThreadSanitizer
        self.enableAddressSanitizer = enableAddressSanitizer
        self.enableUndefinedBehaviorSanitizer = enableUndefinedBehaviorSanitizer
        self.enableBitcode = enableBitcode
        self.parallelizeTargets = parallelizeTargets
        self.maximumActions = maximumActions
        self.jobs = jobs
        self.hideShellScript = hideShellScript
        self.allowProvisioningUpdates = allowProvisioningUpdates
        self.extraArguments = extraArguments
    }

    // MARK: - Command Line Arguments
    /// Converts the build options into command-line arguments for xcodebuild.
    ///
    /// - Parameter action: The build action to generate arguments for.
    /// - Returns: An array of command-line arguments.
    public func asArguments(for action: XcodeBuildAction) -> [String] {
        var args: [String] = []

        // Project configuration
        args.append("-project \(project).xcodeproj")
        scheme.map { args.append("-scheme \($0)") }
        target.map { args.append("-target \($0)") }
        configuration.map { args.append("-configuration \($0)") }

        // Build settings
        sdk.map { args.append("-sdk \($0.value)") }
        destination.map { args.append("-destination '\($0.value)'") }
        derivedDataPath.map { args.append("-derivedDataPath \($0)") }
        xcconfig.map { args.append("-xcconfig \($0)") }

        // Test configuration
        if case .test = action {
            testPlan.map { args.append("-testPlan \($0)") }
            testConfiguration.map { args.append("-testConfiguration \($0)") }
            testLanguage.map { args.append("-testLanguage \($0)") }
            testRegion.map { args.append("-testRegion \($0)") }

            if !skipTesting.isEmpty {
                args.append("-skip-testing:\(skipTesting.joined(separator: ","))")
            }
            if !onlyTesting.isEmpty {
                for test in onlyTesting {
                    args.append("-only-testing:\(test)")
                }
            }
            if !testTargets.isEmpty {
                args.append("-only-testing:\(testTargets.joined(separator: ","))")
            }
        }

        // Archive configuration
        if case .archive = action {
            archivePath.map { args.append("-archivePath \($0.path)") }
        }
        if case .exportArchive = action {
            archivePath.map { args.append("-archivePath \($0.path)") }
            exportOptions.map { args.append("-exportOptionsPlist \($0)") }
            if allowProvisioningUpdates {
                args.append("-allowProvisioningUpdates")
            }
        }

        // Build flags
        if enableCodeCoverage { args.append("-enableCodeCoverage YES") }
        if enableThreadSanitizer { args.append("-enableThreadSanitizer YES") }
        if enableAddressSanitizer { args.append("-enableAddressSanitizer YES") }
        if enableUndefinedBehaviorSanitizer { args.append("-enableUndefinedBehaviorSanitizer YES") }
        if enableBitcode { args.append("ENABLE_BITCODE=YES") }
        if parallelizeTargets { args.append("-parallelizeTargets") }
        maximumActions.map { args.append("-maximum-concurrent-actions \($0)") }
        jobs.map { args.append("-jobs \($0)") }
        if hideShellScript { args.append("-hideShellScriptEnvironment") }

        args.append(contentsOf: extraArguments)

        args.append(action.command)

        return args
    }

    /// Creates build configuration options optimized for a standard build operation.
    ///
    /// - Parameters:
    ///   - project: The name of the Xcode project.
    ///   - scheme: The scheme to build.
    ///   - configuration: The build configuration (e.g., "Debug", "Release").
    ///   - sdk: The SDK to build against.
    ///   - destination: The build destination.
    ///   - target: Optional specific target to build.
    ///   - derivedDataPath: Optional custom derived data path.
    ///   - xcconfig: Optional path to an xcconfig file.
    ///   - enableBitcode: Whether to enable bitcode.
    ///   - parallelizeTargets: Whether to parallelize target building.
    ///   - maximumActions: Optional maximum concurrent build actions.
    ///   - jobs: Optional number of parallel build jobs.
    ///   - hideShellScript: Whether to hide shell script environment variables.
    ///   - extraArguments: Additional xcodebuild arguments.
    /// - Returns: A configured ``XcodeBuildOptions`` instance for building.
    public static func forBuild(
        project: String,
        scheme: String,
        configuration: String,
        sdk: SDK?,
        destination: Destination?,
        target: String? = nil,
        derivedDataPath: String? = nil,
        xcconfig: String? = nil,
        enableBitcode: Bool = false,
        parallelizeTargets: Bool = false,
        maximumActions: Int? = nil,
        jobs: Int? = nil,
        hideShellScript: Bool = false,
        extraArguments: [String] = []
    ) -> XcodeBuildOptions {
        return XcodeBuildOptions(
            project: project,
            scheme: scheme,
            target: target,
            configuration: configuration,
            workingDirectory: nil,
            sdk: sdk,
            destination: destination,
            derivedDataPath: derivedDataPath,
            xcconfig: xcconfig,
            testPlan: nil,
            testConfiguration: nil,
            testLanguage: nil,
            testRegion: nil,
            skipTesting: [],
            onlyTesting: [],
            testTargets: [],
            archivePath: nil,
            exportOptions: nil,
            enableCodeCoverage: false,
            enableThreadSanitizer: false,
            enableAddressSanitizer: false,
            enableUndefinedBehaviorSanitizer: false,
            enableBitcode: enableBitcode,
            parallelizeTargets: parallelizeTargets,
            maximumActions: maximumActions,
            jobs: jobs,
            hideShellScript: hideShellScript,
            allowProvisioningUpdates: false,
            extraArguments: extraArguments
        )
    }

    /// Creates build configuration options optimized for running tests.
    ///
    /// - Parameters:
    ///   - project: The name of the Xcode project.
    ///   - scheme: The scheme to test.
    ///   - destination: The test destination.
    ///   - testPlan: Optional test plan name.
    ///   - testConfiguration: Optional test configuration name.
    ///   - testLanguage: Optional test language.
    ///   - testRegion: Optional test region.
    ///   - skipTesting: Test targets to skip.
    ///   - onlyTesting: Test targets to include exclusively.
    ///   - testTargets: Specific test targets to run.
    ///   - enableCodeCoverage: Whether to enable code coverage.
    ///   - enableThreadSanitizer: Whether to enable the thread sanitizer.
    ///   - enableAddressSanitizer: Whether to enable the address sanitizer.
    ///   - enableUndefinedBehaviorSanitizer: Whether to enable the undefined behavior sanitizer.
    ///   - xcconfig: Optional path to an xcconfig file.
    ///   - derivedDataPath: Optional custom derived data path.
    ///   - parallelizeTargets: Whether to parallelize target building.
    ///   - maximumActions: Optional maximum concurrent build actions.
    ///   - jobs: Optional number of parallel build jobs.
    ///   - hideShellScript: Whether to hide shell script environment variables.
    ///   - extraArguments: Additional xcodebuild arguments.
    /// - Returns: A configured ``XcodeBuildOptions`` instance for testing.
    public static func forTesting(
        project: String,
        scheme: String,
        destination: Destination,
        testPlan: String?,
        testConfiguration: String?,
        testLanguage: String?,
        testRegion: String?,
        skipTesting: [String],
        onlyTesting: [String],
        testTargets: [String],
        enableCodeCoverage: Bool = true,
        enableThreadSanitizer: Bool = false,
        enableAddressSanitizer: Bool = false,
        enableUndefinedBehaviorSanitizer: Bool = false,
        xcconfig: String? = nil,
        derivedDataPath: String? = nil,
        parallelizeTargets: Bool = false,
        maximumActions: Int? = nil,
        jobs: Int? = nil,
        hideShellScript: Bool = false,
        extraArguments: [String] = []
    ) -> XcodeBuildOptions {
        return XcodeBuildOptions(
            project: project,
            scheme: scheme,
            target: nil,
            configuration: nil,
            workingDirectory: nil,
            sdk: nil,
            destination: destination,
            derivedDataPath: derivedDataPath,
            xcconfig: xcconfig,
            testPlan: testPlan,
            testConfiguration: testConfiguration,
            testLanguage: testLanguage,
            testRegion: testRegion,
            skipTesting: skipTesting,
            onlyTesting: onlyTesting,
            testTargets: testTargets,
            archivePath: nil,
            exportOptions: nil,
            enableCodeCoverage: enableCodeCoverage,
            enableThreadSanitizer: enableThreadSanitizer,
            enableAddressSanitizer: enableAddressSanitizer,
            enableUndefinedBehaviorSanitizer: enableUndefinedBehaviorSanitizer,
            enableBitcode: false,
            parallelizeTargets: parallelizeTargets,
            maximumActions: maximumActions,
            jobs: jobs,
            hideShellScript: hideShellScript,
            allowProvisioningUpdates: false,
            extraArguments: extraArguments
        )
    }

    /// Creates build configuration options optimized for creating an archive.
    ///
    /// - Parameters:
    ///   - project: The name of the Xcode project.
    ///   - scheme: The scheme to archive.
    ///   - configuration: The build configuration.
    ///   - archivePath: The path where the archive will be created.
    ///   - target: Optional specific target to archive.
    ///   - derivedDataPath: Optional custom derived data path.
    ///   - xcconfig: Optional path to an xcconfig file.
    ///   - enableBitcode: Whether to enable bitcode.
    ///   - parallelizeTargets: Whether to parallelize target building.
    ///   - maximumActions: Optional maximum concurrent build actions.
    ///   - jobs: Optional number of parallel build jobs.
    ///   - hideShellScript: Whether to hide shell script environment variables.
    ///   - allowProvisioningUpdates: Whether to allow provisioning profile updates.
    ///   - extraArguments: Additional xcodebuild arguments.
    /// - Returns: A configured ``XcodeBuildOptions`` instance for archiving.
    public static func forArchive(
        project: String,
        scheme: String,
        configuration: String,
        archivePath: ArchivePath,
        target: String? = nil,
        derivedDataPath: String? = nil,
        xcconfig: String? = nil,
        enableBitcode: Bool = false,
        parallelizeTargets: Bool = false,
        maximumActions: Int? = nil,
        jobs: Int? = nil,
        hideShellScript: Bool = false,
        allowProvisioningUpdates: Bool = true,
        extraArguments: [String] = []
    ) -> XcodeBuildOptions {
        return XcodeBuildOptions(
            project: project,
            scheme: scheme,
            target: target,
            configuration: configuration,
            sdk: SDK.iPhoneOS,
            destination: nil,
            derivedDataPath: derivedDataPath,
            xcconfig: xcconfig,
            testPlan: nil,
            testConfiguration: nil,
            testLanguage: nil,
            testRegion: nil,
            skipTesting: [],
            onlyTesting: [],
            testTargets: [],
            archivePath: archivePath,
            exportOptions: nil,
            enableCodeCoverage: false,
            enableThreadSanitizer: false,
            enableAddressSanitizer: false,
            enableUndefinedBehaviorSanitizer: false,
            enableBitcode: enableBitcode,
            parallelizeTargets: parallelizeTargets,
            maximumActions: maximumActions,
            jobs: jobs,
            hideShellScript: hideShellScript,
            allowProvisioningUpdates: allowProvisioningUpdates,
            extraArguments: extraArguments
        )
    }

    /// Creates build configuration options optimized for exporting an archive.
    ///
    /// - Parameters:
    ///   - project: The name of the Xcode project.
    ///   - scheme: The scheme to export.
    ///   - exportOptions: The export configuration options.
    ///   - allowProvisioningUpdates: Whether to allow provisioning profile updates.
    ///   - extraArguments: Additional xcodebuild arguments.
    /// - Returns: A configured ``XcodeBuildOptions`` instance for exporting.
    public static func forExport(
        project: String,
        scheme: String,
        exportOptions: ExportOptions,
        allowProvisioningUpdates: Bool = true,
        extraArguments: [String] = []
    ) -> XcodeBuildOptions {
        return XcodeBuildOptions(
            project: project,
            scheme: scheme,
            target: nil,
            configuration: nil,
            sdk: nil,
            destination: nil,
            derivedDataPath: nil,
            xcconfig: nil,
            testPlan: nil,
            testConfiguration: nil,
            testLanguage: nil,
            testRegion: nil,
            skipTesting: [],
            onlyTesting: [],
            testTargets: [],
            archivePath: nil,
            exportOptions: exportOptions,
            enableCodeCoverage: false,
            enableThreadSanitizer: false,
            enableAddressSanitizer: false,
            enableUndefinedBehaviorSanitizer: false,
            enableBitcode: false,
            parallelizeTargets: false,
            maximumActions: nil,
            jobs: nil,
            hideShellScript: false,
            allowProvisioningUpdates: allowProvisioningUpdates,
            extraArguments: extraArguments
        )
    }
}
