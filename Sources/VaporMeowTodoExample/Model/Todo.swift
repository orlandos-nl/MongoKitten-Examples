import Meow

struct Todo: Model {
    @Field var _id: ObjectId
    @Field var title: String
    @Field var items: [String]
}
