import Foundation
import LLM

public class LLMProviderModelController: ObservableObject, Identifiable {
    public var id: String { name }
    let canDelete: Bool
    @Published public var enabled: Bool
    @Published public var name: String

    public init(canDelete: Bool, enabled: Bool, name: String) {
        self.canDelete = canDelete
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
        let models1 = value.models1.map { LLMProviderModelController(canDelete: true, enabled: $0.enabled, name: $0.name) }
        let models2 = provider.models.map { LLMProviderModelController(canDelete: false, enabled: value.models2.contains($0.name), name: $0.name) }
        self.models = models2 + models1
    }

    public func addCustomModel(name: String) {
        value.models1.append(ProviderModelValue(name: name, enabled: true))
        self.models.append(LLMProviderModelController(canDelete: true, enabled: true, name: name))
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
