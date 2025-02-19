import Foundation
import CoreData

// 首先需要导入相关类型
// import ChatMessage
// import ChatBox
// import Role
// import PersistenceController


class ChatSessionBiz {
    var id: UUID
    var created_at: Date
    var boxes: [ChatBoxBiz]
    var role: RoleBiz

    var name: String {
        get { role.name }
    }
    
    var avatar: String {
        get { role.avatar }
    }
    
    var lastMessageTime: Date {
        get { boxes.last?.created_at ?? Date() }
    }
    // var lastMessage: String {
    //     get { boxes.last?.content ?? "" }
    // }
    var unreadCount: Int {
	return 0
    }
    
    static func New(id: UUID) -> ChatSessionBiz? {
        // 获取 ViewContext
        let context = PersistenceController.container.viewContext
        
        // 创建获取请求
        let fetchRequest: NSFetchRequest<ChatSessionEntity> = ChatSessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            // 尝试获取匹配的会话
            if let entity = try context.fetch(fetchRequest).first {
                // 获取关联的 Role
                let roleFetch: NSFetchRequest<RoleEntity> = RoleEntity.fetchRequest()
                // Fix ambiguous type by explicitly creating UUID instance
                let userId = entity.user1_id ?? UUID()
                roleFetch.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
                if let role_entity = try? context.fetch(roleFetch).first,
                   let role = RoleBiz.from(role_entity) {
                    
                    // 转换消息和聊天框
                    let messages = entity.messagesArray.compactMap { ChatMessageBiz.from($0) }
                    let boxes = entity.chatBoxesArray.compactMap { ChatBoxBiz.from($0) }
                    
                    return ChatSessionBiz(
                        id: id,
                        created_at: entity.created_at ?? Date(),
                        boxes: boxes,
                        role: role
                    )
                }
            }
        } catch {
            print("Error fetching ChatSession: \(error)")
        }
        
	return nil
    }

    init(id: UUID, created_at: Date, boxes: [ChatBoxBiz], role: RoleBiz) {
        self.id = id
        self.created_at = created_at
        self.boxes = boxes
        self.role = role
    }
}
