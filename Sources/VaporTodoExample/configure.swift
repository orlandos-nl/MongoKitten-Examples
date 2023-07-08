import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory)){{#fluent}}

    // Connect to MongoDB, defaulting to localhost
    let mongodb = Environment.get("MONGODB") ?? "mongodb://localhost/mongokitten-vapor-example"
    try app.initializeMongoDB(connectionString: mongodb)

    // No need for migrations in MongoDB, unless you altered your data model
    
    // register routes
    try routes(app)
}
