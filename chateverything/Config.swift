import Foundation

public enum Route: Hashable {
    case ChatDetailView(sessionId: UUID)
    case VocabularyView(filepath: String)
    case RoleDetailView(roleId: UUID)
}


class Config: ObservableObject {
    let store: ChatStore
    let permissionManager: PermissionManager

    var me: RoleBiz
    var roles: [RoleBiz] = []
    var llmProviders: [LLMProvider]
    var llmProviderValues: [String:LLMProviderValue] = [:]
    var llmProviderControllers: [LLMProviderController]
    var ttsProviders: [TTSProvider]
    var ttsProviderValues: [String:TTSProviderValue] = [:]
    var ttsProviderControllers: [TTSProviderController]

    public var enabledLLMProviders: [LLMProviderController] {
        return llmProviderControllers.filter { $0.value.enabled }
    }
    public var enabledTTSProviders: [TTSProviderController] {
        return ttsProviderControllers.filter { $0.value.enabled }
    }

    init(store: ChatStore) {
        self.store = store
        self.permissionManager = PermissionManager.shared
// loadMe
            if let me = UserDefaults.standard.object(forKey: "me") {
                let mm = me as! [String:Any]
                self.me = RoleBiz(
                    id: UUID(uuidString: mm["id"] as? String ?? "")!,
                    name: mm["name"] as? String ?? "",
                    desc: mm["desc"] as? String ?? "",
                    avatar: mm["avatar"] as? String ?? "",
                    prompt: mm["prompt"] as? String ?? "",
                    language: mm["language"] as? String ?? "",
                    created_at: mm["created_at"] as? Date ?? Date(),
                    config: RoleConfig(
                        voice: RoleVoice.GetDefault(),
                        llm: defaultRoleLLM
                    )
                )
            } else {
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
                let data = [
                    "id": me.id.uuidString,
                    "name": me.name,
                    "avatar": me.avatar,
                ]
                UserDefaults.standard.set(data, forKey: "me")
            }


                // if let configs = UserDefaults.standard.object(forKey: "role_configs") as? [String: Any] {
                //     for (id, config) in configs {
                //         if let config = config as? [String: Any] {
                //             print("get config of role: \(id) \(config)")
                //         }
                //     }
                // }
// loadRoles
//            var roles: [RoleBiz] = []
            for role in DefaultRoles {
                if let configs = UserDefaults.standard.object(forKey: "role_configs") as? [String: Any] {
                    if let config = configs[role.id.uuidString] as? [String: Any] {
                        var voice = config["voice"] as? [String: Any]
                        var llm = config["llm"] as? [String: Any]
                        if var v = voice {
                            if v["provider"] == nil {
                                voice!["provider"] = "system"
                            }
                        } else {
                            voice = defaultRoleVoice
                        }
                        if var l = llm {
                            if l["provider"] == nil {
                                llm!["provider"] = "deepseek"
                            }
                        } else {
                            llm = defaultRoleLLM
                        }
                        role.config = RoleConfig(
                            voice: voice ?? defaultRoleVoice,
                            llm: llm ?? defaultRoleLLM
                        )
                        print("role: \(role.name) voice: \(voice) llm: \(llm)")
                    }
                }
            }
            self.roles = DefaultRoles
            print("roles: \(roles.count)")

// loadLLMProviders
            self.llmProviders = LLMServiceProviders
            if var llmProviderValues: [String:Any] = UserDefaults.standard.object(forKey: "llm_provider_values") as? [String:Any] {
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
                            enabled: (llmProvider.id == "openai" || llmProvider.id == "deepseek") ? true : false,
                            apiProxyAddress: nil,
                            apiKey: "",
                            models1: [],
                            models2: (llmProvider.id == "openai" || llmProvider.id == "deepseek") ? llmProvider.models.map { $0.id } : []
                        )
                    ))
                }
            }
            self.llmProviderControllers = llmControllers

// loadTTSProviders
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
                            enabled: (ttsProvider.id == "system") ? true : false,
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
        var existing: [String: Any] = UserDefaults.standard.object(forKey: "llm_provider_values") as? [String: Any] ?? [:]
        existing[id] = [
            "enabled": value.enabled,
            "apiProxyAddress": value.apiProxyAddress ?? "", // 处理可选值
            "apiKey": value.apiKey,
            "models1": models1Data,
            "models2": value.models2
        ]
        UserDefaults.standard.set(existing, forKey: "llm_provider_values")
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

    func updateRoleLLMConfig(roleId: UUID, value: [String: Any]) {
        let role = self.roles.first { $0.id == roleId }
        guard let role = role else {
            return
        }
        role.config.llm = value
        var configs: [String: Any] = UserDefaults.standard.object(forKey: "role_configs") as? [String: Any] ?? [:]
        if var existing = configs[roleId.uuidString] as? [String: Any] {
            existing["llm"] = value
            configs[roleId.uuidString] = existing
        } else {
            configs[roleId.uuidString] = ["voice": RoleVoice.GetDefault(), "llm": value]
        }
        UserDefaults.standard.set(configs, forKey: "role_configs")
    }
    func updateRoleVoiceConfig(roleId: UUID, value: [String: Any]) {
        let role = self.roles.first { $0.id == roleId }
        guard let role = role else {
            return
        }
        role.config.voice = value
        var configs: [String: Any] = UserDefaults.standard.object(forKey: "role_configs") as? [String: Any] ?? [:]
        if var existing = configs[roleId.uuidString] as? [String: Any] {
            existing["voice"] = value
            configs[roleId.uuidString] = existing
        } else {
            configs[roleId.uuidString] = ["voice": value, "llm": defaultRoleLLM]
        }
        UserDefaults.standard.set(configs, forKey: "role_configs")
    }
}

// Add this extension before the Config class
extension Dictionary {
    static func assign(_ target: [Key: Value], _ sources: [Key: Value]...) -> [Key: Value] {
        var result = target
        
        for source in sources {
            for (key, value) in source {
                result[key] = value
            }
        }
        
        return result
    }
    
    mutating func assign(_ sources: [Key: Value]...) {
        for source in sources {
            for (key, value) in source {
                self[key] = value
            }
        }
    }
}
