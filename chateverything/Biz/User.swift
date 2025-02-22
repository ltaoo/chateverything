import Foundation
import CoreData

struct UserBiz {
    var id: UUID
    var name: String
    var avatar: String
    var created_at: Date
    
    static func from(_ entity: User) -> UserBiz? {
        guard let id = entity.id,
              let name = entity.name,
              let avatar = entity.avatar,
              let created_at = entity.created_at else {
            return nil
        }
        
        return UserBiz(
            id: id,
            name: name,
            avatar: avatar,
            created_at: created_at
        )
    }
} 