//
//  File.swift
//  XCBuildKit
//
//  Created by Ali Hilal on 02/11/2024.
//

import Foundation

actor TaskController {
    private var task: Task<Void, Error>?
    
    func start(_ block: @escaping @Sendable () async throws -> Void) {
        task = Task {
            do {
                try await block()
            } catch {
                throw error
            }
        }
    }
    
    func cancel() {
        task?.cancel()
    }
}

/// A class that manages Xcode build operations and processes their output.
///
/// `XcodeBuild` provides functionality to execute various Xcode build actions,
/// process their output, and report build progress and status through a stream
/// of build states.
///
/// ## Example Usage
/// ```swift
/// let builder = XcodeBuild()
/// let options = XcodeBuildOptions(scheme: "MyApp", project: "MyApp.xcodeproj")
///
/// for await state in builder.execute(.build, options: options) {
///     switch state {
///     case .inProgress(let phase):
///         print("Building:", phase)
///     case .completed:
///         print("Build succeeded")
///     case .error(let message):
///         print("Build failed:", message)
///     }
/// }
/// ```
public final class XcodeBuild: Sendable, XcodeBuilding {
    
    // MARK: - Types
    /// Errors that can occur during the build process.
    public enum XcodeBuildError: LocalizedError {
        /// The build configuration is invalid.
        case invalidConfiguration(String)
        
        /// The build failed with an error.
        case buildFailed(String)
        
        /// The build task was cancelled.
        case taskCancelled
        
        /// A dependency-related error occurred.
        case dependencyError(String)
        
        /// A localized description of the error.
        public var errorDescription: String? {
            switch self {
            case .invalidConfiguration(let reason):
                return "Invalid build configuration: \(reason)"
            case .buildFailed(let reason):
                return "Build failed: \(reason)"
            case .taskCancelled:
                return "Build task was cancelled"
            case .dependencyError(let message):
                return "Dependency error: \(message). Try cleaning derived data and rebuilding."
            }
        }
    }
    
    private enum BuildOutputIndicator {
        static let error = "❌"
        static let warning = "⚠️"
        static let progress = "▸"
        static let success = "✓"
        static let building = "=== BUILD"
        static let testSuite = "Test Suite"
        static let testCase = "Test Case"
    }
    
    // MARK: - Properties
    private let shellCommand: ShellCommandExecuting
    private let logsPath: URL
    private let logFormatter: BuildLogFormattable
    private let validator: BuildConfigurationValidating

    // MARK: - Initialization
    /// Creates a new instance of the Xcode build manager.
    ///
    /// - Parameters:
    ///   - shellCommand: The shell command executor to use. Defaults to ``ShellCommandExecuter``.
    ///   - logsPath: The directory where build logs will be stored. Defaults to the temporary directory.
    ///   - logFormatter: The formatter for build output
    public init(
        shellCommand: ShellCommandExecuting = ShellCommandExecuter(),
        logsPath: URL = FileManager.default.temporaryDirectory,
        logFormatter: BuildLogFormattable = BuildLogFormatter()
    ) {
        self.shellCommand = shellCommand
        self.validator = BuildConfigurationValidator()
        self.logsPath = logsPath
        self.logFormatter = logFormatter
    }
    
