//
//  BuildConfigurationValidator.swift
//  XCBuildKit
//
//  Created by Ali Hilal on 02/11/2024.
//

import Foundation

/// A protocol defining requirements for validating Xcode build configurations.
///
/// Conforming types are responsible for ensuring that build configurations contain
/// all required parameters for specific build actions.
public protocol BuildConfigurationValidating: Sendable {
    /// Validates the build configuration for a specific action.
    ///
    /// - Parameters:
    ///   - action: The Xcode build action to validate.
    ///   - options: The build options to validate.
    ///
    /// - Throws: An error if the configuration is invalid for the specified action.
    func validate(_ action: XcodeBuildAction, _ options: XcodeBuildOptions) throws
}

/// A validator that ensures build configurations meet the requirements for specific Xcode build actions.
///
/// `BuildConfigurationValidator` validates that all required parameters are present and properly
/// configured for different build actions such as testing, archiving, and exporting.
///
/// ## Example Usage
/// ```swift
/// let validator = BuildConfigurationValidator()
/// let options = XcodeBuildOptions(scheme: "MyApp", project: "MyApp.xcodeproj")
///
/// do {
///     try validator.validate(.test, options)
/// } catch {
///     print("Invalid configuration:", error.localizedDescription)
/// }
/// ```
public struct BuildConfigurationValidator: BuildConfigurationValidating {
    /// Creates a new instance of the build configuration validator.
    public init() {}

    /// Validates build configuration based on the specified action.
    ///
    /// - Parameters:
    ///   - action: The Xcode build action to validate.
    ///   - options: The build options to validate.
    ///
    /// - Throws: ``AnyError`` if any required configuration is missing.
    public func validate(_ action: XcodeBuildAction, _ options: XcodeBuildOptions) throws {
        switch action {
        case .test, .buildForTesting, .testWithoutBuilding:
            try validateTestingConfiguration(options)
        case .archive:
            try validateArchiveConfiguration(options)
        case .exportArchive:
            try validateExportConfiguration(options)
        default:
            break
        }
    }

    /// Validates configuration required for testing actions.
    ///
    /// - Parameter options: The build options to validate.
    /// - Throws: ``AnyError`` if any required testing configuration is missing.
    private func validateTestingConfiguration(_ options: XcodeBuildOptions) throws {
        try validateRequiredField(options.destination?.value, "Destination")
        try validateRequiredField(options.project, "Project")
        try validateRequiredField(options.scheme, "Scheme")
    }

    /// Validates configuration required for archive actions.
    ///
    /// - Parameter options: The build options to validate.
    /// - Throws: ``AnyError`` if any required archive configuration is missing.
    private func validateArchiveConfiguration(_ options: XcodeBuildOptions) throws {
        try validateRequiredField(options.archivePath?.path, "Archive path")
        try validateRequiredField(options.project, "Project")
        try validateRequiredField(options.scheme, "Scheme")
    }

    /// Validates configuration required for export actions.
    ///
    /// - Parameter options: The build options to validate.
    /// - Throws: ``AnyError`` if any required export configuration is missing.
    private func validateExportConfiguration(_ options: XcodeBuildOptions) throws {
        guard let exportOptions = options.exportOptions else {
            throw AnyError("Export options are required for export")
        }

        try validateRequiredField(exportOptions.archivePath, "Archive path")
        try validateRequiredField(exportOptions.exportPath, "Export path")
        try validateRequiredField(exportOptions.optionsPlist, "Export options plist")
    }

    /// Validates a required field and throws an error if it is missing or empty.
    ///
    /// - Parameters:
    ///   - value: The value to validate.
    ///   - fieldName: The name of the field.
    ///
    /// - Throws: ``AnyError`` if the value is missing or empty.
    private func validateRequiredField(_ value: String?, _ fieldName: String) throws {
        guard let value = value, !value.isEmpty else {
            throw AnyError("\(fieldName) is required")
        }
    }
}

struct AnyError: Swift.Error, LocalizedError {
    let message: String

    init (_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}
