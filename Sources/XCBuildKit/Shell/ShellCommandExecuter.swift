//
//  ShellCommand.swift
//  XCBuildKit
//
//  Created by Ali Hilal on 15/12/2022.
//

import Foundation

/// A class that provides shell command execution capabilities with real-time output streaming.
///
/// `ShellCommandExecuter` allows you to execute shell commands asynchronously while capturing
/// their output in real-time. It handles both standard output and standard error streams,
/// and provides proper process management and cleanup.
///
/// ## Overview
/// The executor provides a safe way to run shell commands and handle their output:
/// - Resolves executable paths automatically
/// - Streams output in real-time
/// - Handles process termination and cleanup
/// - Provides detailed error information
///
/// ## Example Usage
/// ```swift
/// let executor = ShellCommandExecuter()
///
/// // Execute a simple command
/// for try await output in executor.execute(arguments: ["ls", "-la"]) {
///     switch output {
///     case .stdout(let data):
///         print("Output:", String(data: data, encoding: .utf8) ?? "")
///     case .stderr(let data):
///         print("Error:", String(data: data, encoding: .utf8) ?? "")
///     }
/// }
///
/// // Using the static convenience method
/// let output = try await ShellCommandExecuter.execute("git", "status")
///     .collectOutput()
/// ```
public final class ShellCommandExecuter: Sendable, ShellCommandExecuting {

    /// Creates a new instance of the shell command executor.
    public init() { }

    /// Executes a shell command with the specified configuration.
    ///
    /// This method executes the given command asynchronously and streams its output. The first argument
    /// is treated as the command to execute, and subsequent arguments are passed to that command.
    ///
    /// - Parameters:
    ///   - arguments: An array of command-line arguments. The first element must be the command to execute.
    ///   - environment: A dictionary of environment variables for the command. Defaults to the current process environment.
    ///   - workingDirectory: The directory from which to execute the command. If nil, uses the current working directory.
    ///
    /// - Returns: An asynchronous throwing stream that emits ``ShellOutput`` instances containing
    ///           the command's output data.
    ///
    /// - Throws: ``ShellError/missingExecutable`` if the arguments array is empty
    /// - Throws: ``ShellError/executableNotFound`` if the command cannot be found
    /// - Throws: ``ShellError/nonZeroExit`` if the command exits with a non-zero status
    /// - Throws: ``ShellError/terminated`` if the command is terminated by a signal
    public func execute(
        arguments: [String],
        environment: [String: String] = ProcessInfo.processInfo.environment,
        workingDirectory: String? = nil
    ) -> AsyncThrowingStream<ShellOutput, Error> {
        AsyncThrowingStream { continuation in
            let processController = ProcessController()
            let sendableContinuation = SendableContinuation(continuation)
            let taskController = TaskController()

            Task {
                await taskController.start {

                    do {
                        guard let executableName = arguments.first else {
                            throw ShellError.missingExecutable
                        }

                        let executable = try await self.resolveExecutable(executableName)
                        let processArguments = Array(arguments.dropFirst())

                        let stdoutPipe = Pipe()
                        let stderrPipe = Pipe()

                        let process = await processController.setup(
                            executable: executable,
                            arguments: processArguments,
                            environment: environment,
                            workingDirectory: workingDirectory
                        )

                        process.standardOutput = stdoutPipe
                        process.standardError = stderrPipe

                        let stdoutHandle = stdoutPipe.fileHandleForReading
                        let stderrHandle = stderrPipe.fileHandleForReading

                        stdoutHandle.readabilityHandler = { @Sendable handle in
                            let data = handle.availableData
                            guard !data.isEmpty else { return }
                            Task {
                                await sendableContinuation.yield(.stdout(data))
                            }
                        }

                        stderrHandle.readabilityHandler = { @Sendable handle in
                            let data = handle.availableData
                            guard !data.isEmpty else { return }
                            Task {
                                await processController.appendStderr(data)
                                await sendableContinuation.yield(.stderr(data))
                            }
                        }

                        try process.run()
                        process.waitUntilExit()

                        // Cleanup
                        stdoutHandle.readabilityHandler = nil
                        stderrHandle.readabilityHandler = nil

                        // Read any remaining data
                        if let finalStdoutData = try? stdoutHandle.readToEnd(),
                           !finalStdoutData.isEmpty {
                            await sendableContinuation.yield(.stdout(finalStdoutData))
                        }

                        if let finalStderrData = try? stderrHandle.readToEnd(),
                           !finalStderrData.isEmpty {
                            await processController.appendStderr(finalStderrData)
                            await sendableContinuation.yield(.stderr(finalStderrData))
                        }

                        switch process.terminationReason {
                        case .exit where process.terminationStatus != 0:
                            let errorData = await processController.getStderr()
                            throw ShellError.nonZeroExit(
                                code: process.terminationStatus,
                                stderr: String(data: errorData, encoding: .utf8) ?? ""
                            )
                        case .uncaughtSignal:
                            throw ShellError.terminated(signal: process.terminationStatus)
                        default:
                            break
                        }

                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }

                continuation.onTermination = { @Sendable _ in
                    Task {
                        await processController.terminate()
                        await taskController.cancel()

                    }
                }
            }
        }
    }

    /// Resolves the full path of an executable command.
    ///
    /// - Parameter command: The command name or path to resolve.
    /// - Returns: A URL representing the full path to the executable.
    /// - Throws: ``ShellError/executableNotFound`` if the command cannot be found in PATH.
    private func resolveExecutable(_ command: String) async throws -> URL {
        if command.hasPrefix("/") || command.hasPrefix("./") {
            return URL(fileURLWithPath: command)
        }

        let whichProcess = Process()
        whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        whichProcess.arguments = [command]

        let pipe = Pipe()
        whichProcess.standardOutput = pipe

        try whichProcess.run()
        whichProcess.waitUntilExit()

        guard let data = try pipe.fileHandleForReading.readToEnd(),
              let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !path.isEmpty else {
            throw ShellError.executableNotFound(command)
        }

        return URL(fileURLWithPath: path)
    }
}

/// Convenience methods for executing shell commands.
public extension ShellCommandExecuter {
    /// Executes a shell command using variadic arguments.
    ///
    /// This static method provides a convenient way to execute shell commands without
    /// creating an explicit instance of `ShellCommandExecuter`.
    ///
    /// - Parameters:
    ///   - arguments: The command and its arguments as variadic strings.
    ///   - environment: Optional environment variables for the command.
    ///   - workingDirectory: Optional working directory for command execution.
    ///
    /// - Returns: An asynchronous throwing stream of command output.
    static func execute(
        _ arguments: String...,
        environment: [String: String]? = nil,
        at workingDirectory: String? = nil
    ) -> AsyncThrowingStream<ShellOutput, Error> {
        ShellCommandExecuter().execute(
            arguments: arguments,
            environment: environment ?? ProcessInfo.processInfo.environment,
            workingDirectory: workingDirectory
        )
    }
}

// private actor TaskController {
//    private var task: Task<Void, Never>?
//
//    func start(_ block: @escaping @Sendable () async throws -> Void) {
//        task = Task { try? await block() }
//    }
//
//    func cancel() {
//        task?.cancel()
//    }
// }

private actor ProcessController {
    private var process: Process?
    private let stderrCollector = OutputCollector()

    func setup(
        executable: URL,
        arguments: [String],
        environment: [String: String],
        workingDirectory: String?
    ) -> Process {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.environment = environment
        if let workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }
        self.process = process
        return process
    }

