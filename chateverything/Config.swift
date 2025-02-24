import Foundation

public enum Route: Hashable {
    case ChatDetailView(sessionId: UUID)
    case VocabularyView(filepath: String)
    case RoleDetailView(roleId: UUID)
}

class Config: ObservableObject {
    let store: ChatStore
    // 系统固定角色
    var roles: [RoleBiz] = []

    var me: RoleBiz
    var llmProviders: [LLMProvider]
    var llmProviderValues: [String:LLMProviderValue] = [:]
    var llmProviderControllers: [LLMProviderController]
    var ttsProviders: [TTSProvider]
    var ttsProviderValues: [String:TTSProviderValue] = [:]
    var ttsProviderControllers: [TTSProviderController]

    public var enabledLLMProviders: [LLMProviderController] {
        return llmProviderControllers.filter { $0.value.enabled }
    }
    public var enabledTTSServiceProviders: [TTSProviderController] {
        return ttsProviderControllers.filter { $0.value.enabled }
    }
    
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

        self.llmProviders = LLMServiceProviders
        if let llmProviderValues: [String:Any] = UserDefaults.standard.object(forKey: "provider_values") as? [String:Any] {
            var values: [String: LLMProviderValue] = [:]
            for (name, data) in llmProviderValues {
                if let v = data as? [String: Any] {
                    // 将字典数组转回 LLMProviderModelValue 数组
                    let models1Data = v["models1"] as? [[String: Any]] ?? []
                    let models1 = models1Data.map { dict in
                        LLMProviderModelValue(
                            name: dict["name"] as? String ?? "",
                            enabled: dict["enabled"] as? Bool ?? true
                        )
                    }
                    
                    values[name] = LLMProviderValue(
                        id: name,
                        enabled: v["enabled"] as? Bool ?? false,
                        apiProxyAddress: v["apiProxyAddress"]as? String == "" ? nil : v["apiProxyAddress"] as? String,
                        apiKey: v["apiKey"] as? String ?? "",
                        models1: models1,
                        models2: v["models2"] as? [String] ?? []
                    )
                }
            }
            self.llmProviderValues = values
        }
        var llmControllers: [LLMProviderController] = []
        for llmProvider in LLMServiceProviders {
            let value = self.llmProviderValues[llmProvider.id]
            if value != nil {
                llmControllers.append(LLMProviderController(provider: llmProvider, value: value!))
            } else {
                llmControllers.append(LLMProviderController(
                    provider: llmProvider,
                    value: LLMProviderValue(
                        id: llmProvider.id,
                        enabled: llmProvider.id == "openai" ? true : false,
                        apiProxyAddress: nil,
                        apiKey: "",
                        models1: [],
                        models2: llmProvider.id == "openai" ? llmProvider.models.map { $0.id } : []
                    )
                ))
            }
        }
        self.llmProviderControllers = llmControllers

        self.ttsProviders = TTSProviders
        if let ttsProviderValues: [String:Any] = UserDefaults.standard.object(forKey: "tts_provider_values") as? [String:Any] {
            var values: [String: TTSProviderValue] = [:]
            for (id, data) in ttsProviderValues {
                if let v = data as? [String: Any] {
                    values[id] = TTSProviderValue(
                        id: id,
                        enabled: v["enabled"] as? Bool ?? false,
                        credential: v["credential"] as? [String:String] ?? [:]
                    )
                }
            }
            self.ttsProviderValues = values
        }
        var ttsControllers: [TTSProviderController] = []
        for ttsProvider in TTSProviders {
            let value = self.ttsProviderValues[ttsProvider.id]
            if value != nil {
                ttsControllers.append(TTSProviderController(provider: ttsProvider, value: value!))
                ttsProvider.credential?.setValue(value: value!.credential)
            } else {
                ttsControllers.append(TTSProviderController(
                    provider: ttsProvider,
                    value: TTSProviderValue(
                        id: ttsProvider.id,
                        enabled: ttsProvider.id == "system" ? true : false,
                        credential: [:]
                    )
                ))
            }
        }
        self.ttsProviderControllers = ttsControllers
    }

    func updateSingleLLMProviderValue(id: String, value: LLMProviderValue) {
        self.llmProviderValues[id] = value
        let models1Data = value.models1.map { model -> [String: Any] in
            return [
                "name": model.name,
                "enabled": model.enabled
            ]
        }
        var existing: [String: Any] = UserDefaults.standard.object(forKey: "provider_values") as? [String: Any] ?? [:]
        existing[id] = [
            "enabled": value.enabled,
            "apiProxyAddress": value.apiProxyAddress ?? "", // 处理可选值
            "apiKey": value.apiKey,
            "models1": models1Data,
            "models2": value.models2
        ]
        UserDefaults.standard.set(existing, forKey: "provider_values")
    }

    func updateSingleTTSProviderValue(id: String, value: TTSProviderValue) {
        // print("updateSingleTTSProviderValue \(id)")
        self.ttsProviderValues[id] = value
        var existing: [String: Any] = UserDefaults.standard.object(forKey: "tts_provider_values") as? [String: Any] ?? [:]
        existing[id] = [
            "enabled": value.enabled,
            "credential": value.credential
        ]
        UserDefaults.standard.set(existing, forKey: "tts_provider_values")
    }
}
