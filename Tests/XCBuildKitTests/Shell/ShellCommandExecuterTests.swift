import XCTest
@testable import XCBuildKit

@MainActor
final class ShellCommandExecuterTests: XCTestCase {
    nonisolated(unsafe) var shellExecuter: ShellCommandExecuter!

    override func setUp() {
        super.setUp()
        shellExecuter = ShellCommandExecuter()
    }

    override func tearDown() {
        shellExecuter = nil
        super.tearDown()
    }

    // MARK: - Basic Command Tests

    func testEchoCommand() async throws {
        let output = shellExecuter.execute(arguments: ["echo", "Hello World"])
        var result = ""

        for try await line in output {
            if case .stdout(let data) = line {
                result += String(data: data, encoding: .utf8) ?? ""
            }
        }

        XCTAssertEqual(result.trimmingCharacters(in: .whitespacesAndNewlines), "Hello World")
    }

    func testCommandWithEnvironmentVariables() async throws {
        let env = ["TEST_VAR": "test_value"]
        let output = shellExecuter.execute(
            arguments: ["sh", "-c", "echo $TEST_VAR"],
            environment: env
        )

        var result = ""
        for try await line in output {
            if case .stdout(let data) = line {
                result += String(data: data, encoding: .utf8) ?? ""
            }
        }

        XCTAssertEqual(result.trimmingCharacters(in: .whitespacesAndNewlines), "test_value")
    }

    func testWorkingDirectoryChange() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let output = shellExecuter.execute(
            arguments: ["pwd"],
            workingDirectory: tempDir.path
        )

        var result = ""
        for try await line in output {
            if case .stdout(let data) = line {
                result += String(data: data, encoding: .utf8) ?? ""
            }
        }

        let pwdOutput = result.trimmingCharacters(in: .whitespacesAndNewlines)

        // On macOS, /var/folders is symlinked from /private/var/folders
        // Both paths should be considered valid
        let expectedPaths = [
            tempDir.path,
            "/private" + tempDir.path
        ]