    func appendStderr(_ data: Data) async {
        await stderrCollector.append(data)
    }

    func getStderr() async -> Data {
        await stderrCollector.getData()
    }

    func terminate() {
        process?.terminate()
    }
}

private actor OutputCollector {
    private var collectedData = Data()

    func append(_ data: Data) {
        collectedData.append(data)
    }

    func getData() -> Data {
        collectedData
    }
}

private actor SendableContinuation<T: Sendable> {
    private let continuation: AsyncThrowingStream<T, Error>.Continuation

    init(_ continuation: AsyncThrowingStream<T, Error>.Continuation) {
        self.continuation = continuation
    }

    func yield(_ value: T) {
        continuation.yield(value)
    }

    func finish() {
        continuation.finish()
    }

    func finish(throwing error: Error) {
        continuation.finish(throwing: error)
    }
}

/// Convenience methods for collecting shell command output.
///
/// This extension provides utility methods for working with shell command output streams,
/// making it easier to collect and process command output data.
public extension AsyncThrowingStream where Element == ShellOutput {
    /// Collects all output from the command into a single string.
    ///
    /// This method accumulates all output from the command stream into a single string,
    /// optionally including standard error output.
    ///
    /// ## Example Usage
    /// ```swift
    /// // Collect only stdout
    /// let output = try await shellCommand.execute("ls", "-la")
    ///     .collectOutput()
    ///
    /// // Collect both stdout and stderr
    /// let allOutput = try await shellCommand.execute("git", "status")
    ///     .collectOutput(includeStderr: true)
    /// ```
    ///
    /// - Parameter includeStderr: A boolean indicating whether to include standard error output
    ///   in the collected string. Defaults to `false`.
    ///
    /// - Returns: A string containing all collected output from the command.
    ///
    /// - Throws: Any error that occurs during command execution or output processing.
    func collectOutput(includeStderr: Bool = false) async throws -> String {
        try await reduce(into: "") { result, output in
            switch output {
            case .stdout(let data):
                if let str = String(data: data, encoding: .utf8) {
                    result += str
                }
            case .stderr(let data):
                if includeStderr, let str = String(data: data, encoding: .utf8) {
                    result += str
                }
            }
        }
    }
}
