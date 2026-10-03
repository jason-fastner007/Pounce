// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "native_auth",
    platforms: [.iOS("15.0"), .macOS("12.0")],
    products: [.library(name: "native-auth", targets: ["native_auth"])],
    dependencies: [.package(name: "FlutterFramework", path: "../FlutterFramework")],
    targets: [
        .target(
            name: "native_auth",
            dependencies: [.product(name: "FlutterFramework", package: "FlutterFramework")]
        )
    ]
)
