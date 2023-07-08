import MongoKitten

struct Todo: Codable {
    let _id: ObjectId
    var title: String
    var items: [String]
}
