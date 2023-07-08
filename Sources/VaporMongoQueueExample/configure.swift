import Vapor
import Meow
import VaporSMTPKit

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory)){{#fluent}}

    // Connect to MongoDB, defaulting to localhost
    let mongodb = Environment.get("MONGODB") ?? "mongodb://localhost/meow-vapor-example"
    try app.initializeMongoDB(connectionString: mongodb)

    // Ensure users can't register duplicate email addresses
    // Note, in practice you need to account for case sensitivity etc
    try await app.meow[User.self].buildIndexes { user in
        UniqueIndex(named: "unique-email", field: user.$email)
    }

    // register routes
    try routes(app)
}

extension SMTPCredentials {
    static var `default`: SMTPCredentials {
        return SMTPCredentials(
            hostname: "smtp.example.com",
            ssl: .startTLS(configuration: .default),
            email: "noreply@example.com",
            password: "<SECRET>"
        )
    }
}
