//
//  File.swift
//  XCBuildKit
//
//  Created by Ali Hilal on 02/11/2024.
//

import Foundation

/// A protocol defining requirements for formatting Xcode build log output.
///
/// Conforming types provide methods to format different types of build log messages,
/// such as errors, warnings, build phases, and test output, into a consistent and
/// readable format.
///
/// ## Example Usage
/// ```swift
/// let formatter = BuildLogFormatter()
/// let errorMessage = formatter.formatError("❌ Build failed")
/// print(errorMessage) // Prints: "Error: Build failed"
/// ```
public protocol BuildLogFormattable: Sendable {
    /// Formats error messages from the build log.
    ///
    /// - Parameter line: The raw error message line from the build log.
    /// - Returns: A formatted error message string.
    func formatError(_ line: String) -> String

    /// Formats warning messages from the build log.
    ///
    /// - Parameter line: The raw warning message line from the build log.
    /// - Returns: A formatted warning message string.
    func formatWarning(_ line: String) -> String

    /// Formats build phase headers from the build log.
    ///
    /// - Parameter line: The raw build phase line from the build log.
    /// - Returns: A formatted build phase string.
    func formatBuildPhase(_ line: String) -> String

    /// Formats test output messages from the build log.
    ///
    /// - Parameter line: The raw test output line from the build log.
    /// - Returns: A formatted test output string.
    func formatTestOutput(_ line: String) -> String

    /// Formats progress messages from the build log.
    ///
    /// - Parameter line: The raw progress line from the build log.
    /// - Returns: A formatted progress string.
    func formatProgress(_ line: String) -> String

    /// Formats success messages from the build log.
    ///
    /// - Parameter line: The raw success message line from the build log.
    /// - Returns: A formatted success message string.
    func formatSuccess(_ line: String) -> String

    /// Formats generic messages from the build log.
    ///
    /// - Parameter line: The raw message line from the build log.
    /// - Returns: A formatted message string.
    func formatGeneric(_ line: String) -> String
}

/// A concrete implementation of ``BuildLogFormattable`` that formats Xcode build log output.
///
/// `BuildLogFormatter` provides standardized formatting for different types of build log
/// messages, removing special characters and adding consistent prefixes where appropriate.
///
/// ## Example Usage
/// ```swift
/// let formatter = BuildLogFormatter()
///
/// // Format an error message
/// let error = formatter.formatError("❌ Compilation failed")
///
/// // Format a warning message
/// let warning = formatter.formatWarning("⚠️ Deprecated API usage")
///
/// // Format a success message
/// let success = formatter.formatSuccess("✓ Build succeeded")
/// ```
public struct BuildLogFormatter: BuildLogFormattable {
    /// Creates a new instance of the build log formatter.
    public init() {}

    /// Formats error messages by removing the error emoji and adding an "Error:" prefix.
    public func formatError(_ line: String) -> String {
        "Error: " + line.replacingOccurrences(of: "❌ ", with: "")
    }

    /// Formats warning messages by removing the warning emoji and adding a "Warning:" prefix.
    public func formatWarning(_ line: String) -> String {
        "Warning: " + line.replacingOccurrences(of: "⚠️ ", with: "")
    }

    /// Formats build phase headers by removing the "===" delimiters and extra whitespace.
    public func formatBuildPhase(_ line: String) -> String {
        line.replacingOccurrences(of: "===", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Passes through test output without modification.
    public func formatTestOutput(_ line: String) -> String {
        line
    }

    /// Formats progress messages by removing the progress indicator and extra whitespace.
    public func formatProgress(_ line: String) -> String {
        line.replacingOccurrences(of: "▸", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Formats success messages by removing the checkmark and adding a "Completed:" prefix.
    public func formatSuccess(_ line: String) -> String {
        "Completed: " + line.replacingOccurrences(of: "✓", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Passes through generic messages without modification.
    public func formatGeneric(_ line: String) -> String {
        line
    }
}
