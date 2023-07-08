import Meow
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
            return try await req.meow[Todo.self] // Select collection
                .find() // Grab all todos
                .drain() // Put all results in an array
        }

        routes.delete { req -> HTTPStatus in
            try await req.meow[Todo.self] // Select collection
                .deleteAll { _ in
                    return [:] // Return no filters
                }

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

            // Create the new Todo using `Upsert`
            try await todo.save(in: req.meow)

            // Return the created Todo
            return todo
        }

        let todo = routes.grouped(":id")

        // Get Todo by ID
        todo.get { req -> Todo in
            // New Reference type ties the ID to a model
            let id: Reference<Todo> = try req.parameters.require("id")

            // Resolve and reutrn the model
            return try await id.resolve(in: req.meow)
        }

        // Gets and deletes a todo in a single operation
        todo.delete { req -> Todo in
            let id: Reference<Todo> = try req.parameters.require("id")

            // Get the TODO
            let todo = try await id.resolve(in: req.meow)

            // Delete the TODO
            try await id.deleteTarget(in: req.meow)

            // Return the original result
            return todo
        }

        // Overwrites all fields that are set, ignores existing fields
        todo.patch { req -> Todo in
            let id: Reference<Todo> = try req.parameters.require("id")
            let patchRequest = try req.content.decode(UpdateTodoDTO.self)

            try await req.meow[Todo.self].updateOne { todo in
                // Filters in Meow use a `.filter { entity in` like syntax
                // The first block is for filters
                // !! Make sure that you prefix your field to compare with a `$`
                todo.$_id == id
            } build: { todo in
                // The second block builds the change set
                if let title = patchRequest.title {
                    todo.setField(at: \.$title, to: title)
                }
                if let items = patchRequest.items {
                    todo.setField(at: \.$items, to: items)
                }
            }

            return try await id.resolve(in: req.meow)
        }
    }
}
