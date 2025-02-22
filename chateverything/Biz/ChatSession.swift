import Foundation
import CoreData
import LLM


class ChatSessionConfig: ObservableObject {
    @Published var blurMsg: Bool
    @Published var autoSpeaking: Bool

    init(blurMsg: Bool, autoSpeaking: Bool) {
        self.blurMsg = blurMsg
        self.autoSpeaking = autoSpeaking
    }
}

class ChatSessionBiz: ObservableObject, Identifiable {
    let store: ChatStore

    let id: UUID
    @Published var created_at: Date
    @Published var updated_at: Date
    @Published var title: String
    @Published var avatar_uri: String
    @Published private(set) var boxes: [ChatBoxBiz] {
        willSet {
            objectWillChange.send()
        }
    }
    @Published var members: [ChatSessionMemberBiz]
    @Published var config: ChatSessionConfig

    var unreadCount: Int {
        return 0
    }
    static func create(role: RoleBiz, in store: ChatStore) -> ChatSessionBiz {
        let id = UUID()
        let created_at = Date()
        let updated_at = Date()
        let title = role.name
        let avatar_uri = role.avatar

        let ctx = store.container.viewContext
        let record = ChatSession(context: ctx)
        record.id = id
        record.created_at = created_at
        record.title = title
        record.avatar_uri = avatar_uri
        ctx.insert(record)
        try! ctx.save()

        let config = ChatSessionConfig(blurMsg: false, autoSpeaking: false)

        return ChatSessionBiz(id: id, created_at: created_at, updated_at: updated_at, title: title, avatar_uri: avatar_uri, boxes: [], members: [], config: config, store: store)
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
        let updated_at = record.updated_at ?? Date()
        let title = record.title ?? ""
        let avatar_uri = record.avatar_uri ?? ""
        let config = ChatSessionConfig(blurMsg: false, autoSpeaking: false)

        return ChatSessionBiz(
            id: id,
            created_at: created_at,
            updated_at: updated_at,
            title: title,
            avatar_uri: avatar_uri,
            boxes: [],
            members: [],
            config: config,
            store: store
        )
    }
    func load(id: UUID, config: Config) {
        let ctx = config.store.container.viewContext
        
        let req = NSFetchRequest<ChatSession>(entityName: "ChatSession")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let session = try! ctx.fetch(req).first!

        let role_req = NSFetchRequest<ChatSessionMember>(entityName: "ChatSessionMember")
        role_req.predicate = NSPredicate(format: "%K == %@", argumentArray: ["session_id", session.id ])
        let role_records = try! ctx.fetch(role_req)
        let members: [ChatSessionMemberBiz] = role_records.map {
            let r = ChatSessionMemberBiz.from($0, store: store)
            r.role = RoleBiz.Get(id: $0.role_id!, store: store)
            return r
        }
         let fetchBatchSize = 20
        let box_req = NSFetchRequest<ChatBox>(entityName: "ChatBox")
        box_req.predicate = NSPredicate(format: "session_id == %@", id as CVarArg)
        box_req.sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: true)]
        box_req.fetchBatchSize = fetchBatchSize
        box_req.fetchLimit = 20
        let box_records = try! ctx.fetch(box_req)
        let boxes: [ChatBoxBiz] = box_records.map {
            let box = ChatBoxBiz.from($0, store: store)
            // print("[BIZ]ChatSessionBiz.load: box: \(box.type) \(box.sender_id)")
            if box.sender_id == config.me.id {
                box.isMe = true
            }
            box.load(store: store)
            return box
        }

        // print("[BIZ]ChatSessionBiz.load: boxes: \(boxes.count)")

        self.created_at = session.created_at ?? Date()
        self.updated_at = session.updated_at ?? Date()
        self.title = session.title ?? ""
        self.avatar_uri = session.avatar_uri ?? ""
        self.boxes = boxes
        self.members = members
    }

    init(id: UUID, created_at: Date, updated_at: Date, title: String, avatar_uri: String, boxes: [ChatBoxBiz], members: [ChatSessionMemberBiz], config: ChatSessionConfig, store: ChatStore) {
        self.id = id
        self.created_at = created_at
        self.updated_at = updated_at
        self.title = title
        self.avatar_uri = avatar_uri
        self.boxes = boxes
        self.members = members
        self.config = config
        self.store = store
    }

    func setBoxes(boxes: [ChatBoxBiz]) {
        self.boxes = boxes
    }

    func append(box: ChatBoxBiz, completion: (([ChatBoxBiz]) -> Void)? = nil) {
        self.boxes.append(box)

        let ctx = self.store.container.viewContext
        let req = NSFetchRequest<ChatSession>(entityName: "ChatSession")
        req.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.id])
        let session = try! ctx.fetch(req).first!
        session.updated_at = Date()
        try! ctx.save()

        box.save(sessionId: self.id, store: self.store)
        completion?(self.boxes)
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
