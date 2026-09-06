// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GlossyGlass",
    platforms: [
        .iOS(.v17)
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
                "RELEASE-v3.md",
                "build-dylib.yml",
                "HOW-TO-UPLOAD.txt"
            ]
        )
    ]
)
