// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ConvEngineChat",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "ConvEngineChat", targets: ["ConvEngineChat"])
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.1")
    ],
    targets: [
        .target(
            name: "ConvEngineChat",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui")
            ],
            path: "Sources/ConvEngineChat"
        ),
        .testTarget(
            name: "ConvEngineChatTests",
            dependencies: ["ConvEngineChat"],
            path: "Tests/ConvEngineChatTests"
        )
    ]
)
