import Foundation
import CoreData

@objc(ChatMessage)
public class ChatMessageEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var content: String?
    @NSManaged public var sender_id: String?
    @NSManaged public var created_at: Date?
    @NSManaged public var audio_url: String?
    @NSManaged public var box_id: UUID?
    @NSManaged public var box: ChatBoxEntity?
}

extension ChatMessageEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatMessageEntity> {
        return NSFetchRequest<ChatMessageEntity>(entityName: "ChatMessage")
    }
}

