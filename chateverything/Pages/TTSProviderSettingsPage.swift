import SwiftUI

struct TTSProviderSettingsPage: View {
    @EnvironmentObject var config: Config
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("TTS")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                ) {
                    ForEach(config.ttsProviderControllers) { controller in
                        TTSProviderSettingView(
                            controller: controller,
                            provider: controller.provider,
                            value: controller.value,
                            config: config
                        )
                    }
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("TTS 设置")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TTSProviderSettingView: View {
    @ObservedObject var controller: TTSProviderController
    var provider: TTSProvider
    @ObservedObject var value: TTSProviderValue
    @ObservedObject var config: Config
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Image(provider.logo_uri)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                Text(provider.name)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { value.enabled },
                    set: { enabled in
                       value.update(enabled: enabled)
                        config.updateSingleTTSProviderValue(id: provider.id, value: value)
                    }
                )).disabled(provider.id == "system")
                .tint(DesignSystem.Colors.primary)
            }
            
            if value.enabled {
                credentialFieldsView
            }
        }
    }

    func handleChange() {
        if let credential = provider.credential {
            let r = credential.validate()
            if r.isValid {
                value.credential = r.value as? [String:String] ?? [:]
                config.updateSingleTTSProviderValue(id: provider.id, value: value)
            }
        }
    }
    
    @ViewBuilder
    private var credentialFieldsView: some View {
        if let credential = provider.credential {
            ForEach(credential.fields.sorted(by: { $0.key < $1.key }), id: \.key) { key, field in
                switch field {
                case .single(let formField):
                    if case .InputString(let input) = formField.input {
                        TextField(
                            formField.label,
                            text: Binding(
                                get: { input.value as? String ?? "" },
                                set: { newValue in
                                    input.setValue(value: newValue)
                                    self.handleChange()
                                }
                            )
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 4)
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


#Preview {
    TTSProviderSettingsPage()
} 
