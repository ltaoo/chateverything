import Foundation

public class TTSProviderController: ObservableObject, Identifiable, Hashable {
	public var id: String { provider.id }
    public var name: String { provider.name }
    public var provider: TTSProvider
    @Published public var value: TTSProviderValue

    public init(provider: TTSProvider, value: TTSProviderValue) {
        self.provider = provider
        self.value = value
    }

    public func enable() {
        value.enabled = true
    }
    
    public func disable() {
        value.enabled = false
    }

    public static func == (lhs: TTSProviderController, rhs: TTSProviderController) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
} 
