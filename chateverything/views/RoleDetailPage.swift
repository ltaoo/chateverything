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
        Group {
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

                    // EnabledLanguageModelsView(role: self.role, session: self.session)
                    
                    // 添加 TTS 设置部分
                    TTSSettingsView(role: self.role)
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

// 添加 TTS 设置视图
struct TTSSettingsView: View {
    @ObservedObject var role: RoleBiz
    @State private var selectedEngine: TTSEngineOption = TTSEngineOptions[0]
    @State private var selectedRole: TTSEngineRole? = TTSEngineOptions[0].roles[0]
    
    var body: some View {
        Section(header: Text("语音设置")
            .font(DesignSystem.Typography.bodyMedium)
            .foregroundColor(DesignSystem.Colors.textSecondary)) {
            Picker("语音引擎", selection: $selectedEngine) {
                ForEach(TTSEngineOptions, id: \.name) { option in
                    Text(option.name)
                        .font(DesignSystem.Typography.bodyMedium)
                        .tag(option)
                }
            }
            
            Picker("语音角色", selection: $selectedRole) {
                ForEach(selectedEngine.roles, id: \.voice) { role in
                    Text(role.name)
                        .font(DesignSystem.Typography.bodyMedium)
                        .tag(Optional(role))
                }
            }
            .onChange(of: selectedEngine) { newEngine in
                // 当切换引擎时，自动选择第一个角色
                selectedRole = newEngine.roles.first
            }
            
            if selectedEngine.name == "系统" {
                SystemTTSSettingsView(role: role)
            } else if selectedEngine.name == "腾讯云" {
                TencentCloudTTSSettingsView(role: role)
            }
        }
    }
}

struct SystemTTSSettingsView: View {
    @ObservedObject var role: RoleBiz
    @State private var volume: Double = 0.5
    @State private var speed: Double = 1.0
    @State private var selectedLanguage: String = "zh-CN"
    
    let languages = ["zh-CN", "en-US", "ja-JP"]
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            Picker("语言", selection: $selectedLanguage) {
                ForEach(languages, id: \.self) { language in
                    Text(language)
                        .font(DesignSystem.Typography.bodyMedium)
                        .tag(language)
                }
            }
            
            HStack {
                Text("音量")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Slider(value: $volume, in: 0...1)
                    .accentColor(DesignSystem.Colors.primary)
                Text("\(Int(volume * 100))%")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            HStack {
                Text("语速")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Slider(value: $speed, in: 0.5...2)
                    .accentColor(DesignSystem.Colors.primary)
                Text("\(speed, specifier: "%.1f")x")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.small)
    }
}

struct TencentCloudTTSSettingsView: View {
    @ObservedObject var role: RoleBiz
    @State private var volume: Double = 0.5
    @State private var speed: Double = 1.0
    @State private var selectedLanguage: String = "zh"
    @State private var selectedVoice: String = "zhibei"
    
    let languages = ["zh": "中文", "en": "英语", "jp": "日语"]
    let voices = [
        "zhibei": "智贝",
        "zhibei2": "智贝2",
        "xiaoyan": "晓燕",
        "xiaogang": "晓刚"
    ]
    
    var body: some View {
        VStack {
            Picker("语言", selection: $selectedLanguage) {
                ForEach(Array(languages.keys), id: \.self) { key in
                    Text(languages[key] ?? "").tag(key)
                }
            }
            
            Picker("声音", selection: $selectedVoice) {
                ForEach(Array(voices.keys), id: \.self) { key in
                    Text(voices[key] ?? "").tag(key)
                }
            }
            
            HStack {
                Text("音量")
                Slider(value: $volume, in: 0...1)
                Text("\(Int(volume * 100))%")
            }
            
            HStack {
                Text("语速")
                Slider(value: $speed, in: 0.5...2)
                Text("\(speed, specifier: "%.1f")x")
            }
        }
    }
}

// 子视图
struct ModelListView: View {
    let controller: LLMProviderController
    @ObservedObject var llm: LLMService
    // @State private var selectedModel: String
    
    init(controller: LLMProviderController, llm: LLMService) {
        self.controller = controller
        self.llm = llm
        // 初始化 selectedModel
        // _selectedModel = State(initialValue: llm.value.model)
    }
    
    var body: some View {
        ForEach(controller.models, id: \.id) { sub in
            HStack {
                Text(sub.name)
                Spacer()
                if sub.name == llm.value.model {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
//                let matchedProvider = Config.shared.languageProviderValues.first(where: { $0.provider == provider.name })
//                guard let matchedProvider = matchedProvider else {
//                    return
//                }
//                llm.update(value: LLMValues(provider: matchedProvider.provider, model: sub.name, apiProxyAddress: matchedProvider.apiProxyAddress, apiKey: matchedProvider.apiKey))
                // 手动更新选中的模型
                // selectedModel = sub.name
            }
        }
    }
}

struct EnabledLanguageModelsView: View {
    @EnvironmentObject var config: Config
    @State var providers: [LLMProviderController] = []
    // @State var values = Config.shared.languageProviderValues
    @ObservedObject var role: RoleBiz
    @ObservedObject var session: ChatSessionBiz

    init(role: RoleBiz, session: ChatSessionBiz) {
        self.role = role
        self.session = session

        _providers = State(initialValue: config.enabledProviders)
    }

    // 添加派生字段，过滤掉 isEnabled 为 false 的值
//    private var enabledValues: [LanguageProvider] {
//        providers.filter { provider in
//            if let value = values.first(where: { $0.provider == provider.name }) {
//                return value.isEnabled
//            }
//            return false
//        }
//    }
    
    var body: some View {
        ForEach(providers, id: \.id) { (provider: LLMProviderController) in
                Section {
                    Text("Hello")
//                    ModelListView(controller: provider, llm: self.session.llm)
                } header: {
                    HStack {
                        Image(provider.provider.logo_uri)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        Text(provider.provider.name)
                    }
                }
            }
    }
}
