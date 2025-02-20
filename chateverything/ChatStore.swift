import Foundation
import CoreData

// 聊天会话模型
// struct ChatSession: Identifiable, Codable {
//     let id: UUID
//     let name: String
//     let avatar: String
//     let lastMessage: String
//     let lastMessageTime: Date
//     var unreadCount: Int
//     var messageIds: [UUID] = []  // 只存储消息ID
//     let roleId: String
//     let modelId: String
    
//     enum CodingKeys: String, CodingKey {
//         case id, name, avatar, lastMessage, lastMessageTime, unreadCount, messageIds, roleId, modelId
//     }
    
//     init(name: String, avatar: String, lastMessage: String, lastMessageTime: Date, unreadCount: Int, messageIds: [UUID] = [], roleId: String, modelId: String) {
//         self.id = UUID()
//         self.name = name
//         self.avatar = avatar
//         self.lastMessage = lastMessage
//         self.lastMessageTime = lastMessageTime
//         self.unreadCount = unreadCount
//         self.messageIds = messageIds
//         self.roleId = roleId
//         self.modelId = modelId
//     }
// }

// // 问题结构
// struct Question: Identifiable, Codable, Equatable {
//     let id: UUID
//     let content: String
//     let options: [QuizOption]
//     var selectedAnswer: String?
//     var isCorrect: Bool?
    
//     init(content: String, options: [QuizOption], selectedAnswer: String? = nil, isCorrect: Bool? = nil) {
//         self.id = UUID()
//         self.content = content
//         self.options = options
//         self.selectedAnswer = selectedAnswer
//         self.isCorrect = isCorrect
//     }
// }

// 聊天消息模型
// public struct ChatMessage: Identifiable, Codable {
//     let id = UUID()
//     let content: String
//     let timestamp: Date
//     let isUser: Bool  // true表示用户消息，false表示AI回复

// }

// struct ChatMessage: Identifiable, Equatable, Codable {
//     let id = UUID()
//     let content: String
//     let isMe: Bool
//     let timestamp: Date
//     var nodes: [MsgTextNode]?
//     var audioURL: URL? 
//     var isBlurred: Bool 
//     var questionId: UUID?  // 引用问题ID而不是直接包含问题内容
    
//     init(content: String, isMe: Bool, timestamp: Date, nodes: [MsgTextNode]? = nil, audioURL: URL? = nil, questionId: UUID? = nil) {
//         self.content = content
//         self.isMe = isMe
//         self.timestamp = timestamp
//         self.nodes = nodes
//         self.audioURL = audioURL
//         self.isBlurred = !isMe
//         self.questionId = questionId
//     }
    
//     enum CodingKeys: String, CodingKey {
//         case id, content, isMe, timestamp, nodes, audioURL, isBlurred, questionId
//     }
    
//     init(from decoder: Decoder) throws {
//         let container = try decoder.container(keyedBy: CodingKeys.self)
//         id = try container.decode(UUID.self, forKey: .id)
//         content = try container.decode(String.self, forKey: .content)
//         isMe = try container.decode(Bool.self, forKey: .isMe)
//         timestamp = try container.decode(Date.self, forKey: .timestamp)
//         nodes = try container.decodeIfPresent([MsgTextNode].self, forKey: .nodes)
//         audioURL = try container.decodeIfPresent(URL.self, forKey: .audioURL)
//         isBlurred = try container.decode(Bool.self, forKey: .isBlurred)
//         questionId = try container.decodeIfPresent(UUID?.self, forKey: .questionId)
//     }
    
//     func encode(to encoder: Encoder) throws {
//         var container = encoder.container(keyedBy: CodingKeys.self)
//         try container.encode(id, forKey: .id)
//         try container.encode(content, forKey: .content)
//         try container.encode(isMe, forKey: .isMe)
//         try container.encode(timestamp, forKey: .timestamp)
//         try container.encodeIfPresent(nodes, forKey: .nodes)
//         try container.encodeIfPresent(audioURL, forKey: .audioURL)
//         try container.encode(isBlurred, forKey: .isBlurred)
//         try container.encodeIfPresent(questionId, forKey: .questionId)
//     }
// }

// extension ChatMessage {
//     static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
//         lhs.id == rhs.id &&
//         lhs.content == rhs.content &&
//         lhs.isMe == rhs.isMe &&
//         lhs.timestamp == rhs.timestamp &&
//         lhs.nodes == rhs.nodes &&
//         lhs.audioURL == rhs.audioURL &&
//         lhs.isBlurred == rhs.isBlurred &&
//         lhs.questionId == rhs.questionId
//     }
// } 

class ChatStore: ObservableObject {
    @Published var sessions: [ChatSessionBiz] = []
//    @Published var messages: [UUID: ChatMessageBiz] = [:]
//    @Published var questions: [UUID: ChatQuestionBiz] = [:]
    
    private let container: NSPersistentContainer
    private let sessionsKey = "chat_sessions"
    private let messagesKey = "chat_messages"
    private let questionsKey = "chat_questions"
    // private let context = PersistenceController.container.viewContext
    
