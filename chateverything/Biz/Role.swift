import Foundation
import CoreData

struct RoleSpeakerV1 {
    var id: String
    var engine: String
}
struct RoleModelV1 {
    var name: String
}

struct RoleSettingsV1 {
    var model: RoleModelV1
    var speaker: RoleSpeakerV1
    var temperature: Double
}
struct RoleSettingsV2 {
    var model: RoleModelV2
    var speaker: RoleSpeakerV2
}
struct RoleSpeakerV2 {
    var id: String
    var engine: String
}
struct RoleModelV2 {
    var name: String
    var apiProxyAddress: String
    var apiKey: String
}

struct RoleBiz: Identifiable {
    var id: UUID
    var name: String
    var avatar: String
    var prompt: String
    var settings: String
    var created_at: Date
    
    var roleSettings: RoleSettingsV2? {
        get {
            guard let data = settings.data(using: .utf8) else { return nil }
            
            // 先尝试解析 V2 版本
            if let v2Settings = try? JSONDecoder().decode(RoleSettingsV2.self, from: data) {
                return v2Settings
            }
            
            // 如果解析 V2 失败，尝试解析 V1 并升级到 V2
            if let v1Settings = try? JSONDecoder().decode(RoleSettingsV1.self, from: data) {
                // 将 V1 转换为 V2
                return RoleSettingsV2(
                    model: RoleModelV2(
                        name: v1Settings.model.name,
                        apiProxyAddress: "", // 设置默认值
                        apiKey: ""  // 设置默认值
                    ),
                    speaker: RoleSpeakerV2(
                        id: v1Settings.speaker.id,
                        engine: v1Settings.speaker.engine
                    )
                )
            }
            
            return nil
        }
    }
    
    mutating func saveSettings(_ settings: RoleSettingsV2) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(settings)
        if let jsonString = String(data: data, encoding: .utf8) {
            self.settings = jsonString
        }
    }
    
    static func from(_ entity: Role) -> RoleBiz? {
        let id = entity.id ?? UUID()
        let name = entity.name ?? ""
        let avatar = entity.avatar ?? ""
        let prompt = entity.prompt ?? ""
        let settings = entity.settings ?? ""
        let created_at = entity.created_at ?? Date()
        
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

extension RoleSettingsV1: Codable {}
extension RoleModelV1: Codable {}
extension RoleSpeakerV1: Codable {}

extension RoleSettingsV2: Codable {}
extension RoleModelV2: Codable {}
extension RoleSpeakerV2: Codable {} 