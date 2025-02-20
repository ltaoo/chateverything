import Foundation
import LLM

struct LanguageValue {
    var provider: String
    var isEnabled: Bool
    var apiProxyAddress: String
    var apiKey: String
    var selectedModels: [String]
}

public enum Route {
    case ChatDetailView(roleId: UUID)
}

class Config {
    static let shared = Config()
    
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
        self._languageProviders = LLMServiceProviders
        
        self._languageValues = [
            LanguageValue(
                provider: "deepseek",
                isEnabled: true,
                apiProxyAddress: "https://api.deepseek.com/chat/completions", apiKey: "sk-292831353cda4d1c9f59984067f24379",
                selectedModels: ["deepseek-chat"]
            ),
            LanguageValue(
                provider: "doubao",
                isEnabled: true,
                apiProxyAddress: "https://ark.cn-beijing.volces.com/api/v3/chat/completions", apiKey: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhcmstY29uc29sZSIsImV4cCI6MTczOTk5MjgxMCwiaWF0IjoxNzM5OTU2ODEwLCJ0IjoidXNlciIsImt2IjoxLCJhaWQiOiIyMTAyMDM0ODI1IiwidWlkIjoiMCIsImlzX291dGVyX3VzZXIiOnRydWUsInJlc291cmNlX3R5cGUiOiJlbmRwb2ludCIsInJlc291cmNlX2lkcyI6WyJlcC0yMDI1MDIwNTE0MTUxOC1udmw5cCJdfQ.Z1GxZIt9zPUHfTEsHm9FctiECbO0SxGGuCF5ZIMWG7J1FMRyvWvK2qCWCXvR8yEHRpxKCEg-y_uVAuBklv90PchOlalJy_nvRidKrptzNJSjRVPFjZCKFd_cwEoqPv3NV-ltH3fc3HJCq0abuU6UR_gKY__Tl2qwcjUnr0tXjit71w9wQM6CQGB_49NvQdbq087ISZmC3yi0XSPVyN2b2F0WBp6lxZUCxdwbKtxVZc0N_SRcJQPNxrgsgjmFxqCjTADZggVT_2sCzqsax0rtGFR8PypiPhnMJyT1FutscqCo69RptOlfFlGect4ol_S9RBa1uyhSK3B_ixfVya8S1g",
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
