import Meow
import JWT
import Vapor

struct RegisterDTO: Content {
    let email: String
    let password: String
}

struct LoginDTO: Content {
    let email: String
    let password: String
}

struct AuthResponse: Content {
    let token: String
}

struct AuthRoutes: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("register") { req in
            let registerRequest = try req.content.decode(RegisterDTO.self)

            // Create the user model
            let user = User(
                _id: ObjectId(),
                email: registerRequest.email,
                passwordHash: try Bcrypt.hash(registerRequest.password)
            )

            // INSERT the user, which validates for a unique email address using the indexes
            try await user.create(in: req.meow)

            // Generate a token, which is valid for 1 hour
            let token = Token(sub: Reference(to: user))

            // Sign it, so they can use this to log in
            let jwt = try req.jwt.sign(token)

            // Return the token
            return AuthResponse(token: jwt)
        }

        routes.post("login") { req in
            let loginRequest = try req.content.decode(LoginDTO.self)

            guard var user = try await req.meow[User.self].findOne(matching: { user in
                user.$email == loginRequest.email && user.$isBanned == false
            }) else {
                throw Abort(.unauthorized)
            }

            // It's better to update properties using a query, rather than overriding them inline
            // That way you can handle changes from multiple routes in parallel without losing data
            // However, for small projects it's normally not an issue
            user.lastLogin = Date()

            try await user.save(in: req.meow)

            // Generate a token, which is valid for 1 hour
            let token = Token(sub: Reference(to: user))

            // Sign it, so they can use this to log in
            let jwt = try req.jwt.sign(token)

            // Return the token
            return AuthResponse(token: jwt)
        }
    }
}
