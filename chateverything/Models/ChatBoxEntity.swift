import Foundation
import CoreData

@objc(ChatBoxEntity)
public class ChatBoxEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var payload_id: UUID?
    @NSManaged public var created_at: Date?
    @NSManaged public var session_id: UUID?
    @NSManaged public var session: ChatSessionEntity?
}

extension ChatBoxEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatBoxEntity> {
        return NSFetchRequest<ChatBoxEntity>(entityName: "ChatBox")
    }
}
