import SwiftUI
import LLM


struct LanguageModelSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var providers: [LanguageProvider]
    @State private var selectedProvider: LanguageProvider?
    @State private var selectedModel: LanguageModel?
    
    init() {
        // 初始化时从 Config 读取配置
        _providers = State(initialValue: Config.shared.languageProviders)
        _selectedProvider = State(initialValue: Config.shared.languageProviders.first)
        _selectedModel = State(initialValue: Config.shared.languageProviders.first?.models.first)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Section(header: Text("选择提供商")) {
                //     Picker("提供商", selection: $selectedProvider) {
                //         ForEach(providers, id: \.name) { provider in
                //             Text(provider.name).tag(Optional(provider))
                //         }
                //     }
                // }
                
                // if let provider = selectedProvider {
                //     Section(header: Text("选择模型")) {
                //         Picker("模型", selection: $selectedModel) {
                //             ForEach(provider.models, id: \.id) { model in
                //                 Text(model.name).tag(Optional(model))
                //             }
                //         }
                //     }
                // }
                
                Section {
                    Button("保存") {
                        if let provider = selectedProvider,
                           let model = selectedModel {
                            // 更新 Config 中的配置
                            if let providerIndex = Config.shared.languageProviders.firstIndex(where: { $0.name == provider.name }) {
                                var updatedProviders = Config.shared.languageProviders
                                updatedProviders[providerIndex] = provider
                                // 这里需要在 Config 中添加一个方法来更新配置
                                Config.shared.updateProviders(updatedProviders)
                            }
                        }
                        dismiss()
                    }
                }
            }
            .navigationTitle("语言模型设置")
            .navigationBarItems(trailing: Button("取消") {
                dismiss()
            })
        }
    }
}

#Preview {
    NavigationView {
        LanguageModelSettingsView()
    }
} 