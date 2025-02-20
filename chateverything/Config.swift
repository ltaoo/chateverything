import Foundation
import LLM

public struct LanguageValue: Identifiable {
    public var id: String { provider }
    var isEnabled: Bool
    let provider: String
    var apiProxyAddress: String
    var apiKey: String
    var selectedModels: [String]
}

public enum Route: Hashable {
    case ChatDetailView(sessionId: UUID)
}
public let DefaultLanguageValue = LanguageValue(
    isEnabled: true,
    provider: "deepseek",
    apiProxyAddress: "https://api.deepseek.com/chat/completions",
    apiKey: "sk-292831353cda4d1c9f59984067f24379",
    selectedModels: ["deepseek-chat"]
)

class Config {
    static let shared = Config()

    var userId: UUID
    private var _languageProviders: [LanguageProvider]
    private var _languageValues: [LanguageValue]
    
    var languageProviders: [LanguageProvider] {
        get { _languageProviders }
        set { _languageProviders = newValue }
    }
    
    var languageValues: [LanguageValue] {
        get { _languageValues }
        set { _languageValues = newValue }
    }
    
    let roles: [RoleEntity] = [
        // 可以添加更多角色
    ]
    
    private init() {
        if let userIdString = UserDefaults.standard.string(forKey: "userId") {
            self.userId = UUID(uuidString: userIdString) ?? UUID()
        } else {
            self.userId = UUID()
            UserDefaults.standard.set(self.userId.uuidString, forKey: "userId")
        }
        self._languageProviders = LLMServiceProviders
        self._languageValues = [
            DefaultLanguageValue,
            LanguageValue(
                isEnabled: true,
                provider: "doubao",
                apiProxyAddress: "https://ark.cn-beijing.volces.com/api/v3/chat/completions",
                apiKey: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhcmstY29uc29sZSIsImV4cCI6MTc0MDEwODUxMywiaWF0IjoxNzQwMDcyNTEzLCJ0IjoidXNlciIsImt2IjoxLCJhaWQiOiIyMTAyMDM0ODI1IiwidWlkIjoiMCIsImlzX291dGVyX3VzZXIiOnRydWUsInJlc291cmNlX3R5cGUiOiJlbmRwb2ludCIsInJlc291cmNlX2lkcyI6WyJlcC0yMDI1MDIwNTE0MTUxOC1udmw5cCJdfQ.ao9qOXNn7Wzjd1v98DunW4UXIVBZx4L5T3KRx6IbBRD5oFo6hWxdYaIG6jdk0wRIeP09Vb5PYlhEuhUrTmzUZMCWCvVI7o3uRyNR_Hgzlx4u8AoG9pze_Ybw6Ojw_QtURK6L6RXnbcpnE7jdA6Lrf8GnLYxVFA53FVs9x4JycpRWtUypwviJ3TEzmv-k-6XKuyQMKNzIGuKgBxVpgdW6Ny9k1S732wqOegEFU1nqJlZfgaEiFVBC6xWnYXxmZFtfDaghF2vY_TNxDFCF_pkWkwhTtPodGc6fW8OCXHgagcBbFuXjlH250uqF0QB9Np1lNR-86PqD1aSy9nNkg5BFpA",
                selectedModels: ["ep-20250205141518-nvl9p"]
            )
        ]
    }
    
    func updateProviders(_ providers: [LanguageProvider]) {
        self._languageProviders = providers
        // 这里可以添加持久化存储逻辑，比如保存到 UserDefaults 或文件中
    }
    
    func updateLanguageValues(_ values: [LanguageValue]) {
        self._languageValues = values
        // 这里可以添加持久化存储逻辑
    }
} 
