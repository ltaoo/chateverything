import Foundation
import LLM

public class LLMProviderModelController: ObservableObject, Identifiable {
    public var id: String { name }
    // 默认模型
    let isDefault: Bool
    @Published public var enabled: Bool
    @Published public var name: String

    public init(isDefault: Bool, enabled: Bool, name: String) {
        self.isDefault = isDefault
        self.enabled = enabled
        self.name = name
    }
}

public class LLMProviderController: ObservableObject, Identifiable {
	public var id: String { provider.name }
    public var name: String { provider.name }
    public var provider: LanguageProvider
    @Published public var value: ProviderValue

    @Published public var models: [LLMProviderModelController]

    public init(provider: LanguageProvider, value: ProviderValue) {
        self.provider = provider
        self.value = value
        let models1 = value.models1.map { LLMProviderModelController(isDefault: false, enabled: $0.enabled, name: $0.name) }
        let models2 = provider.models.map { LLMProviderModelController(isDefault: true, enabled: value.models2.contains($0.name), name: $0.name) }
        self.models = models2 + models1
    }

    public func updateValueModels() {
        value.models1 = models.filter { 
            if !$0.isDefault {
                return true
            }
            return false
         }.map { ProviderModelValue(name: $0.name, enabled: $0.enabled) }
        value.models2 = models.filter { 
            if $0.isDefault && $0.enabled {
                return true
            }
            return false
         }.map { $0.name }
    }

    public func addCustomModel(name: String) {
        self.models.append(LLMProviderModelController(isDefault: false, enabled: true, name: name))
        self.updateValueModels()
    }

    public func removeCustomModel(name: String) {
        self.models.removeAll { $0.name == name }
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
