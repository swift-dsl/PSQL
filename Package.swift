// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PSQL",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PSQL",
            targets: ["PSQL"]
        ),
        .executable(
            name: "psqltest",
            targets: [
                "PSQLTestFlows",
            ]
        ),
    ],

    dependencies: [
        .package(url: "https://github.com/leviouwendijk/Primitives.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Registry.git", branch: "master"),
        // .package(url: "https://github.com/leviouwendijk/Indentation.git", branch: "master"),
        .package(
            url: "https://github.com/leviouwendijk/TestFlows.git",
            branch: "master"
        ),
    ],
    targets: [
        .target(
            name: "PSQL",
            dependencies: [
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Registry", package: "Registry"),
                // .product(name: "Indentation", package: "Indentation"),
            ],
        ),
        .executableTarget(
            name: "PSQLTestFlows",
            dependencies: [
                "PSQL",
                .product(
                    name: "TestFlows",
                    package: "TestFlows"
                ),
            ]
        ),
    ]
)
