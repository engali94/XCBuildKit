//
//  File.swift
//  XCBuildKit
//
//  Created by Ali Hilal on 02/11/2024.
//

import Foundation

/// A protocol that defines the interface for executing Xcode build operations.
///
/// Types conforming to `XcodeBuilding` provide functionality to execute various Xcode build
/// actions and stream their progress and results. This protocol serves as the primary
/// interface for initiating and monitoring build operations.
///
/// ## Example Usage
/// ```swift
/// let builder: XcodeBuilding = XcodeBuild()
/// let options = XcodeBuildOptions(scheme: "MyApp", project: "MyApp.xcodeproj")
///
/// // Execute a build and monitor its progress
/// for await state in builder.execute(.build, options: options) {
///     switch state {
///     case .inProgress(let phase):
///         print("Current phase:", phase)
///     case .completed:
///         print("Build completed successfully")
///     case .error(let message):
///         print("Build failed:", message)
///     }
/// }
/// ```
public protocol XcodeBuilding: Sendable {
    /// Executes an Xcode build action with the specified options.
    ///
    /// This method initiates a build operation and returns an asynchronous stream that
    /// emits build states, allowing callers to monitor the progress and outcome of the build.
    ///
    /// - Parameters:
    ///   - action: The ``XcodeBuildAction`` to execute.
    ///   - options: The ``XcodeBuildOptions`` configuring the build operation.
    ///
    /// - Returns: An `AsyncStream` that emits ``BuildState`` values indicating the
    ///           progress and status of the build operation.
    ///
    /// - Note: The stream will emit `.completed` when the build succeeds or `.error`
    ///         with a description if the build fails or is cancelled.
    func execute(_ action: XcodeBuildAction, options: XcodeBuildOptions) -> AsyncStream<BuildState>
}
