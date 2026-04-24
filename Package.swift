// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OracleXSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "OracleXSDK",
            targets: ["OracleXSDK"]
        )
    ],
    targets: [
        .target(
            name: "OracleXSDK",
            path: "Sources"
        )
    ]
)
