import SwiftUI
import LLM


struct ProviderSettingsView: View {
    @ObservedObject var controller: LLMProviderController
    var provider: LanguageProvider
    @ObservedObject var value: ProviderValue
    @ObservedObject var config: Config
    @State private var newModelName: String = ""
    @State private var showingAddModelDialog = false
    @State private var isShowingAlert = false
    
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
                        config.updateSingleProviderValue(name: provider.name, value: value)
                    }
                ))
                .tint(DesignSystem.Colors.primary)
            }
            
            if value.enabled {
                // API 设置
                TextField("API 代理地址", text: Binding(
                    get: { value.apiProxyAddress ?? "" },
                    set: { address in
                        value.apiProxyAddress = address
                        config.updateSingleProviderValue(name: provider.name, value: value)
                    }
                ), prompt: Text(provider.apiProxyAddress)
                    .foregroundColor(DesignSystem.Colors.textSecondary))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(DesignSystem.Typography.bodyMedium)
                    .padding(.leading, DesignSystem.Spacing.xxLarge)
                
                SecureField("API Key", text: Binding(
                    get: { value.apiKey },
                    set: { key in
                        value.apiKey = key
                        config.updateSingleProviderValue(name: provider.name, value: value)
                    }
                ), prompt: Text("请输入您的 API Key")
                    .foregroundColor(DesignSystem.Colors.textSecondary))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(DesignSystem.Typography.bodyMedium)
                    .padding(.leading, DesignSystem.Spacing.xxLarge)
                
                Text("模型")
                    .font(DesignSystem.Typography.headingSmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding(.top, DesignSystem.Spacing.medium)
                    .padding(.leading, DesignSystem.Spacing.xxLarge)
                
                ForEach(Array(controller.models.enumerated()), id: \.element.id) { index, model in
                    ModelToggleRow(controller: controller, model: controller.models[index], config: config, onChange: {
                        controller.updateValueModels()
                        config.updateSingleProviderValue(name: provider.name, value: value)
                    })
                }
                
                HStack {
                    Button(action: {
                        showingAddModelDialog = true
                    }) {
                        Label("添加自定义模型", systemImage: "plus.circle")
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    .buttonStyle(.borderless)
                    Spacer()
                }
                .padding(.leading, DesignSystem.Spacing.xxLarge)
                .padding(.top, DesignSystem.Spacing.xSmall)
            }
        }
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
                            config.updateSingleProviderValue(name: provider.name, value: value)
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
        HStack {
            Text(model.name)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.leading, DesignSystem.Spacing.xxLarge)
            Spacer()
            if !model.isDefault {
                Button(action: {
                    controller.removeCustomModel(name: model.name)
                    onChange()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(DesignSystem.Colors.error)
                }
                .buttonStyle(.borderless)
                .padding(.trailing, DesignSystem.Spacing.xSmall)
            }
            Toggle("", isOn: Binding(
                get: { model.enabled },
                set: { enabled in
                    model.enabled = enabled
                    onChange()
                }
            ))
            .tint(DesignSystem.Colors.primary)
        }
    }
} 
