import SwiftUI

struct LLMProvider: Identifiable {
    let id = UUID()
    let name: String
    let logo: String // SF Symbol name
    var models: [LLMModel]  // 改为 var，使其可变
    var isEnabled: Bool
    var apiKey: String
}

struct LLMModel: Identifiable {
    let id = UUID()
    let name: String
    var isEnabled: Bool
}

struct LanguageModelSettingsView: View {
    @State private var providers: [LLMProvider] = [
        LLMProvider(
            name: "OpenAI",
            logo: "brain",
            models: [
                LLMModel(name: "GPT-4", isEnabled: true),
                LLMModel(name: "GPT-3.5-Turbo", isEnabled: true)
            ],
            isEnabled: true,
            apiKey: ""
        ),
        LLMProvider(
            name: "Anthropic",
            logo: "sparkles",
            models: [
                LLMModel(name: "Claude 3 Opus", isEnabled: true),
                LLMModel(name: "Claude 3 Sonnet", isEnabled: true)
            ],
            isEnabled: false,
            apiKey: ""
        ),
        LLMProvider(
            name: "Gemini",
            logo: "circle.hexagongrid.fill",
            models: [
                LLMModel(name: "Gemini Pro", isEnabled: true),
                LLMModel(name: "Gemini Ultra", isEnabled: false)
            ],
            isEnabled: false,
            apiKey: ""
        )
    ]
    
    var body: some View {
        List {
            ForEach($providers) { $provider in
                Section {
                    // Provider 开关
                    Toggle(isOn: $provider.isEnabled) {
                        HStack {
                            Image(systemName: provider.logo)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text(provider.name)
                                .font(.headline)
                        }
                    }
                    
                    if provider.isEnabled {
                        // API Key 输入框
                        HStack {
                            SecureField("API Key", text: $provider.apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            if !provider.apiKey.isEmpty {
                                Button(action: {
                                    provider.apiKey = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        // 模型列表
                        ForEach($provider.models) { $model in
                            Toggle(isOn: $model.isEnabled) {
                                Text(model.name)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("语言模型设置")
    }
}

#Preview {
    NavigationView {
        LanguageModelSettingsView()
    }
} 