import Foundation
import LLM



public class ProviderModelValue: Identifiable {
    public var id: String { name }
    var name: String
    var enabled: Bool = true

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

public enum Route: Hashable {
    case ChatDetailView(sessionId: UUID)
}
public let DefaultProviderValue = ProviderValue(
    provider: "deepseek",
    enabled: true,
    apiProxyAddress: nil,
    apiKey: "sk-292831353cda4d1c9f59984067f24379",
    models1: [],
    models2: []
)

class Config: ObservableObject {
    static let shared = Config()

    // 系统固定角色
    var roles: [RoleEntity] = []

    var userId: UUID
    var languageProviders: [LanguageProvider]
    var languageProviderValues: [String:ProviderValue] = [:]
    var languageProviderControllers: [LLMProviderController]

    public var enabledProviders: [LLMProviderController] {
        return languageProviderControllers.filter { $0.value.enabled }
    }
    
    @Published var apiProxyAddress: String?
    @Published var apiKey: String?
    
    private init() {
        if let userIdString = UserDefaults.standard.string(forKey: "userId") {
            self.userId = UUID(uuidString: userIdString) ?? UUID()
        } else {
            self.userId = UUID()
            UserDefaults.standard.set(self.userId.uuidString, forKey: "userId")
        }

        if let languageProviderValues: [String:ProviderValue] = UserDefaults.standard.object(forKey: "provider_values") as? [String:ProviderValue] {
            var values: [String: ProviderValue] = [:]
            for (name, data) in languageProviderValues {
                if let v = data as? [String: Any] {
                    values[name] = ProviderValue(
                        provider: name,
                        enabled: v["enabled"] as? Bool ?? false,
                        apiProxyAddress: v["apiProxyAddress"] as? String ?? nil,
                        apiKey: v["apiKey"] as? String ?? "",
                        models1: v["models1"] as? [ProviderModelValue] ?? [],
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
    
    func updateSettings(values: [String:ProviderValue]) {
        var data: [String: Any] = [:]
        for (name, value) in values {
            data[name] = [
                "enabled": value.enabled,
                "apiProxyAddress": value.apiProxyAddress,
                "apiKey": value.apiKey,
                "models1": value.models1,
                "models2": value.models2
            ]
        }
        UserDefaults.standard.set(data, forKey: "provider_values")
    }
} 
