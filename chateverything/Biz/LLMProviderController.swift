import Foundation

public class LLMProviderModelController: ObservableObject, Identifiable, Hashable {
    public let id: String
    let isDefault: Bool
    @Published public var enabled: Bool

    public init(isDefault: Bool, enabled: Bool, id: String) {
        self.isDefault = isDefault
        self.enabled = enabled
        self.id = id
    }

    public static func == (lhs: LLMProviderModelController, rhs: LLMProviderModelController) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public class LLMProviderController: ObservableObject, Identifiable, Hashable {
	public var id: String { provider.id }
    public var name: String { provider.name }
    public var provider: LLMProvider
    @Published public var value: LLMProviderValue

    @Published public var models: [LLMProviderModelController]

    public init(provider: LLMProvider, value: LLMProviderValue) {
        self.provider = provider
        self.value = value
        let models1: [LLMProviderModelController] = value.models1.map { LLMProviderModelController(isDefault: false, enabled: $0.enabled, id: $0.id) }
        let models2: [LLMProviderModelController] = provider.models.map { LLMProviderModelController(isDefault: true, enabled: value.models2.contains($0.id), id: $0.id) }
        self.models = models2 + models1
    }

    public static func == (lhs: LLMProviderController, rhs: LLMProviderController) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public func build(config: RoleConfig) -> LLMServiceConfig {
        let llmConfig = config.llm
        return LLMServiceConfig(
            provider: self.provider.id,
            model: llmConfig["model"] as! String,
            apiProxyAddress: value.apiProxyAddress ?? provider.apiProxyAddress,
            apiKey: value.apiKey
        )
    }

    public func updateValueModels() {
        value.models1 = models.filter { 
            if !$0.isDefault {
                return true
            }
            return false
         }.map { LLMProviderModelValue(id: $0.id, enabled: $0.enabled) }
        value.models2 = models.filter { 
            if $0.isDefault && $0.enabled {
                return true
            }
            return false
         }.map { $0.id }
    }

    public func addCustomModel(id: String) {
        self.models.append(LLMProviderModelController(isDefault: false, enabled: true, id: id))
        self.updateValueModels()
    }

    public func removeCustomModel(id: String) {
        self.models.removeAll { $0.id == id }
        self.updateValueModels()
    }
    
    public func enable() {
        value.enabled = true
    }
    
    public func disable() {
        value.enabled = false
    }
    
    public func updateApiProxyAddress(_ address: String) {
        value.apiProxyAddress = address
    }
    
    public func updateApiKey(_ key: String) {
        value.apiKey = key
    }
    
    public func selectModel(_ modelId: String) {
        value.models2.append(modelId)
    }
    
    public func unselectModel(_ modelId: String) {
        value.models2.removeAll { $0 == modelId }
    }
} 
