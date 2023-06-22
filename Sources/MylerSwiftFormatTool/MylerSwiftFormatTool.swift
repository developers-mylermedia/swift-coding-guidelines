import ArgumentParser
import Foundation

// MARK: - MylerSwiftFormatTool

/// A command line tool that formats the given directories using SwiftFormat, SwiftLint and SwiftGen,
/// based on the Myler Swift Style Guide
@main
struct MylerSwiftFormatTool: ParsableCommand {

  // MARK: Internal

  @Argument(help: "The directories to format")
  var directories: [String]

  @Option(help: "The absolute path to a SwiftFormat binary")
  var swiftFormatPath: String

  @Option(help: "The absolute path to use for SwiftFormat's cache")
  var swiftFormatCachePath: String?

  @Option(help: "The absolute path to a SwiftLint binary")
  var swiftLintPath: String

  @Option(help: "The absolute path to use for SwiftLint's cache")
  var swiftLintCachePath: String?

  @Option(help: "The absolute path to a SwiftGen binary")
  var swiftGenPath: String

  @Flag(help: "When true, source files are not reformatted")
  var lint = false

  @Flag(help: "When true, logs the commands that are executed")
  var log = false

  @Option(help: "The absolute path to the SwiftFormat config file")
  var swiftFormatConfig = Bundle.module.path(forResource: "default", ofType: "swiftformat")!

  @Option(help: "The absolute path to the SwiftLint config file")
  var swiftLintConfig = Bundle.module.path(forResource: "swiftlint", ofType: "yml")!

  @Option(help: "The absolute path to the SwiftLint config file")
  var swiftGenConfig: String?

  @Option(help: "The project's minimum Swift version")
  var swiftVersion: String?

  mutating func run() throws {

    // Separate running Swiftgen or the lint/formatting
    if swiftGenConfig != nil {
      runSwiftGen()
    } else {
      runFormatAndLint()
    }
  }

  private mutating func runFormatAndLint() throws {
    try swiftFormat.run()
    swiftFormat.waitUntilExit()

    try swiftLint.run()
    swiftLint.waitUntilExit()

    if log {
      log(swiftFormat.shellCommand)
      log(swiftLint.shellCommand)
      log("SwiftFormat ended with exit code \(swiftFormat.terminationStatus)")
      log("SwiftLint ended with exit code \(swiftLint.terminationStatus)")
    }

    if
      swiftFormat.terminationStatus == SwiftFormatExitCode.lintFailure ||
      swiftLint.terminationStatus == SwiftLintExitCode.lintFailure {
      throw ExitCode.failure
    }

    // Any other non-success exit code is an unknown failure
    if swiftFormat.terminationStatus != EXIT_SUCCESS {
      throw ExitCode(swiftFormat.terminationStatus)
    }

    if swiftLint.terminationStatus != EXIT_SUCCESS {
      throw ExitCode(swiftLint.terminationStatus)
    }
  }
  
  private mutating func runSwiftGen() throws {
     try swiftGen.run()
     swiftGen.waitUntilExit()

    if log {
      log(swiftGen.shellCommand)
      log("SwiftGen ended with exit code \(swiftGen.terminationStatus)")
    }

    if swiftGen.terminationStatus == SwiftGenExitCode.lintFailure {
      throw ExitCode.failure
    }

    if swiftGen.terminationStatus != EXIT_SUCCESS {
      throw ExitCode(swiftGen.terminationStatus)
    }
  }
  
  // MARK: Private

  private lazy var swiftFormat: Process = {
    var arguments = directories + [
      "--config", swiftFormatConfig,
    ]

    if let swiftFormatCachePath = swiftFormatCachePath {
      arguments += ["--cache", swiftFormatCachePath]
    }

    if lint {
      arguments += ["--lint"]
    }

    if let swiftVersion = swiftVersion {
      arguments += ["--swiftversion", swiftVersion]
    }

    let swiftFormat = Process()
    swiftFormat.launchPath = swiftFormatPath
    swiftFormat.arguments = arguments
    return swiftFormat
  }()

  private lazy var swiftLint: Process = {
    var arguments = directories + [
      "--config", swiftLintConfig,
      // Required for SwiftLint to emit a non-zero exit code on lint failure
      "--strict",
      // This flag is required when invoking SwiftLint from an SPM plugin, due to sandboxing
      "--in-process-sourcekit",
    ]

    if let swiftLintCachePath = swiftLintCachePath {
      arguments += ["--cache-path", swiftLintCachePath]
    }

    if !lint {
      arguments += ["--fix"]
    }

    let swiftLint = Process()
    swiftLint.launchPath = swiftLintPath
    swiftLint.arguments = arguments
    return swiftLint
  }()

  private lazy var swiftGen: Process = {
    // Unwrap this config to make sure its a [string] array instead of [any]
    guard let config = swiftGenConfig else { 
      return Process()
    }
    
    var arguments = directories + [
      "config", config,
    ]

    let swiftGen = Process()
    swiftGen.launchPath = swiftGenPath
    swiftGen.arguments = arguments
    return swiftGen
}()

  private func log(_ string: String) {
    // swiftlint:disable:next no_direct_standard_out_logs
    print("[MylerSwiftFormatTool]", string)
  }

}

extension Process {
  var shellCommand: String {
    let launchPath = launchPath ?? ""
    let arguments = arguments ?? []
    return "\(launchPath) \(arguments.joined(separator: " "))"
  }
}

// MARK: - SwiftFormatExitCode

/// Known exit codes used by SwiftFormat
enum SwiftFormatExitCode {
  static let lintFailure: Int32 = 1
}

// MARK: - SwiftLintExitCode

/// Known exit codes used by SwiftLint
enum SwiftLintExitCode {
  static let lintFailure: Int32 = 2
}

// MARK: - SwiftGetExitCode

/// Known exit codes used by SwiftGen
enum SwiftGenExitCode {
  static let lintFailure: Int32 = 1
}
