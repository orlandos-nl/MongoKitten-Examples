import MongoKitten
import Vapor

// Allow `Todo` to be returned by Vapor
extension Todo: Content {}

struct CreateTodoDTO: Content {
    let title: String
    let items: [String]
}

struct UpdateTodoDTO: Content {
    let title: String?
    let items: [String]?
}

struct TodoRoutes: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        // Index route
        routes.get { req in
            return try await req.mongoDB["todos"] // Select collection
                .find() // Grab all todos
                .decode(Todo.self) // Decode into `Todo` Codable type
                .drain() // Put all results in an array
        }

        routes.delete { req -> HTTPStatus in
            try await req.mongoDB["todos"] // Select collection
                .deleteAll(where: [:]) // Delete with no filters will delete everything

            // No JSON response
            return .ok
        }

        // Create new Todo
        routes.post { req in
            let createRequest = try req.content.decode(CreateTodoDTO.self)
            let todo = Todo(
                _id: ObjectId(), // Generate the id
                title: createRequest.title,
                items: createRequest.items
            )

            // Create the new Todo
            try await req.mongoDB["todos"].insertEncoded(todo)

            // Return the created Todo
            return todo
        }

        let todo = routes.grouped(":id")

        // Get Todo by ID
        todo.get { req -> Todo in
            let id: ObjectId = try req.parameters.require("id")

            guard let todo = try await req.mongoDB["todos"] // Select collection
                .findOne("_id" == id, as: Todo.self) // Get Todo by id
            else {
                // Throw 404
                throw Abort(.notFound)
            }

            return todo
        }

        // Gets and deletes a todo in a single operation
        todo.delete { req -> Todo in
            let id: ObjectId = try req.parameters.require("id")

            let todoCollection = req.mongoDB["todos"] // Select collection
            guard let todo = try await todoCollection
                .findOneAndDelete(where: "_id" == id) // Find and delete the todo
                .decode(Todo.self) // Decode the deleted Todo
            else {
                // Todo with this ID didn't exist, so could not be deleted
                throw Abort(.notFound)
            }

            return todo
        }

        // Overwrites all fields that are set, ignores existing fields
        todo.patch { req -> Todo in
            let id: ObjectId = try req.parameters.require("id")
            let patchRequest = try req.content.decode(UpdateTodoDTO.self)

            // Make a document with only the changes
            var changedFields = Document()

            // Because `nil` values will be ignored, we can just add them as-is
            changedFields["title"] = patchRequest.title
            changedFields["items"] = try patchRequest.items.map(Document.init)

            guard
                // Updates
                let todo = try await req.mongoDB["todos"].findOneAndUpdate(
                    where: "_id" == id, // Selects a specific todo
                    to: [
                        "$set": changedFields // Overwrite fields
                    ],
                    returnValue: .modified // The result is the document _with_ changes (.modified)
                ).decode(Todo.self) // Decode the Todo
            else {
                // Todo with this ID didn't exist, so could not be deleted
                throw Abort(.notFound)
            }

            return todo
        }
    }
}
