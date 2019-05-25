// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Stride",
    platforms: [
      .macOS(.v10_13)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
      
        .executable(
            name: "Stride",
            targets: ["Stride"]),
        .library(
          name: "StrideLib",
          targets: ["StrideLib"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
      .package(url: "https://github.com/pmacro/Suit", .branch("master")),
      .package(url: "https://github.com/pmacro/SPMClient", .branch("master")),
      .package(url: "https://github.com/pmacro/Highlighter", .branch("master")),
      .package(url: "https://github.com/pmacro/LanguageClient", .branch("master")),
      .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Stride",
            dependencies: ["Suit", "StrideLib", "HighlighterRunner", "RxSwift"]),
        
        .target(
          name: "StrideLib",
          dependencies: ["Suit", "SPMClient", "Highlighter", "LanguageClient"]),
        
        .testTarget(
          name: "StrideTests",
          dependencies: ["StrideLib", "Suit", "SuitTestUtils", "SPMClient"],
          path: "Tests")
    ]
)
