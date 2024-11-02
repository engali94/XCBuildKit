# ``XCBuildKit``

A Swift package for managing Xcode build operations with a type-safe API.

## Overview

XCBuildKit provides a comprehensive set of tools for executing and managing Xcode build operations programmatically. It offers type-safe APIs for configuring build settings, running tests, creating archives, and more.

> Important: XCBuildKit requires macOS as it interacts with the `xcodebuild` command-line tool.

## Platform Support

XCBuildKit is designed to run on:
- macOS 11.0 or later

## Topics

### Essentials

- ``XcodeBuild``
- ``XcodeBuildAction``
- ``XcodeBuildOptions``

### Build Configuration

- ``Destination``
- ``SDK``
- ``ArchivePath``
- ``ExportOptions``

### Build States

- ``BuildState``
- ``BuildLogFormatter``