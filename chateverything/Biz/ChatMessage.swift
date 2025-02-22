import Foundation
import CoreData

class ChatMessageBiz {
    var id: UUID
    var content: String
    var box_id: UUID
    var created_at: Date
    var store: ChatStore
    
    init(id: UUID, content: String, box_id: UUID, created_at: Date, store: ChatStore) {
        self.id = id
        self.content = content
        self.box_id = box_id
        self.created_at = created_at
        self.store = store
    }
    
    static func from(_ entity: ChatMsgContent, store: ChatStore) -> ChatMessageBiz {
        let id = entity.id ?? UUID()
        let text = entity.text ?? ""
        let box_id = entity.box_id ?? UUID()
        let created_at = entity.created_at ?? Date()
        
        return ChatMessageBiz(id: id,
                          content: text,
                          box_id: box_id,
                          created_at: created_at,
                          store: store)
    }
} 
