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
        VStack(alignment: .leading) {
            HStack {
                    Image(provider.logo_uri)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                Text(provider.name)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { value.enabled },
                    set: { enabled in
                        value.update(enabled: enabled)
                        config.updateSingleProviderValue(name: provider.name, value: value)
                    }
                ))
            }
            
            if value.enabled {
                // API 设置
                TextField("API 代理地址", text: Binding(
                    get: { value.apiProxyAddress ?? "" },
                    set: { address in
                        value.apiProxyAddress = address
                        config.updateSingleProviderValue(name: provider.name, value: value)
                    }
                ), prompt: Text(provider.apiProxyAddress))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading, 40)
                
                SecureField("API Key", text: Binding(
                    get: { value.apiKey },
                    set: { key in
                        value.apiKey = key
                        config.updateSingleProviderValue(name: provider.name, value: value)
                    }
                ), prompt: Text("请输入您的 API Key"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading, 40)
                
                // 默认模型列表
                Text("模型")
                    .font(.headline)
                    .padding(.top)
                    .padding(.leading, 40)
                
                ForEach(Array(controller.models.enumerated()), id: \.element.id) { index, model in
                    ModelToggleRow(controller: controller, model: controller.models[index], config: config, onChange: {
                        controller.updateValueModels()
                        for model in controller.models {
                            print("model: \(model.isDefault) \(model.name) \(model.enabled)")
                        }
                        for model in value.models1 {
                            print("model1: \(model.name) \(model.enabled)")
                        }
                        for model in value.models2 {
                            print("model2: \(model)")
                        }
                        config.updateSingleProviderValue(name: provider.name, value: value)
                    })
                }
                
                HStack {
                    Button(action: {
                        showingAddModelDialog = true
                    }) {
                        Label("添加自定义模型", systemImage: "plus.circle")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.borderless)
                    Spacer()
                }
                .padding(.leading, 40)
                .padding(.top, 8)
            }
        }
        .sheet(isPresented: $showingAddModelDialog) {
            NavigationView {
                Form {
                    TextField("模型名称", text: $newModelName)
                }
                .navigationTitle("添加自定义模型")
                .navigationBarItems(
                    leading: Button("取消") {
                        newModelName = ""
                        showingAddModelDialog = false
                    },
                    trailing: Button("确定") {
                        print("click ok: \(newModelName)")
                        if !newModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            controller.addCustomModel(name: newModelName)
                            config.updateSingleProviderValue(name: provider.name, value: value)
                        }
                        newModelName = ""
                        showingAddModelDialog = false
                    }
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
                .padding(.leading, 40)
            Spacer()
            if !model.isDefault {
                Button(action: {
                    controller.removeCustomModel(name: model.name)
                    onChange()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
                .padding(.trailing, 8)
            }
            Toggle("", isOn: Binding(
                get: { model.enabled },
                set: { enabled in
                    model.enabled = enabled
                    onChange()
                }
            ))
        }
    }
} 
