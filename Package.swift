// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GlossyGlass",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "GlossyGlass",
            type: .dynamic,
            targets: ["GlossyGlass"]
        )
    ],
    targets: [
        .target(
            name: "GlossyGlass",
            path: ".",
            exclude: [
                "Package.swift",
                "README.md",
                "OVERHAUL.md",
                "build-dylib.yml",
                ".github"
            ]
        )
    ]
)