    // MARK: - XcodeBuilding
    public func execute(_ action: XcodeBuildAction, options: XcodeBuildOptions) -> AsyncStream<BuildState> {
        AsyncStream { continuation in
            let taskController = TaskController()
            
            Task {
                await taskController.start {
                    do {
                        try self.setupLogsDirectory()
                        let rawLogPath = try self.createLogFile(for: action)
                        let arguments = try self.validateAndGetArguments(action, options)
                        
                        let output = self.shellCommand.execute(
                            arguments: ["/bin/bash", "-c", self.buildCommand(arguments: arguments, logPath: rawLogPath)],
                            environment: ProcessInfo.processInfo.environment,
                            workingDirectory: options.workingDirectory
                        )
                        
                        try await self.processOutput(output, continuation: continuation)
                        continuation.yield(.completed)
                        
                    } catch {
                        self.handleError(error, continuation: continuation)
                    }
                    continuation.finish()
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                Task {
                    await taskController.cancel()
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupLogsDirectory() throws {
        try FileManager.default.createDirectory(
            at: logsPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    private func createLogFile(for action: XcodeBuildAction) throws -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logFileName = "xcodebuild_\(action.command)_\(timestamp).log"
        return logsPath.appendingPathComponent(logFileName)
    }
    
    private func buildCommand(arguments: [String], logPath: URL) -> String {
        let command = """
        set -o pipefail && \
        xcodebuild \(arguments.joined(separator: " ")) \
        | tee '\(logPath.path)' \
        | xcbeautify
        """
        print("Executing command: \(command)")
        return command
    }
    
    private func validateAndGetArguments(_ action: XcodeBuildAction, _ options: XcodeBuildOptions) throws -> [String] {
        try validator.validate(action, options)
        return options.asArguments(for: action)
    }
    
    private func processOutput(
        _ output: AsyncThrowingStream<ShellOutput, Error>,
        continuation: AsyncStream<BuildState>.Continuation
    ) async throws {
        for try await outputLine in output {
            switch outputLine {
            case .stdout(let data):
                if let line = String(data: data, encoding: .utf8) {
                    let lines = line.components(separatedBy: .newlines)
                    for line in lines where !line.isEmpty {
                        
                        // Don't treat simulator warnings as build failures
                        if line.contains("WARNING: Using the first of multiple matching destinations") {
                            continuation.yield(.inProgress(line))
                        } else {
                            continuation.yield(processOutputLine(line))
                        }
                    }
                }
            case .stderr(let data):
                if let line = String(data: data, encoding: .utf8) {
                    // Don't treat simulator warnings as build failures
                    if line.contains("WARNING: Using the first of multiple matching destinations") {
                        continuation.yield(.inProgress(line))
                    } else {
                        continuation.yield(.error(line))
                    }
                }
            }
        }
    }
    
    private func handleError(_ error: Error, continuation: AsyncStream<BuildState>.Continuation) {
        if error is CancellationError {
            continuation.yield(.error(XcodeBuildError.taskCancelled.localizedDescription))
        } else if let buildError = error as? XcodeBuildError {
            continuation.yield(.error(buildError.localizedDescription))
        } else {
            continuation.yield(.error(error.localizedDescription))
        }
        // don't yield .completed after an error
    }
    
    private func processOutputLine(_ line: String) -> BuildState {
        guard !line.isEmpty else { return .inProgress(line) }
        
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        
        // Check if it's just a simulator destination warning
        if trimmedLine.contains("WARNING: Using the first of multiple matching destinations") {
            return .inProgress(logFormatter.formatWarning(trimmedLine))
        }
        
        switch true {
        case line.contains(BuildOutputIndicator.error):
            // Make sure it's an actual error, not just a warning
            if !line.contains("WARNING:") {
                return .error(logFormatter.formatError(trimmedLine))
            }
            return .inProgress(logFormatter.formatWarning(trimmedLine))
        case line.contains(BuildOutputIndicator.warning):
            return .inProgress(logFormatter.formatWarning(trimmedLine))
        case line.contains(BuildOutputIndicator.building):
            return .inProgress(logFormatter.formatBuildPhase(trimmedLine))
        case line.contains(BuildOutputIndicator.testSuite),
             line.contains(BuildOutputIndicator.testCase):
            return .inProgress(logFormatter.formatTestOutput(trimmedLine))
        case line.contains(BuildOutputIndicator.progress):
            return .inProgress(logFormatter.formatProgress(trimmedLine))
        case line.contains(BuildOutputIndicator.success):
            return .inProgress(logFormatter.formatSuccess(trimmedLine))
        default:
            return .inProgress(logFormatter.formatGeneric(trimmedLine))
        }
    }
}
