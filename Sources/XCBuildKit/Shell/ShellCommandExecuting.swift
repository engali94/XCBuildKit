//
//  ShellCommandExecuting.swift
//  XCBuildKit
//
//  Created by Ali Hilal on 15/12/2022.
//

import Foundation

/// A protocol that defines an interface for executing shell commands.
///
/// Use this protocol to abstract shell command execution in your application. Conforming types
/// should provide implementation for executing shell commands with specified arguments,
/// environment variables, and working directory.
///
/// ## Example Usage
/// ```swift
/// let shell: ShellCommandExecuting = RealShellExecutor()
/// let output = try await shell.execute(
///     arguments: ["ls", "-la"],
///     environment: ["PATH": "/usr/bin"],
///     workingDirectory: "/Users/developer"
/// )
/// ```
public protocol ShellCommandExecuting: Sendable {
    /// Executes a shell command with the specified configuration.
    ///
    /// This method executes a shell command asynchronously and returns a stream of output.
    /// The output stream provides real-time access to the command's standard output and standard error.
    ///
    /// - Parameters:
    ///   - arguments: An array of command-line arguments where the first element is typically the command to execute.
    ///   - environment: A dictionary of environment variables to be set for the command execution.
    ///   - workingDirectory: The directory path from which to execute the command. If nil, uses the current working directory.
    ///
    /// - Returns: An asynchronous throwing stream that emits ``ShellOutput`` instances containing
    ///           the command's output data.
    ///
    /// - Throws: An error if the command execution fails or if there are issues with the stream.
    @discardableResult
    func execute(
        arguments: [String],
        environment: [String: String],
        workingDirectory: String?
    ) -> AsyncThrowingStream<ShellOutput, Error>
}
