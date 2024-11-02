import XCTest
@testable import XCBuildKit

final class MockShellCommand: ShellCommandExecuting {
    nonisolated(unsafe) var executedCommands: [(arguments: [String], environment: [String: String], workingDirectory: String?)] = []
    nonisolated(unsafe) var outputToReturn: [ShellOutput] = []
    nonisolated(unsafe) var shouldThrow: Error?

    func execute(
        arguments: [String],
        environment: [String: String],
        workingDirectory: String?
    ) -> AsyncThrowingStream<ShellOutput, Error> {
        executedCommands.append((arguments, environment, workingDirectory))

        return AsyncThrowingStream { continuation in
            if let error = shouldThrow {
                continuation.finish(throwing: error)
                return
            }

            Task {
                for output in outputToReturn {
                    continuation.yield(output)
                }
                continuation.finish()
            }
        }
    }
}

final class XcodeBuildTests: XCTestCase {
    var shellCommand: MockShellCommand!
    var xcodeBuild: XcodeBuild!
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()
        shellCommand = MockShellCommand()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        xcodeBuild = XcodeBuild(
            shellCommand: shellCommand,
            logsPath: tempDirectory
        )
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        try await super.tearDown()
    }

    private func getCommandArguments() -> [String] {
        guard let command = shellCommand.executedCommands.first?.arguments[2] else {
            return []
        }

        let commandParts = command.components(separatedBy: " | ")
        let xcodeBuildCommand = commandParts[0]
            .replacingOccurrences(of: "set -o pipefail && ", with: "")
            .trimmingCharacters(in: .whitespaces)

        var arguments: [String] = []
        var currentArg = ""
        var insideQuotes = false

        for char in xcodeBuildCommand {
            if char == "'" {
                insideQuotes.toggle()
                continue
            }

            if char == " " && !insideQuotes {
                if !currentArg.isEmpty {
                    arguments.append(currentArg)
                    currentArg = ""
                }
            } else {
                currentArg.append(char)
            }
        }

        if !currentArg.isEmpty {
            arguments.append(currentArg)
        }

        return arguments
    }

    func testBasicBuild() async throws {
        let options = XcodeBuildOptions.forBuild(
            project: "MyApp",
            scheme: "MyApp",
            configuration: "Debug",
            sdk: .iPhoneSimulator,
            destination: .iOSSimulator(device: "iPhone 15"),
            parallelizeTargets: true
        )

        shellCommand.outputToReturn = [
            .stdout(Data("=== BUILD TARGET MyApp ===\n".utf8)),
            .stdout(Data("Build Succeeded\n".utf8))
        ]

        var states: [BuildState] = []
        let stream = xcodeBuild.execute(.build, options: options)

        for await state in stream {
            states.append(state)
        }

        let args = getCommandArguments()

        let expectedArgs = [
            "xcodebuild",
            "-project", "MyApp.xcodeproj",
            "-scheme", "MyApp",
            "-configuration", "Debug",
            "-sdk", "iphonesimulator",
            "-destination", "platform=iOS Simulator,name=iPhone 15",
            "-parallelizeTargets",
            "build"
        ]

        XCTAssertEqual(args, expectedArgs, "Command arguments don't match expected order")
    }

    func testTestAction() async throws {
        let options = XcodeBuildOptions.forTesting(
            project: "MyApp",
            scheme: "MyApp",
            destination: .iOSSimulator(device: "iPhone 15"),
            testPlan: "MyTestPlan",
            testConfiguration: "MyConfig",
            testLanguage: "en",
            testRegion: "US",
            skipTesting: ["SkipThisTest"],
            onlyTesting: ["OnlyThisTest", "MyAppTests"],
            testTargets: []
        )

        shellCommand.outputToReturn = [
            .stdout(Data("Test Suite 'MyAppTests' started\n".utf8)),
            .stdout(Data("Test Case '-[MyAppTests testExample]' started\n".utf8)),
            .stdout(Data("Test Case '-[MyAppTests testExample]' passed\n".utf8))
        ]

        var states: [BuildState] = []
        let stream = xcodeBuild.execute(.test(testPlan: "MyTestPlan"), options: options)

        for await state in stream {
            states.append(state)
        }

        let args = getCommandArguments()
        let expectedArgs = [
            "xcodebuild",
            "-project", "MyApp.xcodeproj",
            "-scheme", "MyApp",
            "-destination", "platform=iOS Simulator,name=iPhone 15",
            "-testPlan", "MyTestPlan",
            "-testConfiguration", "MyConfig",
            "-testLanguage", "en",
            "-testRegion", "US",
            "-skip-testing:SkipThisTest",
            "-only-testing:OnlyThisTest",
            "-only-testing:MyAppTests",
            "-enableCodeCoverage", "YES",
            "test"
        ]

        XCTAssertEqual(args, expectedArgs, "Command arguments don't match expected order")
    }

    func testArchiveAction() async throws {
        let archivePath = try ArchivePath("path/to/archive.xcarchive")

        let options = XcodeBuildOptions.forArchive(
            project: "MyApp",
            scheme: "MyApp",
            configuration: "Release",
            archivePath: archivePath,
            target: nil,
            derivedDataPath: "/path/to/derived/data",
            xcconfig: nil,
            enableBitcode: true,
            parallelizeTargets: false,
            maximumActions: nil,
            jobs: nil,
            hideShellScript: false,
            allowProvisioningUpdates: false,
            extraArguments: []
        )

        shellCommand.outputToReturn = [
            .stdout(Data("=== ARCHIVE TARGET MyApp ===\n".utf8)),
            .stdout(Data("Archive Succeeded\n".utf8))
        ]

        var states: [BuildState] = []
        let stream = xcodeBuild.execute(.archive, options: options)

        for await state in stream {
            states.append(state)
        }

        let args = getCommandArguments()
        let expectedArgs = [
            "xcodebuild",
            "-project", "MyApp.xcodeproj",
            "-scheme", "MyApp",
            "-configuration", "Release",
            "-sdk", "iphoneos",
            "-derivedDataPath", "/path/to/derived/data",
            "-archivePath", "path/to/archive.xcarchive",
            "ENABLE_BITCODE=YES",
            "archive"
        ]

        XCTAssertEqual(args, expectedArgs, "Command arguments don't match expected order")
    }

    func testArchiveWithoutPath() async throws {
        XCTAssertThrowsError(try ArchivePath("")) { error in
            XCTAssertEqual(
                error.localizedDescription,
                "Archive path cannot be empty"
            )
        }
    }

    func testExportArchiveWithMissingOptions() async throws {
        XCTAssertThrowsError(try ExportOptions(
            archivePath: "/path/to/archive",
            exportPath: "",  // this should throw
            optionsPlist: "" // this should throw
        ))

        let archivePath = try ArchivePath("/path/to/archive")
        let options = XcodeBuildOptions.forArchive(
            project: "MyApp",
            scheme: "MyApp",
            configuration: "Release",
            archivePath: archivePath,
            allowProvisioningUpdates: true
        )

        let stream = xcodeBuild.execute(.exportArchive, options: options)
        var states: [BuildState] = []

        for await state in stream {
            states.append(state)
        }

        XCTAssertTrue(states.contains(where: { state in
            if case .error(let message) = state {
                return message.contains("Export options are required for export")
            }
            return false
        }))
    }

}
