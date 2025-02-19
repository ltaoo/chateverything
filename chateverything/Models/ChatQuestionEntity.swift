import Foundation
import CoreData

@objc(ChatQuestion)
public class ChatQuestionEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var opt1: String?
    @NSManaged public var opt2: String?
    @NSManaged public var opt3: String?
    @NSManaged public var opt4: String?
    @NSManaged public var answer: String?
    @NSManaged public var created_at: Date?
    @NSManaged public var box_id: UUID?
    @NSManaged public var box: ChatBoxEntity?
}

extension ChatQuestionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatQuestionEntity> {
        return NSFetchRequest<ChatQuestionEntity>(entityName: "ChatQuestion")
    }
} 