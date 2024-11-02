//
//  File.swift
//  XCBuildKit
//
//  Created by Ali Hilal on 02/11/2024.
//

import Foundation

/// Represents errors that can occur during shell command execution.
///
/// `ShellError` encapsulates various error conditions that might arise when executing
/// shell commands, such as missing executables, command not found, non-zero exit codes,
/// and process termination signals.
///
/// ## Error Cases
/// The error can be one of the following:
/// - Missing executable command
/// - Executable not found in PATH
/// - Process exit with non-zero status code
/// - Process terminated by signal
///
/// ## Example Usage
/// ```swift
/// do {
///     let output = try await shell.execute(arguments: ["nonexistent"])
/// } catch let error as ShellError {
///     switch error {
///     case .executableNotFound(let name):
///         print("Command not found:", name)
///     case .nonZeroExit(let code, let stderr):
///         print("Command failed with code:", code)
///         print("Error output:", stderr)
///     default:
///         print("Other error:", error.localizedDescription)
///     }
/// }
/// ```
public enum ShellError: LocalizedError {
    /// The command to execute was not provided or was empty.
    case missingExecutable

    /// The specified executable could not be found in the system PATH.
    ///
    /// - Parameter name: The name of the executable that couldn't be found.
    case executableNotFound(String)

    /// The command completed but returned a non-zero exit code.
    ///
    /// - Parameters:
    ///   - code: The exit code returned by the process.
    ///   - stderr: The error output captured from the process.
    case nonZeroExit(code: Int32, stderr: String)

    /// The process was terminated by a signal.
    ///
    /// - Parameter signal: The signal number that terminated the process.
    case terminated(signal: Int32)

    /// A localized description of the error suitable for user presentation.
    ///
    /// This property provides human-readable error messages for each error case.
    public var errorDescription: String? {
        switch self {
        case .missingExecutable:
            return "No executable specified"
        case .executableNotFound(let name):
            return "Executable not found: \(name)"
        case .nonZeroExit(let code, let stderr):
            return "Process exited with code \(code)\nStderr: \(stderr)"
        case .terminated(let signal):
            return "Process terminated with signal \(signal)"
        }
    }

    /// Indicates whether the error represents a process termination.
    ///
    /// Use this property to determine if the error was caused by process termination,
    /// which might require special handling in certain scenarios.
    ///
    /// - Returns: `true` if the error is a termination error, `false` otherwise.
    var isTerminationError: Bool {
        switch self {
        case .terminated:
            return true
        default:
            return false
        }
    }
}
