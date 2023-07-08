import Meow

struct User: Model {
    // MongoDB can use almost any type for the _id.
    // In this example, the _id is their username
    // Note however, that _id can never change
    @Field var _id: String

    var username: String { _id }
}
