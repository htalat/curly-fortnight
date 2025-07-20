// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AXWindowMgr",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "AXWindowMgr",
            targets: ["AXWindowMgr"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "AXWindowMgr",
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .enableExperimentalFeature("BitwiseCopyable"),
                .enableExperimentalFeature("GlobalConcurrency"),
                .enableExperimentalFeature("IsolatedAny"),
                .enableExperimentalFeature("MoveOnlyClasses"),
                .enableExperimentalFeature("MoveOnlyEnumDeinits"),
                .enableExperimentalFeature("MoveOnlyPartialConsumption"),
                .enableExperimentalFeature("MoveOnlyResilientTypes"),
                .enableExperimentalFeature("MoveOnlyTuples"),
                .enableExperimentalFeature("NoncopyableGenerics"),
                .enableExperimentalFeature("RegionBasedIsolation"),
                .enableExperimentalFeature("TransferringArgsAndResults"),
                .enableExperimentalFeature("VariadicGenerics"),
            ]
        ),
        .testTarget(
            name: "AXWindowMgrTests",
            dependencies: ["AXWindowMgr"]
        ),
    ]
)