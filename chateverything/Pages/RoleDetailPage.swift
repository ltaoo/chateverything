import SwiftUI
import QCloudRealTTS

struct RoleDetailView: View {
    let roleId: UUID
    var path: NavigationPath
    var config: Config
    @StateObject var role: RoleBiz

    init(roleId: UUID, path: NavigationPath, config: Config) {
        self.roleId = roleId
        self.path = path
        self.config = config
        _role = StateObject(wrappedValue: RoleBiz(props: RoleProps(id: roleId)))
    }

    var body: some View {
        VStack {
            if role.loading {
                ProgressView()
            } else {
                List {
                    // 头部卡片
                    Section {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                            HStack(spacing: DesignSystem.Spacing.large) {
                                // 替换头像实现
                                Avatar(uri: role.avatar, size: DesignSystem.AvatarSize.large)
                                    .primaryShadow()
                                
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                                    Text(role.name)
                                        .font(DesignSystem.Typography.headingMedium)
                                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                                }
                            }
                        }
                        .padding(.vertical, DesignSystem.Spacing.small)
                    }

                    RoleLLMProviderSettingView(role: self.role, config: self.config)
                    RoleTTSProviderSettingView(role: self.role, config: self.config)
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .background(DesignSystem.Colors.background)
        .onAppear {
            print("[VIEW]RoleDetailView onAppear")
            role.loading = true
            role.load(config: config)
        }
    }
}

struct RoleTTSProviderSettingView: View {
    @ObservedObject var role: RoleBiz
    let config: Config
    
    @State var selectedProviderController: TTSProviderController?
    
    init(role: RoleBiz, config: Config) {
        self.role = role
        self.config = config

        print("[VIEW]RoleTTSProviderSettingView init \(role.config.voice)")
        if let providerId = role.config.voiceDict["provider"] as? String {
            _selectedProviderController = State(initialValue: config.ttsProviderControllers.first { $0.provider.id == providerId })
        }
    }

    var enabledTTSProviders: [TTSProviderController] {
        config.ttsProviderControllers.filter { $0.value.enabled }
    }
    var selectedProvider: TTSProvider? {
        config.ttsProviders.first { $0.id == selectedProviderController?.id }
    }

    var body: some View {
       Section(header: Text("语音设置")
           .font(DesignSystem.Typography.bodyMedium)
           .foregroundColor(DesignSystem.Colors.textSecondary)) {
            Picker("语音引擎", selection: $selectedProviderController) {
               ForEach(enabledTTSProviders, id: \.id) { provider in
                   Text(provider.name)
                       .font(DesignSystem.Typography.bodyMedium)
                       .tag(provider)
               }
            }
            .onChange(of: selectedProviderController) { controller in
                print("[VIEW]RoleTTSProviderSettingView selectedProviderController is changed \(controller)")
                if let c = controller {
                    let provider = c.provider
                    let r = provider.schema.validate()
                    print("[VIEW]RoleTTSProviderSettingView there is values? \(r.isValid)")
                    if r.isValid {
                    print("[VIEW]RoleTTSProviderSettingView selectedProviderController \(r.value)")
                        role.config.updateVoice(value: r.value)
                    }
                }
            }

            if let provider = selectedProvider {
                form

                VoiceTestButton(role: role, controller: selectedProviderController!, provider: provider)
            }
       }
    }

    func handleChange() {
        print("[VIEW]RoleTTSProviderSettingView handleChange")
    }


    struct TmpFormField: Identifiable {
        let id: String
        let field: AnyFormField
    }
 
    @ViewBuilder
    private var form: some View {
        if let schema = selectedProvider?.schema {
            let fields = schema.fields.map { (key: String, field: AnyFormField) in
                TmpFormField(id: key, field: field)
            }
            
            ForEach(fields) { pair in
                let key = pair.id
                let field = pair.field
                
                switch field {
                case .single(let formField):
                    switch formField.input {
                    case .InputString(let input):
                        TextField(
                            formField.label,
                            text: Binding(
                                get: { input.value ?? "" },
                                set: { newValue in
                                    input.setValue(value: newValue)
                                    self.handleChange()
                                }
                            )
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 4)
                        
                    case .InputNumber(let input):
                        TextField(
                            formField.label,
                            text: Binding(
                                get: { String(input.value ?? 0) },
                                set: { newValue in
                                    input.setValue(value: Double(newValue))
                                    self.handleChange()
                                }
                            )
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 4)
                        
                    case .InputBoolean(let input):
                        Toggle(formField.label, isOn: Binding(
                            get: { input.value ?? false },
                            set: { newValue in
                                input.setValue(value: newValue)
                                self.handleChange()
                            }
                        ))
                        
                    case .InputSelect(let input):
                        Picker(formField.label, selection: Binding(
                            get: { input.value ?? "" },
                            set: { newValue in
                                input.setValue(value: newValue)
                                self.handleChange()
                            }
                        )) {
                            ForEach(input.options) { option in
                                Text(option.label).tag(option.value)
                            }
                        }
                        
                    case .InputMultiSelect(let input):
                        // MultiSelect 需要特殊处理，这里暂时用普通的 Picker
                        Text("multi select")
                        // Picker(formField.label, selection: Binding(
                        //     get: { input.value?.first ?? "" },
                        //     set: { newValue in
                        //         input.setValue(value: [newValue])
                        //         self.handleChange()
                        //     }
                        // )) {
                        //     ForEach(input.options) { option in
                        //         Text(option.label).tag(option.value)
                        //     }
                        // }
                        
                    case .InputSlider(let input):
                        VStack(alignment: .leading) {
                            Text(formField.label)
                            Slider(
                                value: Binding(
                                    get: { input.value ?? input.min },
                                    set: { newValue in
                                        input.setValue(value: newValue)
                                        self.handleChange()
                                    }
                                ),
                                in: input.min...input.max,
                                step: input.step
                            )
                        }
                    }
                    
                case .array(_):
                    EmptyView() // Handle array fields if needed
                    
                case .object(_):
                    EmptyView() // Handle object fields if needed
                }
            }
        }
    }
}


struct RoleLLMProviderSettingView: View {
    @ObservedObject var role: RoleBiz
    let config: Config
    @State var selectedProviderController: LLMProviderController?

