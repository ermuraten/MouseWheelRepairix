// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "MouseWheelRepairix",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "MouseWheelRepairix", targets: ["MouseWheelRepairix"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MouseWheelRepairix",
            dependencies: [])
    ]
)
