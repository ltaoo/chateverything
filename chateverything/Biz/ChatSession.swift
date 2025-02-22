import Foundation
import CoreData
import LLM


class ChatSessionBiz: ObservableObject, Identifiable {
    let store: ChatStore

    var id: UUID
    @Published var created_at: Date
    @Published var title: String
    @Published var avatar_uri: String
    @Published var boxes: [ChatBoxBiz]
    @Published var members: [ChatSessionMemberBiz]
    
    var lastMessageTime: Date {
        get { boxes.last?.created_at ?? Date() }
    }
    var unreadCount: Int {
        return 0
    }
    static func delete(session: ChatSessionBiz, in store: ChatStore) {
        let ctx = store.container.viewContext
        let req = NSFetchRequest<ChatSession>(entityName: "ChatSession")
        req.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
        let session = try! ctx.fetch(req).first!
        ctx.delete(session)
    }
    static func from(_ record: ChatSession, in store: ChatStore) -> ChatSessionBiz {
        let id = record.id ?? UUID()
        let created_at = record.created_at ?? Date()
        let title = record.title ?? ""
        let avatar_uri = record.avatar_uri ?? ""

        return ChatSessionBiz(
            id: id,
            created_at: created_at,
            title: title,
            avatar_uri: avatar_uri,
            boxes: [],
            members: [],
            store: store
        )
    }
    func load(id: UUID, in store: ChatStore) {
        let ctx = store.container.viewContext
        
        let req = NSFetchRequest<ChatSession>(entityName: "ChatSession")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let session = try! ctx.fetch(req).first!

        let role_req = NSFetchRequest<ChatSessionMember>(entityName: "ChatSessionMember")
        role_req.predicate = NSPredicate(format: "%K == %@", argumentArray: ["session_id", session.id ])
        let role_records = try! ctx.fetch(role_req)
        let members: [ChatSessionMemberBiz] = role_records.map { ChatSessionMemberBiz.from($0, store: store) }

        let box_req = NSFetchRequest<ChatBox>(entityName: "ChatBox")
        box_req.predicate = NSPredicate(format: "session_id == %@", id as CVarArg)
        box_req.sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: true)]
        box_req.fetchLimit = 20
        let box_records = try! ctx.fetch(box_req)
        let boxes: [ChatBoxBiz] = box_records.map { ChatBoxBiz.from($0, store: store) }

        self.created_at = session.created_at ?? Date()
        self.title = session.title ?? ""
        self.avatar_uri = session.avatar_uri ?? ""
        self.boxes = boxes
        self.members = members
    }

    init(id: UUID, created_at: Date, title: String, avatar_uri: String, boxes: [ChatBoxBiz], members: [ChatSessionMemberBiz], store: ChatStore) {
        self.id = id
        self.created_at = created_at
        self.title = title
        self.avatar_uri = avatar_uri
        self.boxes = boxes
        self.members = members
        self.store = store
    }

    func append(box: ChatBoxBiz) {
        box.save(sessionId: self.id, store: self.store);
        self.boxes.append(box)
    }

    func save() {
        let viewContext = self.store.container.viewContext
        
        let record = ChatSession(context: viewContext)
        record.id = self.id
        record.created_at = self.created_at
        // record.user1_id = self.role.id
        // record.user2_id = Config.shared.userId

        // 保存到 CoreData
        do {
            try viewContext.save()
        } catch {
            print("Error saving chat box: \(error)")
            return
        }
    }
}
