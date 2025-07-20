// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WinMgr",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "WinMgr",
            targets: ["WinMgr"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "WinMgr",
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
            name: "WinMgrTests",
            dependencies: ["WinMgr"]
        ),
    ]
)