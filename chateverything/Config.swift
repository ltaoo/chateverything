import Foundation
import LLM

public enum Route: Hashable {
    case ChatDetailView(sessionId: UUID)
    case VocabularyView(filepath: String)
    case RoleDetailView(roleId: UUID)
}


public class ProviderModelValue: Identifiable, Codable {
    public var id: String { name }
    var name: String
    var enabled: Bool = true
    
    enum CodingKeys: String, CodingKey {
        case name
        case enabled
    }

    public init(name: String, enabled: Bool) {
        self.name = name
        self.enabled = enabled
    }

    public func toggle(value: Bool) {
        enabled = value
    }
}

public class ProviderValue: ObservableObject, Identifiable {
    public var id: String { provider }
    public var provider: String
    @Published public var enabled: Bool
    @Published public var apiProxyAddress: String?
    @Published public var apiKey: String
    // 用户添加的模型
    @Published public var models1: [ProviderModelValue]
    // 选中的默认模型
    @Published public var models2: [String]

    public init(provider: String, enabled: Bool, apiProxyAddress: String?, apiKey: String, models1: [ProviderModelValue], models2: [String]) {
        self.provider = provider
        self.enabled = enabled
        self.apiProxyAddress = apiProxyAddress
        self.apiKey = apiKey
        self.models1 = models1
        self.models2 = models2
    }

    public func update(enabled: Bool) {
        self.enabled = enabled
    }
}

public let DefaultProviderValue = ProviderValue(
    provider: "deepseek",
    enabled: true,
    apiProxyAddress: nil,
    apiKey: "sk-292831353cda4d1c9f59984067f24379",
    models1: [],
    models2: ["deepseek-chat"]
)

class Config: ObservableObject {
    let store: ChatStore
    // 系统固定角色
    var roles: [RoleBiz] = []

    var me: RoleBiz
    var languageProviders: [LanguageProvider]
    var languageProviderValues: [String:ProviderValue] = [:]
    var languageProviderControllers: [LLMProviderController]

    public var enabledProviders: [LLMProviderController] {
        return languageProviderControllers.filter { $0.value.enabled }
    }
    
    @Published var apiProxyAddress: String?
    @Published var apiKey: String?
    
    init(store: ChatStore) {
        self.store = store
        // if let userIdString = UserDefaults.standard.string(forKey: "userId") {
        //     let id = UUID(uuidString: userIdString) ?? UUID()
            
        // } else {
        //     let id = UUID()
        //     self.my = RoleBiz(
        //         id: id,
        //         name: "小明",
        //         avatar_uri: "",
        //         store: store
        //     )
        //     UserDefaults.standard.set(id.uuidString, forKey: "userId")
        // }

        self.me = RoleBiz(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            name: "u5x9k4",
            desc: "",
            avatar: "",
            prompt: "",
            language: "",
            created_at: Date(),
            config: RoleConfig(
                voice: RoleVoice.GetDefault(),
                llm: defaultRoleLLM
            )
        )

        // print("[BIZ]Config.init: me: \(me.id) \(me.name)")

        if let languageProviderValues: [String:Any] = UserDefaults.standard.object(forKey: "provider_values") as? [String:Any] {
            var values: [String: ProviderValue] = [:]
            for (name, data) in languageProviderValues {
                if let v = data as? [String: Any] {
                    // 将字典数组转回 ProviderModelValue 数组
                    let models1Data = v["models1"] as? [[String: Any]] ?? []
                    let models1 = models1Data.map { dict in
                        ProviderModelValue(
                            name: dict["name"] as? String ?? "",
                            enabled: dict["enabled"] as? Bool ?? true
                        )
                    }
                    
                    values[name] = ProviderValue(
                        provider: name,
                        enabled: v["enabled"] as? Bool ?? false,
                        apiProxyAddress: v["apiProxyAddress"]as? String == "" ? nil : v["apiProxyAddress"] as? String,
                        apiKey: v["apiKey"] as? String ?? "",
                        models1: models1,
                        models2: v["models2"] as? [String] ?? []
                    )
                }
            }
            self.languageProviderValues = values
        }
        self.languageProviders = LLMServiceProviders
        var controllers: [LLMProviderController] = []
        for provider in self.languageProviders {
            let value = self.languageProviderValues[provider.name]
            if value != nil {
                controllers.append(LLMProviderController(provider: provider, value: value!))
            } else {
                controllers.append(LLMProviderController(
                    provider: provider,
                    value: ProviderValue(
                        provider: provider.name,
                        enabled: provider.name == "openai" ? true : false,
                        apiProxyAddress: nil,
                        apiKey: "",
                        models1: [],
                        models2: provider.name == "openai" ? provider.models.map { $0.id } : []
                    )
                ))
            }
        }
        self.languageProviderControllers = controllers
        
        // self.languageProviderControllers = self.languageProviders.map { LLMProviderController(provider: $0, value: self.languageProviderValues[$0.name] ?? DefaultProviderValue) }
        // self.languageProviderValues = [
        //     DefaultProviderValue.provider: DefaultProviderValue,
        //     "doubao": ProviderValue(
        //         provider: "doubao",
        //         enabled: true,
        //         apiProxyAddress: nil,
        //         apiKey: "",
        //         models: [
        //             ProviderModelValue(
        //                 name: "ep-20250205141518-nvl9p",
        //                 enabled: true
        //             )
        //         ]
        //     )
        // ]
    }
    
    func updateProviders(_ providers: [LanguageProvider]) {
        self.languageProviders = providers
        // 这里可以添加持久化存储逻辑，比如保存到 UserDefaults 或文件中
    }
    
    func updateProviderValues(_ values: [ProviderValue]) {
//        self.languageProviderValues = values
        // 这里可以添加持久化存储逻辑
    }

    func updateSingleProviderValue(name: String, value: ProviderValue) {
        self.languageProviderValues[name] = value
        
        // 将 models1 转换为可序列化的字典数组
        let models1Data = value.models1.map { model -> [String: Any] in
            return [
                "name": model.name,
                "enabled": model.enabled
            ]
        }
        
        var existing: [String: Any] = UserDefaults.standard.object(forKey: "provider_values") as? [String: Any] ?? [:]
        existing[name] = [
            "enabled": value.enabled,
            "apiProxyAddress": value.apiProxyAddress ?? "", // 处理可选值
            "apiKey": value.apiKey,
            "models1": models1Data,
            "models2": value.models2
        ]
        UserDefaults.standard.set(existing, forKey: "provider_values")
    }
    
    func updateSettings(values: [String:ProviderValue]) {
        var data: [String: Any] = [:]
        for (name, value) in values {
            // 将 models1 转换为可序列化的字典数组
            let models1Data = value.models1.map { model -> [String: Any] in
                return [
                    "name": model.name,
                    "enabled": model.enabled
                ]
            }
            
            data[name] = [
                "enabled": value.enabled,
                "apiProxyAddress": value.apiProxyAddress ?? "", // 处理可选值
                "apiKey": value.apiKey,
                "models1": models1Data,
                "models2": value.models2
            ]
        }
        UserDefaults.standard.set(data, forKey: "provider_values")
    }
} 
