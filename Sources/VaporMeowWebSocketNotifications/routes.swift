import Vapor

func routes(_ app: Application) throws {
    try app.grouped("messages").register(collection: MessagesRoutes(meow: app.meow))
}
