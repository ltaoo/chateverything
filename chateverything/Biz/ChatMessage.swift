import Foundation

class ChatMessageBiz {
    var id: UUID
    var content: String
    var sender_id: String
    var created_at: Date
    var audio_url: String?
    
    init(id: UUID, content: String, sender_id: String, created_at: Date, audio_url: String? = nil, question_id: UUID? = nil) {
        self.id = id
        self.content = content
        self.sender_id = sender_id
        self.created_at = created_at
        self.audio_url = audio_url
    }
    
    static func from(_ entity: ChatMessageEntity) -> ChatMessageBiz? {
        guard let id = entity.id,
              let content = entity.content,
              let sender_id = entity.sender_id,
              let created_at = entity.created_at else {
            return nil
        }
        
        return ChatMessageBiz(id: id,
                          content: content,
                          sender_id: sender_id,
                          created_at: created_at,
                          audio_url: entity.audio_url)
    }
} 