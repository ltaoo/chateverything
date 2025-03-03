import Foundation

public enum Route: Hashable {
    case ChatDetailView(sessionId: UUID)
    case VocabularyStudyView(filepath: String)
    case RoleDetailView(roleId: UUID)
    case VocabularyReviewView
    case RoleCreateView
}


class Config: ObservableObject {
    let store: ChatStore
    let envs = Bundle.main.infoDictionary?["LSEnvironment"] as? [String:Any] ?? [:]
    let permissionManager: PermissionManager

    var me: RoleBiz
    var roles: [RoleBiz] = []
    var llmProviders: [LLMProvider]
    // 角色们的 llm 配置
    var llmProviderValues: [String:LLMProviderValue] = [:]
    var llmProviderControllers: [LLMProviderController]
    var ttsProviders: [TTSProvider]
    // 角色们的 tts 配置
    var ttsProviderValues: [String:TTSProviderValue] = [:]
    var ttsProviderControllers: [TTSProviderController]
    @Published var llmConfig: [String:Any] = defaultRoleLLM
    @Published var ttsConfig: [String:Any] = defaultRoleTTS

    public var enabledLLMProviders: [LLMProviderController] {
        return llmProviderControllers.filter { $0.value.enabled }
    }
    public var enabledTTSProviders: [TTSProviderController] {
        return ttsProviderControllers.filter { $0.value.enabled }
    }

    init(store: ChatStore) {
        // print("[]Config \(self.envs["BUILDIN_API_KEY"])")

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
                        llm: defaultRoleLLM,
                        autoBlur: false
                    )
                )
            } else {
                self.me = RoleBiz(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                    name: "u5x9k4",
                    desc: "",
                    avatar: "avatar1",
                    prompt: "",
                    language: "",
                    created_at: Date(),
                    config: RoleConfig(
                        voice: RoleVoice.GetDefault(),
                        llm: defaultRoleLLM,
                        autoBlur: false
                    )
                )
                let data = [
                    "id": me.id.uuidString,
                    "name": me.name,
                    "avatar": me.avatar,
                ]
                UserDefaults.standard.set(data, forKey: "me")
            }
            self.me.disabled = true

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
                            voice = defaultRoleTTS
                        }
                        if var l = llm {
                            if l["provider"] == nil {
                                llm!["provider"] = "deepseek"
                            }
                        } else {
                            llm = defaultRoleLLM
                        }
                        role.config = RoleConfig(
                            voice: voice ?? defaultRoleTTS,
                            llm: llm ?? defaultRoleLLM
                        )
                        print("role: \(role.name) voice: \(voice) llm: \(llm)")
                    }
                }
            }
            self.roles = DefaultRoles + [self.me] + scenarios.map { $0.talker }
            // print("roles: \(roles.count)")

// loadLLMProviders
            LLMServiceProviders = [
                LLMProvider(
                    id: "build-in",
                    name: "体验服务",
                    logo_uri: "chateverything",
                    apiKey: "",
                    apiProxyAddress: "https://ark.cn-beijing.volces.com/api/v3/chat/completions",
                    models: [
                        LLMProviderModel(
                            id: "deepseek-v3-241226",
                            name: "测试对话", desc: "", type: "", tags: [])
                    ],
                    responseHandler: LLMServiceDefaultHandler,
                    extra: ["api_key": self.envs["BUILDIN_API_KEY"] ?? ""]
                ),
            ] + LLMServiceProviders
            self.llmProviders = LLMServiceProviders
            if var llmProviderValues: [String:Any] = UserDefaults.standard.object(forKey: "llm_provider_values") as? [String:Any] {
                var values: [String: LLMProviderValue] = [:]
                for (name, data) in llmProviderValues {
                    if let v = data as? [String: Any] {
                        // 将字典数组转回 LLMProviderModelValue 数组
                        let models1Data = v["models1"] as? [[String: Any]] ?? []
                        let models1 = models1Data.map { dict in
                            LLMProviderModelValue(
                                id: dict["id"] as? String ?? "",
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
            let defaultEnabledProviders = ["openai", "deepseek", "build-in"]
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
                            enabled: defaultEnabledProviders.contains(llmProvider.id) ? true : false,
                            apiProxyAddress: nil,
                            apiKey: "",
                            models1: [],
                            models2: defaultEnabledProviders.contains(llmProvider.id) ? llmProvider.models.map { $0.id } : []
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


        self.ttsConfig = UserDefaults.standard.object(forKey: "tts_config") as? [String:Any] ?? defaultRoleTTS
        self.llmConfig = UserDefaults.standard.object(forKey: "llm_config") as? [String:Any] ?? defaultRoleLLM
    }

    func updateMeName(name: String) {
        self.me.name = name
        var existing: [String: Any] = UserDefaults.standard.object(forKey: "me") as? [String: Any] ?? [:]
        existing["name"] = name
        UserDefaults.standard.set(existing, forKey: "me")
    }

    func updateMeAvatar(avatar: Data) {
        // Save the image data to UserDefaults
        // self.me.avatar = avatar
        // var existing: [String: Any] = UserDefaults.standard.object(forKey: "me") as? [String: Any] ?? [:]
        // existing["avatar"] = avatar
        // UserDefaults.standard.set(existing, forKey: "me")
        
        // Update the avatar in memory
        // Note: We're keeping the existing avatar string in case it's a network URL or asset name
        // The presence of avatarData in UserDefaults will take precedence when displaying
    }

    func updateSingleLLMProviderValue(id: String, value: LLMProviderValue) {
        self.llmProviderValues[id] = value
        let models1Data = value.models1.map { model -> [String: Any] in
            return [
                "id": model.id,
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

    func updateLLMConfig(value: [String:Any]) {
        self.llmConfig = value
        UserDefaults.standard.set(value, forKey: "llm_config")
    }
    func updateTTSConfig(value: [String:Any]) {
        self.ttsConfig = value
        UserDefaults.standard.set(value, forKey: "tts_config")
    }
}
