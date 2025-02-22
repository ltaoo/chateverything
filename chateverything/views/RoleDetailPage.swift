import SwiftUI
import LLM

struct RoleDetailView: View {
//    let model: ChatDetailViewModel
    let role: RoleBiz
    let session: ChatSessionBiz

    var body: some View {
        List {
            // 头部卡片
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 20) {
                        // 头像
                            Image(role.avatar)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(role.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            // if let description = role.description {
                            //     Text(description)
                            //         .font(.subheadline)
                            //         .foregroundStyle(.secondary)
                            //         .lineLimit(2)
                            // }
                        }
                    }
                }
                .padding(.vertical, 12)
            }

            EnabledLanguageModelsView(role: self.role, session: self.session)
            
            // 添加 TTS 设置部分
            TTSSettingsView(role: self.role)
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("角色详情")
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

// 添加 TTS 设置视图
struct TTSSettingsView: View {
    @ObservedObject var role: RoleBiz
    @State private var selectedEngine: TTSEngineOption = TTSEngineOptions[0]
    @State private var selectedRole: TTSEngineRole? = TTSEngineOptions[0].roles[0]
    
    var body: some View {
        Section(header: Text("语音设置")) {
            Picker("语音引擎", selection: $selectedEngine) {
                ForEach(TTSEngineOptions, id: \.name) { option in
                    Text(option.name).tag(option)
                }
            }
            
            // 添加语音角色选择
            Picker("语音角色", selection: $selectedRole) {
                ForEach(selectedEngine.roles, id: \.voice) { role in
                    Text(role.name)
                        .tag(Optional(role))  // 使用 Optional 包装是因为 selectedRole 是可选类型
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
        VStack {
            Picker("语言", selection: $selectedLanguage) {
                ForEach(languages, id: \.self) { language in
                    Text(language).tag(language)
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
