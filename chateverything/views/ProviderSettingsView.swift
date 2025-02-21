import SwiftUI
import LLM


struct ProviderSettingsView: View {
    @ObservedObject var controller: LLMProviderController
    var provider: LanguageProvider
    @ObservedObject var value: ProviderValue
    @State private var newModelName: String = ""
    @State private var showingAddModelDialog = false
    
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
                    }
                ))
            }
            
            if value.enabled {
                // API 设置
                TextField("API 代理地址", text: Binding(
                    get: { value.apiProxyAddress ?? "" },
                    set: { address in
                        value.apiProxyAddress = address
                    }
                ), prompt: Text(provider.apiProxyAddress))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading, 40)
                
                SecureField("API Key", text: Binding(
                    get: { value.apiKey },
                    set: { key in
                        value.apiKey = key
                    }
                ), prompt: Text("请输入您的 API Key"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading, 40)
                
                // 默认模型列表
                Text("模型")
                    .font(.headline)
                    .padding(.top)
                    .padding(.leading, 40)
                
                ForEach(controller.models){ model in
                    ModelToggleRow(model: model)
                }
                
                Button(action: {
                    showingAddModelDialog = true
                }) {
                    Label("添加自定义模型", systemImage: "plus.circle")
                }
                .padding(.leading, 40)
                .padding(.top, 8)
            }
        }
        .alert("添加自定义模型", isPresented: $showingAddModelDialog) {
            TextField("模型名称", text: $newModelName)
            Button("取消", role: .cancel) {
                newModelName = ""
            }
            Button("确定") {
                if !newModelName.isEmpty {
                    controller.addCustomModel(name: newModelName)
                    newModelName = ""
                }
            }
        } message: {
            Text("请输入要添加的模型名称")
        }
    }
} 


struct ModelToggleRow: View {
    let model: LLMProviderModelController
    
    var body: some View {
        HStack {
            Text(model.name)
                .padding(.leading, 40)
            Spacer()
            Toggle("", isOn: Binding(
                get: { model.enabled },
                set: { enabled in
                    model.enabled = enabled
                }
            ))
        }
    }
} 
