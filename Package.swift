// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "NotchFlow",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "NotchFlow", targets: ["NotchFlow"])
    ],
    targets: [
        .executableTarget(
            name: "NotchFlow",
            path: "Sources"
        )
    ]
)
