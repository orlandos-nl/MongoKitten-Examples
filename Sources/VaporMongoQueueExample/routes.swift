import Vapor

func routes(_ app: Application) throws {
    try app.grouped("auth").register(collection: AuthRoutes())
}
