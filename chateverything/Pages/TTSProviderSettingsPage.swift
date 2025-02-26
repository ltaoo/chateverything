import SwiftUI

struct TTSProviderSettingsPage: View {
    @EnvironmentObject var config: Config
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.medium) {
                ForEach(config.ttsProviderControllers) { controller in
                    TTSProviderSettingView(
                        controller: controller,
                        provider: controller.provider,
                        value: controller.value,
                        config: config
                    )
                }
            }
            .padding(DesignSystem.Spacing.medium)
        }
        .background(DesignSystem.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TTSProviderSettingView: View {
    @ObservedObject var controller: TTSProviderController
    var provider: TTSProvider
    @ObservedObject var value: TTSProviderValue
    @ObservedObject var config: Config
    
    var body: some View {
        VStack() {
            // Provider Header
            HStack {
                HStack {
                    Image(provider.logo_uri)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                    Text(provider.name)
                        .font(DesignSystem.Typography.bodyLarge)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { value.enabled },
                    set: { enabled in
                       value.update(enabled: enabled)
                        config.updateSingleTTSProviderValue(id: provider.id, value: value)
                    }
                ))
                .disabled(provider.id == "system")
                .tint(DesignSystem.Colors.primary)
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.secondaryBackground)
            
            if value.enabled {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                    credentialFieldsView
                }
                .padding(.vertical, DesignSystem.Spacing.cardPadding)
                .padding(.horizontal, DesignSystem.Spacing.cardPadding)
            }
        }
        .frame(maxWidth: .infinity)
        .shadow()
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
                if credential.orders.count > 0 {
                    ForEach(Array(credential.orders.enumerated()), id: \.element) { index, key in
                        if let field = credential.fields[key] {
                            switch field {
                            case .single(let formField):
                                if case .InputString(let input) = formField.input {
                                    Text(formField.label)
                                        .font(DesignSystem.Typography.bodyMedium)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
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
                                }
                                
                                // Only add Divider if this is not the last item
                                if index < credential.orders.count - 1 {
                                    Divider()
                                }
                            case .array(_):
                                EmptyView() // Handle array fields if needed
                            case .object(_):
                                EmptyView() // Handle object fields if needed
                            }
                        }
                    }
                } else {
                    Text("没有可配置的参数")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            } else {
                    Text("没有可配置的参数")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
            }
    }
} 


#Preview {
    TTSProviderSettingsPage()
} 
