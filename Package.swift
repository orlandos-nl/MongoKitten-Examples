// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MongoKitten-Examples",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "VaporTodoExample", targets: ["VaporTodoExample"]),
        .executable(name: "VaporMeowTodoExample", targets: ["VaporMeowTodoExample"]),
        .executable(name: "VaporMeowWebSocketNotifications", targets: ["VaporMeowWebSocketNotifications"]),
        .executable(name: "VaporMongoQueueExample", targets: ["VaporMongoQueueExample"]),
    ],
    dependencies: [
        .package(url: "https://github.com/orlandos-nl/MongoKitten.git", from: "7.0.0"),
        .package(url: "https://github.com/orlandos-nl/MongoQueue.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        .package(url: "https://github.com/Joannis/VaporSMTPKit.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "VaporTodoExample",
            dependencies: [
                .product(name: "MongoKitten", package: "MongoKitten"),
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .executableTarget(
            name: "VaporMeowTodoExample",
            dependencies: [
                .product(name: "Meow", package: "MongoKitten"),
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .executableTarget(
            name: "VaporMeowWebSocketNotifications",
            dependencies: [
                .product(name: "Meow", package: "MongoKitten"),
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .executableTarget(
            name: "VaporMongoQueueExample",
            dependencies: [
                .product(name: "Meow", package: "MongoKitten"),
                .product(name: "MongoQueue", package: "MongoQueue"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "VaporSMTPKit", package: "VaporSMTPKit"),
            ]
        ),
    ]
)
