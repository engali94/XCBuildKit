//
//  File.swift
//  XCBuildKit
//
//  Created by Ali Hilal on 02/11/2024.
//

import Foundation

// MARK: - Build State
/// Represents the current state of an Xcode build operation.
///
/// `BuildState` tracks the progress and outcome of build operations, providing
/// information about the current build phase, completion status, or any errors
/// that occurred during the build process.
///
/// ## States
/// The build can be in one of three states:
/// - In progress with a description of the current phase
/// - Completed successfully
/// - Failed with an error message
///
/// ## Example Usage
/// ```swift
/// var currentState: BuildState = .inProgress("Compiling Swift sources")
///
/// // Update state based on build progress
/// switch currentState {
/// case .inProgress(let phase):
///     print("Building:", phase)
/// case .completed:
///     print("Build completed successfully")
/// case .error(let message):
///     print("Build failed:", message)
/// }
/// ```
public enum BuildState: Equatable, Sendable {
    /// Indicates that the build is currently in progress.
    ///
    /// - Parameter String: A description of the current build phase or activity.
    case inProgress(String)
    
    /// Indicates that the build has completed successfully.
    case completed
    
    /// Indicates that the build failed with an error.
    ///
    /// - Parameter String: A description of what went wrong during the build.
    case error(String)
}
