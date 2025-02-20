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
struct RoleSettingsV2: Codable {
    var model: RoleModelV2
    var speaker: RoleSpeakerV2
    var extra: [String: AnyCodable]
    
    enum CodingKeys: String, CodingKey {
        case model, speaker, extra
    }
    
    // 提供访问 extra 的公共接口
    func getExtra() -> [String: Any] {
        return extra.mapValues { $0.value }
    }
    
    // 设置 extra 的方法
    mutating func setExtra(_ newExtra: [String: Any]) {
        self.extra = newExtra.mapValues { AnyCodable($0) }
    }
    
    // 初始化器
    init(model: RoleModelV2, speaker: RoleSpeakerV2, extra: [String: Any]) {
        self.model = model
        self.speaker = speaker
        self.extra = extra.mapValues { AnyCodable($0) }
    }
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


func parseSettings(settings: String) -> RoleSettingsV2 {
    let defaultSettings = RoleSettingsV2(
                model: RoleModelV2(
                    name: DefaultLanguageValue.selectedModels[0],
                    apiProxyAddress: DefaultLanguageValue.apiProxyAddress,
                    apiKey: DefaultLanguageValue.apiKey
                ),
                speaker: RoleSpeakerV2(id: "", engine: "system"),
                extra: [:]
            );

            guard let data = settings.data(using: .utf8) else { return defaultSettings }
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
                    ),
                    extra: [:]
                )
            }
            return defaultSettings
}

struct RoleBiz: Identifiable {
    var id: UUID
    var name: String
    var avatar: String
    var prompt: String
    var settings: RoleSettingsV2
    var created_at: Date
    
    // var settings: RoleSettingsV2? {
    //     get {
            
    //     }
    // }
    init(id: UUID, name: String, avatar: String, prompt: String, settings: RoleSettingsV2, created_at: Date) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.prompt = prompt
        self.settings = settings
        self.created_at = created_at
    }
    
    // mutating func saveSettings(_ settings: RoleSettingsV2) throws {
    //     let encoder = JSONEncoder()
    //     let data = try encoder.encode(settings)
    //     if let jsonString = String(data: data, encoding: .utf8) {
    //         self._settings = jsonString
    //     }
    // }
    
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
            settings: parseSettings(settings: settings),
            created_at: created_at
        )
    }
}

extension RoleSettingsV1: Codable {}
extension RoleModelV1: Codable {}
extension RoleSpeakerV1: Codable {}

extension RoleModelV2: Codable {}
extension RoleSpeakerV2: Codable {}

// AnyCodable 包装器
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
} 