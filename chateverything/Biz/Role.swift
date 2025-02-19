import Foundation

struct RoleBiz {
    var id: UUID
    var name: String
    var avatar: String
    var prompt: String
    var settings: String
    var created_at: Date
    
    static func from(_ entity: RoleEntity) -> RoleBiz? {
        guard let id = entity.id,
              let name = entity.name,
              let avatar = entity.avatar,
              let prompt = entity.prompt,
              let settings = entity.settings,
              let created_at = entity.created_at else {
            return nil
        }
        
        return RoleBiz(
            id: id,
            name: name,
            avatar: avatar,
            prompt: prompt,
            settings: settings,
            created_at: created_at
        )
    }
} 