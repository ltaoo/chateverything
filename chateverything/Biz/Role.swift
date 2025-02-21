import Foundation
import CoreData
import LLM

public class RoleBiz: ObservableObject, Identifiable {
    public var id: UUID
    public var name: String
    public var description: String
    public var avatar: String
    public var prompt: String
    public var language: String
    public var voice: RoleVoice
    public var created_at: Date
    
    init(id: UUID, name: String, description: String, avatar: String, prompt: String, language: String, voice: RoleVoice, created_at: Date) {
        self.id = id
        self.name = name
        self.description = description
        self.avatar = avatar
        self.prompt = prompt
        self.language = language
        self.voice = voice
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
        // let settings = entity.settings ?? ""
        let created_at = entity.created_at ?? Date()
        
        return RoleBiz(
            id: id,
            name: name,
            description: "",
            avatar: avatar,
            prompt: prompt,
            language: "en-US",
            voice: RoleVoice(engine: "system", rate: 1, volume: 1, style: "normal", role: ""),
            created_at: created_at
        )
    }

    func updateSettings(provider: LanguageProvider, modelId: String) {
        // print("updateSettings \(provider.name) \(modelId)")
        // self.settings.update(model: RoleModelV2(
        //     name: modelId,
        //     apiProxyAddress: provider.apiProxyAddress,
        //     apiKey: provider.apiKey
        // ),
        // speaker: RoleSpeakerV2(id: "", engine: "system"),
        // extra: [:])
    }
}

// extension RoleSettingsV1: Codable {}
// extension RoleModelV1: Codable {}
// extension RoleSpeakerV1: Codable {}

// extension RoleModelV2: Codable {}
// extension RoleSpeakerV2: Codable {}

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

public struct RoleVoice {
    // 引擎，目前支持 QCloud、System
    var engine: String
    // 语速
    var rate: Double
    // 音量
    var volume: Double
    // 情感表现
    var style: String
    // 角色 id
    var role: String

    init(engine: String, rate: Double, volume: Double, style: String, role: String) {
        self.engine = engine
        self.rate = rate
        self.volume = volume
        self.style = style
        self.role = role
    }
}

public let DefaultRoles = [
    RoleBiz(
        id: UUID(),
        name: "雅思助教",
        description: "你是一个雅思助教，请根据学生的需求，给出相应的雅思学习建议。回复内容限制在100字以内。",
        avatar: "",
        prompt: "你是一个雅思助教，请根据学生的需求，给出相应的雅思学习建议。",
        language: "",
        voice: RoleVoice(engine: "system", rate: 1, volume: 1, style: "normal", role: ""),
        created_at: Date()
    ),
    RoleBiz(
        id: UUID(),
        name: "AI助手",
        description: "你是一个AI助手，请回答用户的问题。回复内容限制在100字以内。",
        avatar: "",
        prompt: "你是一个AI助手，请回答用户的问题。",
        language: "",
        voice: RoleVoice(engine: "system", rate: 1, volume: 1, style: "normal", role: ""),
        created_at: Date()
    )
]