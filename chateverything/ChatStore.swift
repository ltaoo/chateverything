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
    
    public let container: NSPersistentContainer
    
    init(container: NSPersistentContainer) {
        self.container = container
    }

    func fetchSessions() {
        let ctx = container.viewContext
        let request = NSFetchRequest<ChatSession>(entityName: "ChatSession")
        request.sortDescriptors = [NSSortDescriptor(key: "updated_at", ascending: false)]
        request.fetchBatchSize = 20

        let sessions = try? ctx.fetch(request)

        var result: [ChatSessionBiz] = []

        for session in sessions! {
            let biz = ChatSessionBiz.from(session, in: self)

            let request = NSFetchRequest<ChatBox>(entityName: "ChatBox")
            request.predicate = NSPredicate(format: "%K == %@", argumentArray: ["session_id", session.id])
            request.sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: false)]
            request.fetchBatchSize = 1
            let boxes: [ChatBox] = try! ctx.fetch(request)
            let boxes2: [ChatBoxBiz] = boxes.map {
                let b = ChatBoxBiz.from($0, store: self)
                b.load(store: self)
                return b
            }
            biz.setBoxes(boxes: boxes2)

            result.append(biz)
        }

        self.sessions = result
    }

    func fetchSession(id: UUID) -> ChatSessionBiz? {
        let request = NSFetchRequest<ChatSession>(entityName: "ChatSession")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let session = try? container.viewContext.fetch(request).first
        guard let session = session else {
            return nil
        }
        return ChatSessionBiz.from(session, in: self)
    }
    
    func addSession(id: UUID, user1_id: UUID, user2_id: UUID) {
        print("addSession: \(id), \(user1_id), \(user2_id)")
    }
    
    func loadInitialSessions(limit: Int) {
    }
} 
