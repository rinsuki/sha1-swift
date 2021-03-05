// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SHA1",
    products: [
        .library(name: "SHA1", targets: ["SHA1"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SHA1",
            path: "./Sources/"
        ),
    ]
)
