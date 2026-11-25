// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PSQLTests",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "psqltest",
            targets: [
                "PSQLTestFlows",
            ]
        ),
    ],

    dependencies: [
        // .package(url: "https://github.com/leviouwendijk/Indentation.git", branch: "master"),
        .package(
            url: "https://github.com/swift-tooling/TestFlows.git",
            branch: "master"
        ),
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "PSQLTestFlows",
            dependencies: [
                .product(name: "PSQL", package: "PSQL"),
                .product(
                    name: "TestFlows",
                    package: "TestFlows"
                ),
            ]
        ),
    ]
)
