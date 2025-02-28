import CoreData
import Foundation

public class ChatSessionConfig: ObservableObject {
    @Published var blurMsg: Bool
    @Published var autoSpeaking: Bool

    init(blurMsg: Bool, autoSpeaking: Bool) {
        self.blurMsg = blurMsg
        self.autoSpeaking = autoSpeaking
    }
}

public class ChatSessionBiz: ObservableObject, Equatable, Identifiable {
    let store: ChatStore

    public let id: UUID
    @Published var created_at: Date
    @Published var updated_at: Date
    @Published var title: String
    @Published var avatar_uri: String
    @Published private(set) var boxes: [ChatBoxBiz] = []
    @Published var members: [ChatSessionMemberBiz]
    @Published var config: ChatSessionConfig

    let helper = ListHelper(service: FetchBoxesOfSession)

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
        record.updated_at = updated_at
        record.title = title
        record.avatar_uri = avatar_uri
        ctx.insert(record)
        try! ctx.save()

        let config = ChatSessionConfig(blurMsg: false, autoSpeaking: false)

        return ChatSessionBiz(
            id: id, created_at: created_at, updated_at: updated_at, title: title,
            avatar_uri: avatar_uri, boxes: [], members: [], config: config, store: store)
    }
    static func delete(session: ChatSessionBiz, in store: ChatStore) {
        let ctx = store.container.viewContext

        // Delete all member records
        let memberReq = NSFetchRequest<ChatSessionMember>(entityName: "ChatSessionMember")
        memberReq.predicate = NSPredicate(format: "session_id == %@", session.id as CVarArg)
        if let members = try? ctx.fetch(memberReq) {
            for member in members {
                ctx.delete(member)
            }
        }

        // Delete all box payloads and boxes
        let boxReq = NSFetchRequest<ChatBox>(entityName: "ChatBox")
        boxReq.predicate = NSPredicate(format: "session_id == %@", session.id as CVarArg)
        if let boxes = try? ctx.fetch(boxReq) {
            for box in boxes {
                // Delete associated payload based on box type
                if let payloadId = box.payload_id {
                    let biz = ChatBoxBiz.from(box, store: store)
                    biz.deletePayload(store: store)
                }
                ctx.delete(box)
            }
        }

        // Delete the session record
        let sessionReq = NSFetchRequest<ChatSession>(entityName: "ChatSession")
        sessionReq.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
        if let sessionRecord = try? ctx.fetch(sessionReq).first {
            ctx.delete(sessionRecord)
            // Save changes
            try? ctx.save()
        }

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
        let session = try! ctx.fetch(req).first

        guard let session = session else {
            print("[BIZ]ChatSessionBiz.load: session not found")
            return
        }

        let role_req = NSFetchRequest<ChatSessionMember>(entityName: "ChatSessionMember")
        role_req.predicate = NSPredicate(
            format: "%K == %@", argumentArray: ["session_id", session.id])
        let member_records = try! ctx.fetch(role_req)
        let members: [ChatSessionMemberBiz] = member_records.map {
            let r = ChatSessionMemberBiz.from($0, store: store)
            let role = RoleBiz.Get(id: $0.role_id!, config: config)
            r.role = role
            if let r = role {
                r.load(config: config)
            }
            return r
        }
        self.members = members

        // 修改消息加载逻辑，只加载最新的消息
        helper.setParams(
            params: ListHelperParams(
                page: 1,
                pageSize: 1000,
                sorts: ["created_at": "desc"],
                search: ["session_id": session.id]
            )
        )
        let boxes = helper.load(config: config)

        let boxesPrepared = boxes.map {
            let box = ChatBoxBiz.from($0.box, store: store)
            if box.sender_id == config.me.id {
                box.isMe = true
            }
            box.load(payload: $0.payload, session: self, config: config)
            return box
        }

        DispatchQueue.main.async {
            self.boxes = boxesPrepared.reversed()
            // for box in boxesPrepared {
            //     self.boxes.insert(box, at: 0)
            // }
        }

        self.created_at = session.created_at ?? Date()
        self.updated_at = session.updated_at ?? Date()
        self.title = session.title ?? ""
        self.avatar_uri = session.avatar_uri ?? ""
    }

    func loadMoreMessages(config: Config) {
        let boxes = helper.loadMore(config: config)
        let boxesPrepared = boxes.map {
            let box = ChatBoxBiz.from($0.box, store: store)
            if box.sender_id == config.me.id {
                box.isMe = true
            }
            box.load(payload: $0.payload, session: self, config: config)
            return box
        }

        DispatchQueue.main.async {
            self.boxes = boxesPrepared.reversed() + self.boxes
        }
    }

    init(
        id: UUID, created_at: Date, updated_at: Date, title: String, avatar_uri: String,
        boxes: [ChatBoxBiz], members: [ChatSessionMemberBiz], config: ChatSessionConfig,
        store: ChatStore
    ) {
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
    func appendTmpBox(box: ChatBoxBiz) {
        print("[BIZ]ChatSessionBiz.appendTmpBox: \(box.type)")
        self.boxes.append(box)
    }
    func appendBox(box: ChatBoxBiz) {
        self.boxes.append(box)

        let ctx = self.store.container.viewContext
        let req = NSFetchRequest<ChatSession>(entityName: "ChatSession")
        req.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.id])
        let session = try! ctx.fetch(req).first
        guard let session = session else {
            print("[BIZ]ChatSessionBiz.append: session not found")
            return
        }
        session.updated_at = Date()
        try! ctx.save()

        box.save(sessionId: self.id, store: self.store)
    }
    func appendBoxes(boxes: [ChatBoxBiz], completion: (([ChatBoxBiz]) -> Void)? = nil) {
        for box in boxes {
            self.appendBox(box: box)
        }
        completion?(self.boxes)
    }
    func removeLastBox() {
        print("[BIZ]ChatSessionBiz.removeLastBox \(self.boxes.count)")
        if self.boxes.count > 0 {
            self.boxes.removeLast()
        }
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

    public static func == (lhs: ChatSessionBiz, rhs: ChatSessionBiz) -> Bool {
        return lhs.id == rhs.id
    }

    func getBoxesForMember(roleId: UUID, config: Config) -> [ChatBoxBiz] {
        return boxes.filter { box in
            (box.sender_id == roleId || box.sender_id == config.me.id)
                && (box.type == "message" || box.type == "audio")
        }.sorted { $0.created_at < $1.created_at }
    }
}
