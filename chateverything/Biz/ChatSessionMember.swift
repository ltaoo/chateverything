import Foundation

class ChatSessionMemberBiz: ObservableObject, Identifiable {
    public var id: UUID
    public var name: String
    public var avatar: String

    public var role: RoleBiz?
    public var store: ChatStore

    init(id: UUID, name: String, avatar: String, store: ChatStore, role: RoleBiz?) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.store = store
        self.role = role
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
}