    init(container: NSPersistentContainer) {
        self.container = container
        // container = NSPersistentContainer(name: "ChatEverything")
        // container.loadPersistentStores { description, error in
        //     if let error = error {
        //         print("Core Data failed to load: \(error.localizedDescription)")
        //     }
        // }
        
        // loadData()
    }
    
//     private func loadData() {
//         // Load sessions from Core Data
//         let request = NSFetchRequest<ChatSessionEntity>(entityName: "ChatSession")
        
//         do {
//             let sessions = try container.viewContext.fetch(request)
//             chatSessions = sessions.map { entity in
//                 ChatSession(
//                     id: entity.id ?? UUID(),
//                     name: entity.user1 ?? "",
//                     avatar: "",  // You might want to add this to Core Data as well
//                     lastMessage: "",
//                     lastMessageTime: entity.createdAt ?? Date(),
//                     unreadCount: 0,
//                     roleId: "",
//                     modelId: ""
//                 )
//             }
//         } catch {
//             print("Error loading chat sessions from Core Data: \(error)")
//         }
        
//         // Load messages and questions from UserDefaults as before
//         if let data = UserDefaults.standard.data(forKey: messagesKey) {
//             do {
//                 messages = try JSONDecoder().decode([UUID: ChatMessageEntity].self, from: data)
//             } catch {
//                 print("Error loading messages: \(error)")
//                 messages = [:]
//             }
//         }
        
//         if let data = UserDefaults.standard.data(forKey: questionsKey) {
//             do {
//                 questions = try JSONDecoder().decode([UUID: ChatQuestionEntity].self, from: data)
//             } catch {
//                 print("Error loading questions: \(error)")
//                 questions = [:]
//             }
//         }
//     }
    
    private func saveContext() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }

    func fetchSessions() {
        let request = NSFetchRequest<ChatSession>(entityName: "ChatSession")
        let sessions = try? container.viewContext.fetch(request)

        if sessions == nil {
            return
        }

        var result: [ChatSessionBiz] = []

        for session in sessions! {
            if let biz = ChatSessionBiz.from(id: session.id!, in: container.viewContext) {
                result.append(biz)
            }
        }

        self.sessions = result
    }

    func fetchSession(id: UUID) -> ChatSessionBiz? {
        let request = NSFetchRequest<ChatSession>(entityName: "ChatSession")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let session = try? container.viewContext.fetch(request).first
        return ChatSessionBiz.from(id: session!.id!, in: container.viewContext)
    }
    
    func addSession(id: UUID, user1_id: UUID, user2_id: UUID) {
        print("addSession: \(id), \(user1_id), \(user2_id)")

        //  guard let entity = NSEntityDescription.entity(forEntityName: "ChatSession", in: container.viewContext) else {
        //     fatalError("Failed to initialize ChatSessionEntity")
        // }

        // let newSession = ChatSession(entity: entity, insertInto: container.viewContext)
        // newSession.id = id
        // newSession.user1_id = user1_id
        // newSession.user2_id = user2_id
        // newSession.created_at = Date()
        
        // saveContext()
        
        // Update the published array
        // sessions.insert(session, at: 0)
    }
    
//     func deleteSession(at indexSet: IndexSet) {
//         // Delete from Core Data
//         let request = NSFetchRequest<ChatSessionEntity>(entityName: "ChatSession")
        
//         indexSet.forEach { index in
//             let sessionId = chatSessions[index].id
//             request.predicate = NSPredicate(format: "id == %@", sessionId as CVarArg)
            
//             do {
//                 let sessions = try container.viewContext.fetch(request)
//                 sessions.forEach { session in
//                     container.viewContext.delete(session)
//                 }
//                 try container.viewContext.save()
//             } catch {
//                 print("Error deleting session: \(error)")
//             }
//         }
        
//         // Update the published array
//         chatSessions.remove(atOffsets: indexSet)
//     }
    
//     func updateSession(_ session: ChatSession) {
//         if let index = chatSessions.firstIndex(where: { $0.id == session.id }) {
//             chatSessions[index] = session
//             saveContext()
//         }
//     }
    
//     func addMessage(_ message: ChatMessage, to sessionId: UUID) {
//         if let index = chatSessions.firstIndex(where: { $0.id == sessionId }) {
//             messages[message.id] = message
//             var session = chatSessions[index]
//             session.messageIds.append(message.id)
//             session.lastMessage = message.content
//             session.lastMessageTime = message.timestamp
//             chatSessions[index] = session
//             saveContext()
//         }
//     }
    
    func loadInitialSessions(limit: Int) {
        // let fetchRequest: NSFetchRequest<ChatSessionEntity> = ChatSessionEntity.fetchRequest()
        // fetchRequest.fetchLimit = limit
        // fetchRequest.sortDescriptors = [
        //     NSSortDescriptor(keyPath: \ChatSessionEntity.lastMessageTime, ascending: false)
        // ]
        
        // do {
        //     let results = try context.fetch(fetchRequest)
        //     self.chatSessions = results.map { entity in
        //         ChatSession(
        //             id: entity.id ?? UUID(),
        //             name: entity.name ?? "",
        //             avatar: entity.avatar ?? "person.circle.fill",
        //             lastMessage: entity.lastMessage ?? "",
        //             lastMessageTime: entity.lastMessageTime ?? Date(),
        //             unreadCount: Int(entity.unreadCount),
        //             messages: [], // 这里可以根据需要加载消息
        //             roleId: entity.roleId ?? "",
        //             modelId: entity.modelId ?? ""
        //         )
        //     }
        // } catch {
        //     print("Error loading chat sessions: \(error)")
        // }
    }
} 
