import Meow
import Foundation

enum ChatMessageType: String, Codable {
    case global, privateChat
}

struct ChatMessage: Model {
    // Custom collection name
    static let collectionName = "messages"

    @Field var _id: ObjectId
    @Field var creator: Reference<User>
    @Field var createdAt: Date
    @Field var message: String
    @Field var type: ChatMessageType
    @Field var recipient: Reference<User>?
}
