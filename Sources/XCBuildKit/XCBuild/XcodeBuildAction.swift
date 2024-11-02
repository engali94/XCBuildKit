//
//  File.swift
//  XCBuildKit
//
//  Created by Ali Hilal on 02/11/2024.
//

import Foundation

// MARK: - Xcode Build Action
/// Represents different actions that can be performed using the xcodebuild command-line tool.
///
/// `XcodeBuildAction` encapsulates various Xcode build commands and their associated parameters,
/// providing a type-safe way to specify build operations.
///
/// ## Example Usage
/// ```swift
/// // Simple build action
/// let buildAction: XcodeBuildAction = .build
///
/// // Test with a specific test plan
/// let testAction: XcodeBuildAction = .test(testPlan: "MyAppTests")
///
/// // List available schemes
/// let listAction: XcodeBuildAction = .list(.schemes)
/// ```
public enum XcodeBuildAction: Sendable {
    /// Builds the specified targets in the project.
    case build
    
    /// Builds and runs tests, optionally using a specific test plan.
    ///
    /// - Parameter testPlan: The name of the test plan to use, if any.
    case test(testPlan: String?)
    
    /// Builds the project and its tests without running them.
    case buildForTesting
    
    /// Runs tests without building the project first.
    case testWithoutBuilding
    
    /// Creates an archive of the built project.
    case archive
    
    /// Exports a previously created archive.
    case exportArchive
    
    /// Analyzes source code without building.
    case analyze
    
    /// Removes build artifacts and intermediate files.
    case clean
    
    /// Displays the build settings for the project.
    case showBuildSettings
    
    /// Shows code coverage information for the project.
    case showCodeCoverage
    
    /// Resolves and downloads Swift package dependencies.
    case resolvePackageDependencies
    
    /// Lists various project-related information.
    ///
    /// - Parameter ListType: The type of information to list.
    case list(ListType)
    
    /// Types of information that can be listed using xcodebuild.
    public enum ListType: Sendable {
        /// Lists all schemes in the project.
        case schemes
        
        /// Lists all available SDKs.
        case sdks
        
        /// Lists available destinations for a specific scheme.
        ///
        /// - Parameter scheme: The scheme name to list destinations for.
        case destinations(scheme: String)
        
        /// Lists available test plans for a specific scheme.
        ///
        /// - Parameter scheme: The scheme name to list test plans for.
        case testPlans(scheme: String)
    }
    
    /// The command-line argument representation of the action.
    ///
    /// This property converts the action into the corresponding xcodebuild command argument.
    var command: String {
        switch self {
        case .build: return "build"
        case .test: return "test"
        case .buildForTesting: return "build-for-testing"
        case .testWithoutBuilding: return "test-without-building"
        case .archive: return "archive"
        case .exportArchive: return "-exportArchive"
        case .analyze: return "analyze"
        case .clean: return "clean"
        case .showBuildSettings: return "-showBuildSettings"
        case .showCodeCoverage: return "-showCodeCoverage"
        case .resolvePackageDependencies: return "-resolvePackageDependencies"
        case .list(let type):
            switch type {
            case .schemes: return "-list"
            case .sdks: return "-showsdks"
            case .destinations: return "-showdestinations"
            case .testPlans: return "-showTestPlans"
            }
        }
    }
}
