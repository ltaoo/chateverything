import Foundation

public class LLMProviderModelValue: Identifiable, Codable {
    public var id: String
    var enabled: Bool = true
    
    enum CodingKeys: String, CodingKey {
        case id
        case enabled
    }

    public init(id: String, enabled: Bool) {
        self.id = id
        self.enabled = enabled
    }

    public func toggle(value: Bool) {
        enabled = value
    }
}

public class LLMProviderValue: ObservableObject, Identifiable {
    public var id: String
    @Published public var enabled: Bool
    @Published public var apiProxyAddress: String?
    @Published public var apiKey: String
    // 用户添加的模型
    @Published public var models1: [LLMProviderModelValue]
    // 选中的默认模型
    @Published public var models2: [String]

    public init(id: String, enabled: Bool, apiProxyAddress: String?, apiKey: String, models1: [LLMProviderModelValue], models2: [String]) {
        self.id = id
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

