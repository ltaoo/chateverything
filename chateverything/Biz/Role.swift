import Foundation
import CoreData
import LLM

public class RoleBiz: ObservableObject, Identifiable {
    public var id: UUID
    public var name: String
    public var desc: String
    public var avatar: String
    public var prompt: String
    public var language: String
    public var voice: RoleVoice
    public var created_at: Date

    init(id: UUID, name: String, desc: String, avatar: String, prompt: String, language: String, voice: RoleVoice, created_at: Date) {
        self.id = id
        self.name = name
        self.desc = desc
        self.avatar = avatar
        self.prompt = prompt
        self.language = language
        self.voice = voice
        self.created_at = created_at

        // let matchedProvider = Config.shared.languageProviders.first!
        // let llm = LLMService(
        //     value: LLMValues(provider: matchedProvider.name, model: matchedProvider.models.first!.name ?? "", apiProxyAddress: matchedProvider.apiProxyAddress, apiKey: matchedProvider.apiKey),
        //     prompt: ""
        // )
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
        let avatar = entity.avatar_uri ?? ""
        let prompt = entity.prompt ?? ""
        // let settings = entity.settings ?? ""
        let created_at = entity.created_at ?? Date()
        
        return RoleBiz(
            id: id,
            name: name,
            desc: "",
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

public let defaultRoleVoice = RoleVoice(engine: "system", rate: 1, volume: 1, style: "normal", role: "")

public class RoleVoice: ObservableObject {
    // 引擎，目前支持 QCloud、System
    @Published var engine: String
    // 语速
    @Published var rate: Double
    // 音量
    @Published var volume: Double
    // 情感表现
    @Published var style: String
    // 角色 id
    @Published var role: String

    static func GetDefault() -> RoleVoice {
        return defaultRoleVoice
    }

    init(engine: String, rate: Double, volume: Double, style: String, role: String) {
        self.engine = engine
        self.rate = rate
        self.volume = volume
        self.style = style
        self.role = role
    }
}


public let DefaultRoles: [RoleBiz] = [
    RoleBiz(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "雅思助教",
        desc: "你是一个雅思助教，请根据学生的需求，给出相应的雅思学习建议。回复内容限制在100字以内。",
        avatar: "https://static.funzm.com/chateverything/avatars/avatar7.jpeg",
        prompt: "你是一个雅思助教，请根据学生的需求，给出相应的雅思学习建议。",
        language: "en-US",
        voice: defaultRoleVoice,
        created_at: Date()
    ),
    RoleBiz(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "AI助手",
        desc: "你是一个AI助手，请回答用户的问题。回复内容限制在100字以内。",
        avatar: "https://static.funzm.com/chateverything/avatars/avatar6.jpeg",
        prompt: "你是一个AI助手，请回答用户的问题。",
        language: "en-US",
        voice: defaultRoleVoice,
        created_at: Date()
    ),
    RoleBiz(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "英语口语教练",
        desc: "专业的英语口语教练，帮助你提升口语表达能力，纠正发音问题，提供地道的表达方式。",
        avatar: "https://static.funzm.com/chateverything/avatars/avatar1.jpeg",
        prompt: "你是一位经验丰富的英语口语教练。你需要：1. 帮助学生提升口语表达能力 2. 纠正发音错误 3. 教授地道的英语表达方式 4. 模拟真实对话场景 5. 给出详细的改进建议。请用简单友好的方式与学生交流。",
        language: "en-US",
        voice: defaultRoleVoice,
        created_at: Date()
    ),
    RoleBiz(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        name: "日语会话伙伴",
        desc: "友好的日语会话伙伴，帮助你练习日常对话，学习日本文化，提高日语水平。",
        avatar: "https://static.funzm.com/chateverything/avatars/avatar2.jpeg",
        prompt: "あなたは親切な日本語会話パートナーです。学習者の日本語レベルに合わせて、簡単な日常会話から高度な議論まで対応できます。日本の文化や習慣についても説明し、自然な日本語の使い方を教えてください。",
        language: "ja-JP",
        voice: defaultRoleVoice,
        created_at: Date()
    ),
    RoleBiz(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
        name: "托福备考指导",
        desc: "专业的托福考试指导老师，提供备考策略，讲解考试技巧，助你获得理想分数。",
        avatar: "https://static.funzm.com/chateverything/avatars/avatar3.jpeg",
        prompt: "你是一位经验丰富的托福考试指导老师。你需要：1. 根据学生的目标分数制定学习计划 2. 讲解各个科目的考试技巧 3. 分析真题并提供详细解答 4. 指出常见错误并给出改进建议 5. 提供高效的备考方法。请用专业且易懂的方式回答问题。",
        language: "en-US",
        voice: defaultRoleVoice,
        created_at: Date()
    ),
    RoleBiz(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
        name: "西班牙语老师",
        desc: "热情的西班牙语教师，教授地道的西班牙语，带你了解西语国家的文化。",
        avatar: "https://static.funzm.com/chateverything/avatars/avatar4.jpeg",
        prompt: "Eres un profesor de español entusiasta y paciente. Tu objetivo es: 1. Enseñar español de manera natural y efectiva 2. Explicar la gramática de forma clara 3. Compartir conocimientos sobre la cultura hispana 4. Practicar conversación 5. Corregir errores con amabilidad. Por favor, adapta tu nivel de español según el estudiante.",
        language: "es-ES",
        voice: defaultRoleVoice,
        created_at: Date()
    )
]