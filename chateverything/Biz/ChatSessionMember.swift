import Foundation

class ChatSessionMemberBiz: ObservableObject, Identifiable {
    public var id: UUID
    public var name: String
    public var avatar: String

    public var role: RoleBiz?
    public var store: ChatStore

    static func Create(role: RoleBiz, session: ChatSessionBiz, in store: ChatStore)
        -> ChatSessionMemberBiz
    {
        let ctx = store.container.viewContext
        let record = ChatSessionMember(context: ctx)
        record.id = UUID()
        record.name = role.name
        record.avatar_uri = role.avatar
        record.role_id = role.id
        record.session_id = session.id
        ctx.insert(record)

        return ChatSessionMemberBiz(
            id: record.id!,
            name: role.name,
            avatar: role.avatar,
            store: store,
            role: role
        )
    }

    static func from(_ record: ChatSessionMember, store: ChatStore) -> ChatSessionMemberBiz {
        let id = record.id ?? UUID()
        let name = record.name ?? ""
        let avatar = record.avatar_uri ?? ""
        // let role = RoleBiz.from(record.role_id, store: store)

        return ChatSessionMemberBiz(
            id: id,
            name: name,
            avatar: avatar,
            store: store,
            role: nil
        )
    }

    init(id: UUID, name: String, avatar: String, store: ChatStore, role: RoleBiz?) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.store = store
        self.role = role
    }
}
