import SwiftUI

struct LLMProviderSettingsPage: View {
    @EnvironmentObject var config: Config
    @Environment(\.dismiss) private var dismiss

    var body: some View {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.medium) {
                    ForEach(config.llmProviderControllers) { controller in
                        LLMProviderSettingView(
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

struct LLMProviderSettingView: View {
    @ObservedObject var controller: LLMProviderController
    var provider: LLMProvider
    @ObservedObject var value: LLMProviderValue
    @ObservedObject var config: Config
    @State private var newModelName: String = ""
    @State private var showingAddModelDialog = false
    @State private var isShowingAlert = false
    
    var body: some View {
        VStack() {
            // Provider Header
            HStack() {
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
                        config.updateSingleLLMProviderValue(id: provider.id, value: value)
                    }
                ))
                .tint(DesignSystem.Colors.primary)
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.secondaryBackground)
            
            if value.enabled {
                // Provider Content
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                    // API Settings
                    Text("API 设置")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    TextField("API 代理地址", text: Binding(
                        get: { value.apiProxyAddress ?? "" },
                        set: { address in
                            value.apiProxyAddress = address
                            config.updateSingleLLMProviderValue(id: provider.id, value: value)
                        }
                    ), prompt: Text(provider.apiProxyAddress)
                        .foregroundColor(DesignSystem.Colors.textSecondary))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(DesignSystem.Typography.bodySmall)

                    Divider()
                    
                    Text("API Key")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    TextField("API Key", text: Binding(
                        get: { value.apiKey },
                        set: { key in
                            value.apiKey = key
                            config.updateSingleLLMProviderValue(id: provider.id, value: value)
                        }
                    ), prompt: Text("请输入您的 API Key")
                        .foregroundColor(DesignSystem.Colors.textSecondary))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(DesignSystem.Typography.bodyMedium)

                    Divider()
                    // Model List
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                        Text("Model List")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                            ForEach(Array(controller.models.enumerated()), id: \.element.id) { index, model in
                                ModelToggleRow(controller: controller, model: controller.models[index], config: config, onChange: {
                                    controller.updateValueModels()
                                    config.updateSingleLLMProviderValue(id: provider.id, value: value)
                                })
                            }
                            Button(action: {
                                showingAddModelDialog = true
                            }) {
                                Label("添加自定义模型", systemImage: "plus.circle")
                                    .font(DesignSystem.Typography.bodySmall)
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("校验")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        Spacer()
                        Button("Check") {
                            // TODO: Implement connectivity check
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DesignSystem.Colors.primary)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.cardPadding)
                .padding(.horizontal, DesignSystem.Spacing.cardPadding)
            }
        }
        .frame(maxWidth: .infinity)
        .shadow()
        .sheet(isPresented: $showingAddModelDialog) {
            NavigationView {
                Form {
                    TextField("模型名称", text: $newModelName)
                        .font(DesignSystem.Typography.bodyMedium)
                }
                .navigationTitle("添加自定义模型")
                .navigationBarItems(
                    leading: Button("取消") {
                        newModelName = ""
                        showingAddModelDialog = false
                    }
                    .foregroundColor(DesignSystem.Colors.primary),
                    trailing: Button("确定") {
                        if !newModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            controller.addCustomModel(name: newModelName)
                            config.updateSingleLLMProviderValue(id: provider.id, value: value)
                        }
                        newModelName = ""
                        showingAddModelDialog = false
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                )
            }
            .presentationDetents([.height(200)])
        }
    }
}

struct ModelToggleRow: View {
    let controller: LLMProviderController
    let model: LLMProviderModelController
    @ObservedObject var config: Config
    var onChange: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Text(model.name)
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            if !model.isDefault {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(DesignSystem.Colors.error)
                    .onTapGesture {
                        controller.removeCustomModel(name: model.name)
                        onChange()
                    }
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { model.enabled },
                set: { enabled in
                    model.enabled = enabled
                    onChange()
                }
            ))
            .tint(DesignSystem.Colors.primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LLMProviderSettingsPage()
} 
