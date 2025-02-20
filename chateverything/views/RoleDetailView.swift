import SwiftUI
import LLM

// 子视图
struct ModelListView: View {
    let provider: LanguageProvider
    @ObservedObject var llm: LLMService
    // @State private var selectedModel: String
    
    init(provider: LanguageProvider, llm: LLMService) {
        self.provider = provider
        self.llm = llm
        // 初始化 selectedModel
        // _selectedModel = State(initialValue: llm.value.model)
    }
    
    var body: some View {
        ForEach(provider.models, id: \.id) { sub in
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
                let matchedProvider = Config.shared.languageValues.first(where: { $0.provider == provider.name })
                guard let matchedProvider = matchedProvider else {
                    return
                }
                llm.update(value: LLMValues(provider: matchedProvider.provider, model: sub.name, apiProxyAddress: matchedProvider.apiProxyAddress, apiKey: matchedProvider.apiKey))
                // 手动更新选中的模型
                // selectedModel = sub.name
            }
        }
    }
}

struct EnabledLanguageModelsView: View {
    @State var providers = Config.shared.languageProviders
    @State var values = Config.shared.languageValues
    @State var role: RoleBiz
    @State var session: ChatSessionBiz

    // 添加派生字段，过滤掉 isEnabled 为 false 的值
    private var enabledValues: [LanguageProvider] {
        providers.filter { provider in
            if let value = values.first(where: { $0.provider == provider.name }) {
                return value.isEnabled
            }
            return false
        }
    }
    
    var body: some View {
        ForEach(providers, id: \.id) { (provider: LanguageProvider) in
                Section {
                    ModelListView(provider: provider, llm: self.session.llm)
                } header: {
                    HStack {
                        Image(provider.logo_uri)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        Text(provider.name)
                    }
                }
            }
    }
}

struct RoleDetailView: View {
    let role: RoleBiz
    let session: ChatSessionBiz

    var body: some View {
        List {
            // 头部卡片
            Section {
                HStack(spacing: 20) {
                    // 头像占位
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Text(role.name)
                        .font(.title)
                        .foregroundStyle(.primary)
                }
                .padding(.vertical)
            }

            EnabledLanguageModelsView(role: role, session: session)
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("角色详情")
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

