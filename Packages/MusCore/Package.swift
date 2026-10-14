// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MusCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "MusCore", targets: ["MusCore"]),
    ],
    targets: [
        .target(name: "MusCore"),
        .testTarget(name: "MusCoreTests", dependencies: ["MusCore"]),
    ]
)
