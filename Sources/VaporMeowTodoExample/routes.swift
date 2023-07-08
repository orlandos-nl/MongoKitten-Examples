import Vapor

func routes(_ app: Application) throws {
    try app.grouped("todos").register(collection: TodoRoutes())
}
