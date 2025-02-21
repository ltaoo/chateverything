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
                apiKey: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhcmstY29uc29sZSIsImV4cCI6MTc0MDE4NTY3OSwiaWF0IjoxNzQwMTQ5Njc5LCJ0IjoidXNlciIsImt2IjoxLCJhaWQiOiIyMTAyMDM0ODI1IiwidWlkIjoiMCIsImlzX291dGVyX3VzZXIiOnRydWUsInJlc291cmNlX3R5cGUiOiJlbmRwb2ludCIsInJlc291cmNlX2lkcyI6WyJlcC0yMDI1MDIwNTE0MTUxOC1udmw5cCJdfQ.MWhl-lY9UourHzus9-qB6CtsoQ1VKWUAyd9dubsxx5aEt_l9VOoW6br_VEAgwDeAFoynwOhWU7xXBp9RDkrJ0DymbbaVk-ozzR4hEDtGGDkfhDnb4reQqqwm4clzMwFfMmDZz6mS1pfotVrQ3dZbOCpCezfxQJtTXT1N2kgnsr2f3-9ekVINd9MzB9iF6Raumu8S-olOLZQSCxPfttFGd4_dp2I56FyMqi7lujf2IyNg2nd6YQmi2sbQq9WEo_bts6y4WKrUlkLuDaQozNuyA7FMJSiC1rtWQShEHEAYwg2uL9nPdPFqH2EWtpC6DRsxw83IrDIqv3LSuNQEr7sAuw",
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
