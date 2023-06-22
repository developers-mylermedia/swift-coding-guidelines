// swift-tools-version: 5.6
import PackageDescription

let package = Package(
  name: "MylerSwift",
  platforms: [.macOS(.v10_13)],
  products: [
    .plugin(name: "FormatSwift", targets: ["FormatSwift"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.3"),
  ],
  targets: [
    .plugin(
      name: "FormatSwift",
      capability: .command(
        intent: .custom(
          verb: "format",
          description: "Formats Swift source files according to the Myler Swift Style Guide"),
        permissions: [
          .writeToPackageDirectory(reason: "Format Swift source files"),
        ]),
      dependencies: [
        "MylerSwiftFormatTool",
        "SwiftFormat",
        "SwiftLint",
        "SwiftGen",
      ]),

    .executableTarget(
      name: "MylerSwiftFormatTool",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      resources: [
        .process("default.swiftformat"),
        .process("swiftlint.yml"),
      ]),

    .binaryTarget(
      name: "SwiftFormat",
      url: "https://github.com/nicklockwood/SwiftFormat/releases/download/0.51.9/swiftformat.artifactbundle.zip",
      checksum: "544892fc9a6464d4bb5e0fc08f74c9b11a0937d73f7af64eafd9ada3b8a2aa7c"),

    .binaryTarget(
      name: "SwiftLint",
      url: "https://github.com/realm/SwiftLint/releases/download/0.48.0/SwiftLintBinary-macos.artifactbundle.zip",
      checksum: "9c255e797260054296f9e4e4cd7e1339a15093d75f7c4227b9568d63edddba50"),
    
    .binaryTarget(
        name: "SwiftGen",
        url: "https://github.com/SwiftGen/SwiftGen/releases/download/6.6.2/swiftgen-6.6.2.artifactbundle.zip",
        checksum: "7586363e24edcf18c2da3ef90f379e9559c1453f48ef5e8fbc0b818fbbc3a045"),
  ])

// Emit an error on Linux, so Swift Package Manager's platform support detection doesn't say this package supports Linux
// https://github.com/airbnb/swift/discussions/197#discussioncomment-4055303
#if os(Linux)
#error("Linux is currently not supported")
#endif
