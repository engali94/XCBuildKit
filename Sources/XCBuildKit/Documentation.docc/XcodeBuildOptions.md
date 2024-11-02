# ``XCBuildKit/XcodeBuildOptions``

Configuration options for Xcode build operations.

## Overview

`XcodeBuildOptions` provides a comprehensive set of options for configuring various Xcode build operations, including building, testing, archiving, and exporting.

> Note: These options are only applicable when running on macOS, as they require the `xcodebuild` command-line tool.

## Topics

### Creating Build Options

- ``forBuild(project:scheme:configuration:sdk:destination:target:derivedDataPath:xcconfig:enableBitcode:parallelizeTargets:maximumActions:jobs:hideShellScript:extraArguments:)``
- ``forTesting(project:scheme:destination:testPlan:testConfiguration:testLanguage:testRegion:skipTesting:onlyTesting:testTargets:enableCodeCoverage:enableThreadSanitizer:enableAddressSanitizer:enableUndefinedBehaviorSanitizer:xcconfig:derivedDataPath:parallelizeTargets:maximumActions:jobs:hideShellScript:extraArguments:)``
- ``forArchive(project:scheme:configuration:archivePath:target:derivedDataPath:xcconfig:enableBitcode:parallelizeTargets:maximumActions:jobs:hideShellScript:allowProvisioningUpdates:extraArguments:)``
- ``forExport(project:scheme:exportOptions:allowProvisioningUpdates:extraArguments:)``

### Project Configuration

- ``project``
- ``scheme``
- ``target``
- ``configuration``
- ``workingDirectory``

### Build Settings

- ``sdk``
- ``destination``
- ``derivedDataPath``
- ``xcconfig`` 