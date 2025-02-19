import Foundation
import CoreData

@objc(ChatSessionEntity)
public class ChatSessionEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var user1_id: UUID?
    @NSManaged public var user2_id: UUID?
    @NSManaged public var created_at: Date?
    @NSManaged public var messages: NSSet?
    @NSManaged public var chatBoxes: NSSet?
}

extension ChatSessionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatSessionEntity> {
        return NSFetchRequest<ChatSessionEntity>(entityName: "ChatSession")
    }
    
    // 便利属性，将 messages 转换为数组
    public var messagesArray: [ChatMessageEntity] {
        let set = messages as? Set<ChatMessageEntity> ?? []
        return set.sorted { $0.created_at ?? Date() < $1.created_at ?? Date() }
    }
    
    // 便利属性，将 chatBoxes 转换为数组
    public var chatBoxesArray: [ChatBoxEntity] {
        let set = chatBoxes as? Set<ChatBoxEntity> ?? []
        return set.sorted { $0.created_at ?? Date() < $1.created_at ?? Date() }
    }
    
    // 便利方法，添加新消息
    public func addMessage(_ message: ChatMessageEntity) {
        addToMessages(message)
    }
    
    // 便利方法，移除消息
    public func removeMessage(_ message: ChatMessageEntity) {
        removeFromMessages(message)
    }
    
    // 便利方法，添加新的 ChatBox
    public func addChatBox(_ chatBox: ChatBoxEntity) {
        addToChatBoxes(chatBox)
    }
    
    // 便利方法，移除 ChatBox
    public func removeChatBox(_ chatBox: ChatBoxEntity) {
        removeFromChatBoxes(chatBox)
    }
}

// MARK: Generated accessors for messages
extension ChatSessionEntity {
    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: ChatMessageEntity)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: ChatMessageEntity)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)
}

// MARK: Generated accessors for chatBoxes
extension ChatSessionEntity {
    @objc(addChatBoxesObject:)
    @NSManaged public func addToChatBoxes(_ value: ChatBoxEntity)

    @objc(removeChatBoxesObject:)
    @NSManaged public func removeFromChatBoxes(_ value: ChatBoxEntity)

    @objc(addChatBoxes:)
    @NSManaged public func addToChatBoxes(_ values: NSSet)

    @objc(removeChatBoxes:)
    @NSManaged public func removeFromChatBoxes(_ values: NSSet)
} 