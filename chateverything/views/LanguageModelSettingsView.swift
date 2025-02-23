import SwiftUI
import LLM

struct LanguageModelSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    // var controllers: [LLMProviderController] = Config.shared.languageProviderControllers
    @EnvironmentObject var config: Config

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("语言模型提供商")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                ) {
                    ForEach(config.languageProviderControllers) { controller in
                        ProviderSettingsView(
                            controller: controller,
                            provider: controller.provider,
                            value: controller.value,
                            config: config
                        )
                    }
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("模型设置")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    LanguageModelSettingsView()
} 
