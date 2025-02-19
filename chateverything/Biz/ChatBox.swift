import Foundation

class ChatBoxBiz {
    var id: UUID
    var type: String
    var payload_id: UUID
    var created_at: Date
    var session_id: UUID
    
    init(id: UUID, type: String, payload_id: UUID, created_at: Date, session_id: UUID) {
        self.id = id
        self.type = type
        self.payload_id = payload_id
        self.created_at = created_at
        self.session_id = session_id
    }
    
    static func from(_ entity: ChatBoxEntity) -> ChatBoxBiz? {
        guard let id = entity.id,
              let type = entity.type,
              let payload_id = entity.payload_id,
              let created_at = entity.created_at,
              let session_id = entity.session_id else {
            return nil
        }
        
        return ChatBoxBiz(id: id, 
                      type: type, 
                      payload_id: payload_id, 
                      created_at: created_at, 
                      session_id: session_id)
    }
} 