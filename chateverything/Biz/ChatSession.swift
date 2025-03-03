import CoreData
import Foundation

public class ChatSessionConfig: ObservableObject {
    @Published var autoBlur: Bool
    @Published var autoSpeak: Bool
    @Published var stream: Bool

    init(autoBlur: Bool, autoSpeak: Bool, stream: Bool) {
        self.autoBlur = autoBlur
        self.autoSpeak = autoSpeak
        self.stream = stream
    }

    enum CodingKeys: String, CodingKey {
        case autoBlur = "auto_blur"
        case autoSpeak = "auto_speak"
        case stream
    }
}

struct ChatSessionCreatePayload {
    var title: String?
    var prompt: String?
    var roles: [RoleBiz]
}

public class ChatSessionBiz: ObservableObject, Equatable, Identifiable {
    let store: ChatStore

    public let id: UUID
    @Published var created_at: Date
    @Published var updated_at: Date
    @Published var title: String
    @Published var avatar_uri: String
    @Published var prompt: String?
    @Published private(set) var boxes: [ChatBoxBiz] = []
    @Published var members: [ChatSessionMemberBiz]
    @Published var config: ChatSessionConfig

    let helper = ListHelper(service: FetchBoxesOfSession)

    var unreadCount: Int {
        return 0
    }
    static func Create(payload: ChatSessionCreatePayload, in store: ChatStore) -> ChatSessionBiz? {
        //        guard let role1 = talker else {
        //            return nil
        //        }
        //        guard let role2 = me else {
        //            return nil
        //        }
        let talker = payload.roles[0]
        let me = payload.roles[1]

        let id = UUID()
        let created_at = Date()
        let updated_at = Date()
        let config: [String: Any] = [
            "auto_speak": talker.config.autoSpeak,
            "auto_blur": talker.config.autoBlur,
            "stream": talker.config.stream,
        ]

        let ctx = store.container.viewContext
        let record = ChatSession(context: ctx)

        record.id = id
        record.created_at = created_at
        record.updated_at = updated_at
        record.title = payload.title ?? talker.name
        record.avatar_uri = talker.avatar
        record.prompt = payload.prompt
        record.config = JSON.stringify(config)
        ctx.insert(record)

        let session = ChatSessionBiz(
            id: id,
            created_at: created_at,
            updated_at: updated_at,
            title: record.title!,
            avatar_uri: record.avatar_uri!,
            boxes: [],
            members: [],
            config: ChatSessionConfig(
                autoBlur: talker.config.autoBlur,
                autoSpeak: talker.config.autoSpeak,
                stream: talker.config.stream
            ),
            store: store
        )

        ChatSessionMemberBiz.Create(role: talker, session: session, in: store)
        ChatSessionMemberBiz.Create(role: me, session: session, in: store)

        do {
            try ctx.save()
            return session
        } catch {
            print(error)
        }

        return nil
    }
    static func Remove(session: ChatSessionBiz, in store: ChatStore) {
        let ctx = store.container.viewContext

        let sessionReq = NSFetchRequest<ChatSession>(entityName: "ChatSession")
        sessionReq.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
        if let sessionRecord = try? ctx.fetch(sessionReq).first {
            sessionRecord.hidden = true
            // Save changes
            try? ctx.save()
        }

        // Delete all member records
        // let memberReq = NSFetchRequest<ChatSessionMember>(entityName: "ChatSessionMember")
        // memberReq.predicate = NSPredicate(format: "session_id == %@", session.id as CVarArg)
        // if let members = try? ctx.fetch(memberReq) {
        //     for member in members {
        //         ctx.delete(member)
        //     }
        // }

        // // Delete all box payloads and boxes
        // let boxReq = NSFetchRequest<ChatBox>(entityName: "ChatBox")
        // boxReq.predicate = NSPredicate(format: "session_id == %@", session.id as CVarArg)
        // if let boxes = try? ctx.fetch(boxReq) {
        //     for box in boxes {
        //         // Delete associated payload based on box type
        //         if let payloadId = box.payload_id {
        //             let biz = ChatBoxBiz.from(box, store: store)
        //             biz.deletePayload(store: store)
        //         }
        //         ctx.delete(box)
        //     }
        // }

        // // Delete the session record
        // let sessionReq = NSFetchRequest<ChatSession>(entityName: "ChatSession")
        // sessionReq.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
        // if let sessionRecord = try? ctx.fetch(sessionReq).first {
        //     ctx.delete(sessionRecord)
        //     // Save changes
        //     try? ctx.save()
        // }

    }
    static func from(_ record: ChatSession, in store: ChatStore) -> ChatSessionBiz {
        let id = record.id ?? UUID()
        let created_at = record.created_at ?? Date()
        let updated_at = record.updated_at ?? Date()
        let title = record.title ?? ""
        let avatar_uri = record.avatar_uri ?? ""

        let config_data = JSON.parse(record.config ?? "{}") as? [String: Any] ?? [:]
        let autoBlur = config_data["auto_blur"] as? Bool ?? true
        let autoSpeak = config_data["auto_speak"] as? Bool ?? true
        let stream = config_data["stream"] as? Bool ?? true
        let config = ChatSessionConfig(autoBlur: autoBlur, autoSpeak: autoSpeak, stream: stream)

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
        self.created_at = session.created_at ?? Date()
        self.updated_at = session.updated_at ?? Date()
        self.title = session.title ?? ""
        self.avatar_uri = session.avatar_uri ?? ""
        self.prompt = session.prompt
        let config_str = session.config ?? "{}"
        let config_data = JSON.parse(config_str) as? [String: Any] ?? [:]
        self.config = ChatSessionConfig(
            autoBlur: config_data["auto_blur"] as? Bool ?? true,
            autoSpeak: config_data["auto_speak"] as? Bool ?? true,
            stream: config_data["stream"] as? Bool ?? true
        )

        print("preview the config \(self.config.autoBlur) \(self.config.autoSpeak) \(self.config.stream)")

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
                r.config.stream = self.config.stream
                // r.config.autoSpeak = self.config.autoSpeak
                // r.config.autoBlur = self.config.autoBlur
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
            box.load(record: $0.payload, session: self, config: config)
            return box
        }

            self.boxes = boxesPrepared.reversed()
            // for box in boxesPrepared {
            //     self.boxes.insert(box, at: 0)
            // }
    }

    func loadMoreMessages(config: Config) {
        let boxes = helper.loadMore(config: config)
        let boxesPrepared = boxes.map {
            let box = ChatBoxBiz.from($0.box, store: store)
            if box.sender_id == config.me.id {
                box.isMe = true
            }
            box.load(record: $0.payload, session: self, config: config)
            return box
        }

        DispatchQueue.main.async {
            self.boxes = boxesPrepared.reversed() + self.boxes
        }
    }

    init(
        id: UUID,
        created_at: Date,
        updated_at: Date,
        title: String,
        avatar_uri: String,
        boxes: [ChatBoxBiz],
        members: [ChatSessionMemberBiz],
        config: ChatSessionConfig,
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
