import Foundation
import CoreData


struct ChatSessionBiz: Identifiable {
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
    
    static func from(id: UUID, in context: NSManagedObjectContext) -> ChatSessionBiz? {
        let viewContext = context
        
        // 获取 ChatSession
        let sessionRequest = NSFetchRequest<ChatSession>(entityName: "ChatSession")
        sessionRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let session = try! viewContext.fetch(sessionRequest).first!
        
        // 获取 Role
        let roleRequest = NSFetchRequest<Role>(entityName: "Role")
        roleRequest.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", session.user1_id ])
        let role = try! viewContext.fetch(roleRequest).first!
        let roleResult = RoleBiz.from(role)
        // print("roleResult: \(roleResult?.settings.model.name)")
        guard let roleResult = roleResult else {
            return nil
        }
        // 获取 ChatBoxes
        let boxRequest = NSFetchRequest<ChatBox>(entityName: "ChatBox")
        boxRequest.predicate = NSPredicate(format: "session_id == %@", id as CVarArg)
        boxRequest.sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: true)]
        boxRequest.fetchLimit = 20
        let boxes = try! viewContext.fetch(boxRequest)
        
        // 初始化消息数组
        // var initialMessages: [ChatMessage] = []
        let boxResult: [ChatBoxBiz] = []
        
        // 遍历 boxes 并加载对应的消息或问题
        for box in boxes {
            if box.type == "message" {
                // 获取 ChatMessage
                let messageRequest = NSFetchRequest<ChatMessage>(entityName: "ChatMessage")
                messageRequest.predicate = NSPredicate(format: "id == %@", box.payload_id as! any CVarArg as CVarArg)
                if let message = try! viewContext.fetch(messageRequest).first {
                    // initialMessages.append(message)
                }
            }
            if box.type == "question" {
                // 获取 ChatQuestion
                // let questionRequest = NSFetchRequest<ChatQuestion>(entityName: "ChatQuestion")
                // questionRequest.predicate = NSPredicate(format: "id == %@", box.content_id as CVarArg)
                // if let question = try! viewContext.fetch(questionRequest).first {
                //     // 将问题转换为消息格式
                //     let questionMessage = ChatMessage(
                //         content: question.content,
                //         isMe: false,
                //         timestamp: question.created_at,
                //         nodes: nil,
                //         audioURL: nil,
                //         quizOptions: question.options?.map { option in
                //             QuizOption(
                //                 text: option.text,
                //                 isCorrect: option.is_correct,
                //                 isSelected: false,
                //                 hasBeenSelected: false
                //             )
                //         },
                //         question: question.question
                //     )
                //     initialMessages.append(questionMessage)
                // }
            }
        }
        

        // 获取 ViewContext
        // let context = PersistenceController.container.viewContext
        
        // // 创建获取请求
        // let fetchRequest = ChatSessionEntity.fetchRequest()
        // fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        // do {
        //     // 尝试获取匹配的会话
        //     if let entity = try context.fetch(fetchRequest).first {
        //         // 获取关联的 Role
        //         let roleFetch = RoleEntity.fetchRequest()
        //         // Fix ambiguous type by explicitly creating UUID instance
        //         let userId = entity.user1_id ?? UUID()
        //         roleFetch.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        //         if let role_entity = try? context.fetch(roleFetch).first,
        //            let role = RoleBiz.from(role_entity) {
                    
        //             // 转换消息和聊天框
        //             let messages = entity.messagesArray.compactMap { ChatMessageBiz.from($0) }
        //             let boxes = entity.chatBoxesArray.compactMap { ChatBoxBiz.from($0) }
                    
        //             return ChatSessionBiz(
        //                 id: id,
        //                 created_at: entity.created_at ?? Date(),
        //                 boxes: boxes,
        //                 role: role
        //             )
        //         }
        //     }
        // } catch {
        //     print("Error fetching ChatSession: \(error)")
        // }
        
        return ChatSessionBiz(id: id, created_at: session.created_at ?? Date(), boxes: boxResult, role: roleResult)
    }

    init(id: UUID, created_at: Date, boxes: [ChatBoxBiz], role: RoleBiz) {
        self.id = id
        self.created_at = created_at
        self.boxes = boxes
        self.role = role
    }
}