        XCTAssertTrue(
            expectedPaths.contains(pwdOutput),
            "Expected pwd output '\(pwdOutput)' to match one of \(expectedPaths)"
        )
    }

    // MARK: - Error Handling Tests

    func testNonExistentCommand() async throws {
        let output = shellExecuter.execute(arguments: ["nonexistentcommand"])

        do {
            for try await _ in output { }
            XCTFail("Should have thrown an error")
        } catch let error as ShellError {
            if case .executableNotFound = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testCommandWithNonZeroExit() async throws {
        let output = shellExecuter.execute(arguments: ["sh", "-c", "exit 1"])

        do {
            for try await _ in output { }
            XCTFail("Should have thrown an error")
        } catch let error as ShellError {
            if case .nonZeroExit(code: 1, stderr: _) = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Output Stream Tests

    func testStdoutAndStderrOutput() async throws {
        let output = shellExecuter.execute(
            arguments: ["sh", "-c", "echo 'stdout'; echo 'stderr' >&2"]
        )

        var stdoutContent = ""
        var stderrContent = ""

        for try await line in output {
            switch line {
            case .stdout(let data):
                stdoutContent += String(data: data, encoding: .utf8) ?? ""
            case .stderr(let data):
                stderrContent += String(data: data, encoding: .utf8) ?? ""
            }
        }

        XCTAssertEqual(stdoutContent.trimmingCharacters(in: .whitespacesAndNewlines), "stdout")
        XCTAssertEqual(stderrContent.trimmingCharacters(in: .whitespacesAndNewlines), "stderr")
    }

    func testLargeOutput() async throws {
        let largeString = String(repeating: "a", count: 1000000)
        let output = shellExecuter.execute(
            arguments: ["echo", largeString]
        )

        var result = ""
        for try await line in output {
            if case .stdout(let data) = line {
                result += String(data: data, encoding: .utf8) ?? ""
            }
        }

        XCTAssertEqual(result.trimmingCharacters(in: .whitespacesAndNewlines), largeString)
    }

    // MARK: - Utility Method Tests

    func testStaticExecuteMethod() async throws {
        let output = ShellCommandExecuter.execute("echo", "Hello World")
        var result = ""

        for try await line in output {
            if case .stdout(let data) = line {
                result += String(data: data, encoding: .utf8) ?? ""
            }
        }

        XCTAssertEqual(result.trimmingCharacters(in: .whitespacesAndNewlines), "Hello World")
    }

    func testCollectOutput() async throws {
        let stdoutOutput = shellExecuter.execute(
            arguments: ["sh", "-c", "echo 'stdout message'; echo 'stderr message' >&2"]
        )

        let stdoutResult = try await stdoutOutput.collectOutput()
        XCTAssertEqual(
            stdoutResult.trimmingCharacters(in: .whitespacesAndNewlines),
            "stdout message"
        )
        XCTAssertFalse(stdoutResult.contains("stderr message"))

        let bothOutput = shellExecuter.execute(
            arguments: ["sh", "-c", "echo 'stdout message'; echo 'stderr message' >&2"]
        )

        let bothResult = try await bothOutput.collectOutput(includeStderr: true)
        XCTAssertTrue(bothResult.contains("stdout message"))
        XCTAssertTrue(bothResult.contains("stderr message"))

        // Test with multiple lines
        let multilineOutput = shellExecuter.execute(
            arguments: ["sh", "-c", "echo 'line1'; echo 'line2'; echo 'error' >&2"]
        )

        let multilineResult = try await multilineOutput.collectOutput(includeStderr: true)
        XCTAssertTrue(multilineResult.contains("line1"))
        XCTAssertTrue(multilineResult.contains("line2"))
        XCTAssertTrue(multilineResult.contains("error"))

        // Test with empty output
        let emptyOutput = shellExecuter.execute(
            arguments: ["sh", "-c", ""]
        )

        let emptyResult = try await emptyOutput.collectOutput()
        XCTAssertEqual(emptyResult.trimmingCharacters(in: .whitespacesAndNewlines), "")
    }

    func testCollectOutputWithRealCommands() async throws {
        let whichOutput = shellExecuter.execute(
            arguments: ["which", "ls"]
        )
        let whichResult = try await whichOutput.collectOutput()
        XCTAssertEqual(whichResult.trimmingCharacters(in: .whitespacesAndNewlines), "/bin/ls")

        let lsOutput = shellExecuter.execute(
            arguments: ["ls", "/bin"]
        )
        let lsResult = try await lsOutput.collectOutput()
        XCTAssertTrue(lsResult.contains("ls"))
        XCTAssertTrue(lsResult.contains("bash"))

        // should fail
        do {
            let errorOutput = shellExecuter.execute(
                arguments: ["ls", "/nonexistent"]
            )
            _ = try await errorOutput.collectOutput()
            XCTFail("Should have thrown an error")
        } catch let error as ShellError {
            if case .nonZeroExit(_, let stderr) = error {
                XCTAssertTrue(stderr.contains("No such file or directory"))
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        let findOutput = shellExecuter.execute(
            arguments: ["find", "/bin", "-name", "ls*", "-maxdepth", "1"]
        )
        let findResult = try await findOutput.collectOutput()
        XCTAssertTrue(findResult.contains("/bin/ls"))
        XCTAssertTrue(findResult.split(separator: "\n").count >= 1)

        let envOutput = shellExecuter.execute(
            arguments: ["sh", "-c", "echo $HOME"]
        )
        let envResult = try await envOutput.collectOutput()
        XCTAssertFalse(envResult.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    func testLargeOutputHandling() async throws {
        // generate 1MB of data
        let size = 1024 * 1024
        let output = shellExecuter.execute(
            arguments: ["dd", "if=/dev/zero", "bs=\(size)", "count=1"]
        )

        var dataSize = 0
        for try await line in output {
            if case .stdout(let data) = line {
                dataSize += data.count
            }
        }

        XCTAssertGreaterThanOrEqual(dataSize, size)
    }
}
