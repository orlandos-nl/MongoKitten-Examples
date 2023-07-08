import Meow
import Vapor

// Allow `ChatMessage` to be returned by Vapor
extension ChatMessage: Content {}

struct CreateMessage: Content {
    // This is unsafe, and you should validate who the user is with tokens
    // But for the sake of example we trust them
    let currentUser: Reference<User>
    
    let message: String

    // The recipient if any. If not provided, the message is global
    let recipient: Reference<User>?
}

actor ChatListeners {
    static let shared = ChatListeners()
    private var listeners = [WebSocket]()

    func addSocket(_ socket: WebSocket) {
        listeners.append(socket)
    }

    func removeSocket(_ socket: WebSocket) {
        listeners.removeAll { $0 === socket }
    }

    func distributeMessage<E: Encodable>(_ message: E) async throws {
        let json = try JSONEncoder().encode(message)

        await withTaskGroup(of: Void.self) { taskGroup in
            for listener in listeners {
                taskGroup.addTask {
                    do {
                        // Send the message to this client
                        try await listener.send(raw: json, opcode: .text)
                    } catch {
                        // Client failed to receive the message, let's close their connection
                        // We don't care of closing throws an error for now
                        _ = try? await listener.close()
                    }
                }
            }

            await taskGroup.waitForAll()
        }
    }
}

struct MessagesRoutes: RouteCollection {
    let meow: MeowDatabase

    func boot(routes: RoutesBuilder) throws {
        // Index route
        routes.get { req in
            return try await req.meow[ChatMessage.self] // Select collection
                .find() // Grab all messages
                .sort(on: \.$createdAt, direction: .descending) // Sort the messages, recent first
                .limit(100) // Last 100 messages only
                .drain() // Put all results in an array
        }

        // Create new ChatMessage
        routes.post { req in
            let createRequest = try req.content.decode(CreateMessage.self)
            let message = ChatMessage(
                _id: ObjectId(), // Generate the id
                creator: createRequest.currentUser, // This is unsafe, but is done for example sake
                createdAt: Date(),
                message: createRequest.message,
                type: createRequest.recipient == nil ? .global : .privateChat,
                recipient: createRequest.recipient
            )

            // Create the new ChatMessage using `Upsert`
            try await message.save(in: req.meow)

            // Return the created ChatMessage
            return message
        }

        // Allow users to subscribe to the chat
        // This doesn't accept input, just emits output
        routes.webSocket { req, webSocket in
            await ChatListeners.shared.addSocket(webSocket)
            webSocket.onClose.whenComplete { _ in
                Task {
                    await ChatListeners.shared.removeSocket(webSocket)
                }
            }
        }

        Task {
            while !Task.isCancelled {
                do {
                    // We need to access the MongoKitten object to make a change stream
                    // Sometimes Meow doesn't provide the APIs directly yet.
                    let mongoKittenCollection = meow[ChatMessage.self].raw

                    let changeStream = try await mongoKittenCollection.buildChangeStream(
                        ofType: ChatMessage.self,
                        build: {
                            // Here we can filter for information we care about
                            Match<ChatMessage> { message in
                                message.$type == .global
                            }
                        }
                    )

                    let observationTask = changeStream.forEach { change in
                        // Change streams can observe _any_ change.
                        // Including `insert`, `delete` and `update`
                        switch change.operationType {
                        case .insert:
                            guard let message = change.fullDocument else {
                                // We need to forward the message
                                // So we're unwrapping it
                                break
                            }

                            do {
                                try await ChatListeners.shared.distributeMessage(message)
                            } catch {
                                // Error while sending a message, let's ignore these
                            }
                        default:
                            // We're currently only interested in `insert`
                            ()
                        }

                        // The change stream also stops when we return `false`
                        // We never want to stop however
                        return true
                    }

                    // This `forEach` task stops when the change stream is stopped, or a connection error occurs
                    // You'll want to restart the change strea when that happens
                    try await observationTask.value
                } catch {
                    // Error occured in the change stream, we should retry connection
                    // A small throttle will save resources in prolonged downtime
                    try await Task.sleep(for: .seconds(1))
                }
            }
        }
    }
}