    init(role: RoleBiz, config: Config) {
        self.role = role
        self.config = config

        if let providerId = role.config.llmDict["provider"] as? String {
            _selectedProviderController = State(initialValue: config.llmProviderControllers.first { $0.provider.id == providerId })
        }
    }

    var enabledProvidersControllers: [LLMProviderController] {
        config.llmProviderControllers.filter { $0.value.enabled } as [LLMProviderController]
    }
    var selectedProvider: LLMProvider? {
        config.llmProviders.first { $0.id == selectedProviderController?.id }
    }

    var body: some View {
        ForEach(enabledProvidersControllers, id: \.id) { (controller: LLMProviderController) in
            Section {
                HStack {
                    Image(controller.provider.logo_uri)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    Text(controller.provider.name)
                }
                ModelListView(role: role, controller: controller, onTap: { model in
                    role.config.updateLLM(model: model.name)
                    DispatchQueue.main.async {
                        role.count += 1
                    }
                })
            }
        }
    }
}

// 子视图
struct ModelListView: View {
    @ObservedObject var role: RoleBiz
    let controller: LLMProviderController
    let onTap: (LLMProviderModelController) -> Void
    
    var body: some View {
        ForEach(controller.models, id: \.id) { sub in
            HStack {
                Text(sub.name)
                Spacer()
                if sub.name == role.config.llmDict["model"] as? String {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap(sub)
            }
        }
    }
}

struct VoiceTestButton: View {
    @ObservedObject var role: RoleBiz
    let controller: TTSProviderController
    let provider: TTSProvider
    @State var tts: TTSEngine?
    @State var player: PCMStreamPlayer?

    var body: some View {
        Button(action: {
            let text1 = "Hello! The weather is beautiful today. Would you like to go for a walk?"
            let text2 = "你好！今天天气真好。要不要一起去散步？"
            let text3 = "こんにちは！今日は天気が良いですね。一緒に散歩しませんか？"
            let lang = role.config.voiceDict["language"] as? String ?? "en-US"
            let text = {
                switch lang {
                case "en-US":
                    return text1
                case "zh-CN":
                    return text2
                case "jp-JP":
                    return text3
                default:
                    return text2
                }
            }()
            tts = {
                switch provider.id {
                case "tencent":
                    return TencentTTSEngine()
                case "system":
                    return SystemTTSEngine()
                default:
                    return SystemTTSEngine()
                }
            }()
            let credential = controller.value.credential
            var config = role.config.voiceDict
            for (key, value) in credential {
                config[key] = value
            }
            tts!.setConfig(config: config)
            tts!.setEvents(callback: TTSCallback(
                onStart: {
                    print("[VIEW]VoiceTestButton onStart")
                    player = PCMStreamPlayer()
                },
                onData: { data in
                    player?.put(data: data)
                },
                onComplete: {
                    print("[VIEW]VoiceTestButton onComplete")
                },
                onCancel: {
                    print("[VIEW]VoiceTestButton onCancel")
                },
                onError: { error in
                    print("[VIEW]VoiceTestButton onError \(error)")
                }
            ))
            tts!.speak(text)
        }) {
            Text("测试")
        }
    }
}

//class RealListener: NSObject, QCloudRealTTSListener {
//    func onFinish() {
//        print("[VIEW]RealListener onFinish")
//    }
//    
//    func onError(_ error: Error) {
//        print("[VIEW]RealListener onError \(error)")
//    }
//    
//    func onData(_ data: Data) {
//        print("[VIEW]RealListener onData \(data)")
//    }
//
//}
//
