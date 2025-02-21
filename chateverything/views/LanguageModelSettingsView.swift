import SwiftUI
import LLM

struct LanguageModelSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    var controllers: [LLMProviderController] = Config.shared.languageProviderControllers
    
    var body: some View {
        Form {
            Section(header: Text("语言模型提供商")) {
                ForEach(controllers) { controller in
                    ProviderSettingsView(
                        controller: controller,
                        provider: controller.provider,
                        value: controller.value
                    )
                }
            }
        }
    }
}

#Preview {
    LanguageModelSettingsView()
} 
