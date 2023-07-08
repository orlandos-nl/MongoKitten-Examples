import Meow
import Foundation

struct User: Model {
    @Field var _id: ObjectId
    @Field var email: String
    @Field var passwordHash: String
    @Field var lastLogin = Date()

    // if `true`, this user is banned from the platform and cannot log in
    @Field var isBanned = false
}
