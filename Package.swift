// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AuthKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AuthKit", targets: ["AuthKit"])],
    targets: [
        .target(name: "AuthKit"),
        // Mocks and fixtures shared by both test targets
        .target(name: "AuthKitTestSupport", dependencies: ["AuthKit"], path: "Tests/AuthKitTestSupport"),
        // Swift Testing and XCTest live side by side
        .testTarget(name: "AuthKitTests", dependencies: ["AuthKit", "AuthKitTestSupport"]),
        .testTarget(name: "AuthKitXCTests", dependencies: ["AuthKit", "AuthKitTestSupport"]),
    ]
)
