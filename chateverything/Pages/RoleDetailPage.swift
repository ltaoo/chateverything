import SwiftUI
import LLM

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

           if let provider = selectedProvider {
                form
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
