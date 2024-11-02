//
//  ShellOutput.swift
//  XCBuildKit
//
//  Created by Ali Hilal on 15/12/2022.
//

import Foundation

/// Represents the output streams from a shell command execution.
///
/// `ShellOutput` encapsulates both standard output (stdout) and standard error (stderr)
/// data from a shell command, allowing consumers to distinguish between regular output
/// and error messages.
///
/// ## Overview
/// The enum provides two cases:
/// - `.stdout`: Contains regular command output data
/// - `.stderr`: Contains error or diagnostic output data
///
/// ## Example Usage
/// ```swift
/// let shell = ShellCommandExecuter()
/// for try await output in shell.execute(arguments: ["ls", "-la"]) {
///     switch output {
///     case .stdout(let data):
///         print("Output:", output.string() ?? "")
///     case .stderr(let data):
///         print("Error:", output.string() ?? "")
///     }
/// }
/// ```
public enum ShellOutput: Sendable {
    /// Standard output data from the command.
    ///
    /// - Parameter data: The raw output data from the command's stdout stream.
    case stdout(Data)
    
    /// Standard error data from the command.
    ///
    /// - Parameter data: The raw output data from the command's stderr stream.
    case stderr(Data)
    
    /// Indicates whether the output represents an error message.
    ///
    /// Use this property to quickly determine if the output came from
    /// the standard error stream.
    ///
    /// - Returns: `true` if the output is from stderr, `false` if from stdout.
    public var isError: Bool {
        switch self {
        case .stderr: true
        case .stdout: false
        }
    }
    
    /// Converts the output data to a string using the specified encoding.
    ///
    /// This method attempts to convert the raw output data into a string
    /// using the provided text encoding.
    ///
    /// - Parameter encoding: The text encoding to use for conversion. Defaults to UTF-8.
    /// - Returns: A string representation of the output data, or `nil` if conversion fails.
    public func string(encoding: String.Encoding = .utf8) -> String? {
        switch self {
        case let .stdout(data), let .stderr(data):
            String(data: data, encoding: encoding)
        }
    }
}
