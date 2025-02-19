import SwiftUI
import LLM

struct ChatConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    var onConfirm: (LanguageModel, String) -> Void
    
    @State private var selectedRole: String = "General Chat"
    @State private var selectedModel: LanguageModel = LanguageModel(
        providerName: "doubao",
        id: "ep-20250205141518-nvl9p",
        name: "ep-20250205141518-nvl9p",
        apiKey: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhcmstY29uc29sZSIsImV4cCI6MTczOTk5MjgxMCwiaWF0IjoxNzM5OTU2ODEwLCJ0IjoidXNlciIsImt2IjoxLCJhaWQiOiIyMTAyMDM0ODI1IiwidWlkIjoiMCIsImlzX291dGVyX3VzZXIiOnRydWUsInJlc291cmNlX3R5cGUiOiJlbmRwb2ludCIsInJlc291cmNlX2lkcyI6WyJlcC0yMDI1MDIwNTE0MTUxOC1udmw5cCJdfQ.Z1GxZIt9zPUHfTEsHm9FctiECbO0SxGGuCF5ZIMWG7J1FMRyvWvK2qCWCXvR8yEHRpxKCEg-y_uVAuBklv90PchOlalJy_nvRidKrptzNJSjRVPFjZCKFd_cwEoqPv3NV-ltH3fc3HJCq0abuU6UR_gKY__Tl2qwcjUnr0tXjit71w9wQM6CQGB_49NvQdbq087ISZmC3yi0XSPVyN2b2F0WBp6lxZUCxdwbKtxVZc0N_SRcJQPNxrgsgjmFxqCjTADZggVT_2sCzqsax0rtGFR8PypiPhnMJyT1FutscqCo69RptOlfFlGect4ol_S9RBa1uyhSK3B_ixfVya8S1g",
        apiProxyAddress: "https://ark.cn-beijing.volces.com/api/v3/chat/completions",
        responseHandler: { data in
            let decoder = JSONDecoder()
            let response = try decoder.decode(DoubaoChatResponse.self, from: data)
            return response.choices[0].message.content
        }
    )
    
    let roles = [
        "General Chat": "通用对话助手",
        "IELTS Speaking": "雅思口语考官",
        "Code Assistant": "代码助手",
        "Math Tutor": "数学导师",
        "Writing Helper": "写作助手"
    ]
    
    // 添加可用的模型列表
    let availableModels: [LanguageModel] = [
        LanguageModel(
            providerName: "doubao",
            id: "ep-20250205141518-nvl9p",
            name: "豆包大模型",
            apiKey: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhcmstY29uc29sZSIsImV4cCI6MTczOTk5MjgxMCwiaWF0IjoxNzM5OTU2ODEwLCJ0IjoidXNlciIsImt2IjoxLCJhaWQiOiIyMTAyMDM0ODI1IiwidWlkIjoiMCIsImlzX291dGVyX3VzZXIiOnRydWUsInJlc291cmNlX3R5cGUiOiJlbmRwb2ludCIsInJlc291cmNlX2lkcyI6WyJlcC0yMDI1MDIwNTE0MTUxOC1udmw5cCJdfQ.Z1GxZIt9zPUHfTEsHm9FctiECbO0SxGGuCF5ZIMWG7J1FMRyvWvK2qCWCXvR8yEHRpxKCEg-y_uVAuBklv90PchOlalJy_nvRidKrptzNJSjRVPFjZCKFd_cwEoqPv3NV-ltH3fc3HJCq0abuU6UR_gKY__Tl2qwcjUnr0tXjit71w9wQM6CQGB_49NvQdbq087ISZmC3yi0XSPVyN2b2F0WBp6lxZUCxdwbKtxVZc0N_SRcJQPNxrgsgjmFxqCjTADZggVT_2sCzqsax0rtGFR8PypiPhnMJyT1FutscqCo69RptOlfFlGect4ol_S9RBa1uyhSK3B_ixfVya8S1g",
            apiProxyAddress: "https://ark.cn-beijing.volces.com/api/v3/chat/completions",
            responseHandler: { data in
                let decoder = JSONDecoder()
                let response = try decoder.decode(DoubaoChatResponse.self, from: data)
                return response.choices[0].message.content
            }
        ),
        LanguageModel(
            providerName: "deepseek",
            id: "deepseek-chat",
            name: "DeepSeek Chat",
            apiKey: "sk-292831353cda4d1c9f59984067f24379",
            apiProxyAddress: "https://api.deepseek.com/chat/completions",
            responseHandler: { data in
                let decoder = JSONDecoder()
                let response = try decoder.decode(DeepseekChatResponse.self, from: data)
                return response.choices[0].message.content
            }
        )
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("选择角色")) {
                    ForEach(Array(roles.keys.sorted()), id: \.self) { role in
                        RoleRowView(
                            role: role,
                            description: roles[role] ?? "",
                            isSelected: role == selectedRole,
                            onSelect: { selectedRole = role }
                        )
                    }
                }
                
                Section(header: Text("语言模型")) {
                    ForEach(availableModels, id: \.id) { model in
                        ModelRowView(
                            model: model,
                            isSelected: model.id == selectedModel.id,
                            onSelect: { selectedModel = model }
                        )
                    }
                }
                
                Section(header: Text("角色说明")) {
                    Text(getRoleDescription(selectedRole))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                }
            }
            .navigationTitle("新对话配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") {
                        let prompt = getPromptForRole(selectedRole)
                        onConfirm(selectedModel, prompt)
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func getRoleDescription(_ role: String) -> String {
        switch role {
            case "IELTS Speaking":
                return "模拟雅思口语考试环境，提供专业的口语评分和改进建议"
            case "Code Assistant":
                return "帮助解决编程问题，提供代码示例和技术指导"
            case "Math Tutor":
                return "提供数学概念讲解和习题辅导，帮助理解数学知识"
            case "Writing Helper":
                return "协助改进写作内容，提供修改建议和写作技巧指导"
            default:
                return "全能助手，可以回答各类问题，提供全方位帮助"
        }
    }
    
    private func getPromptForRole(_ role: String) -> String {
        switch role {
            case "IELTS Speaking":
                return "You are an IELTS speaking examiner. Conduct a simulated IELTS speaking test by asking questions one at a time. After receiving each response with pronunciation scores from speech recognition, evaluate the answer and proceed to the next question. Do not ask multiple questions at once. After all sections are completed, provide a comprehensive evaluation and an estimated IELTS speaking band score. Begin with the first question."
            case "Code Assistant":
                return "You are an experienced programmer. Help answer programming questions, debug code, and provide coding solutions with clear explanations."
            case "Math Tutor":
                return "You are a patient math tutor. Help explain mathematical concepts, solve problems step by step, and provide practice exercises when needed."
            case "Writing Helper":
                return "You are a writing assistant. Help with writing, editing, and improving text while explaining the suggested changes."
            default:
                return "You are a helpful assistant. Provide clear and accurate responses to questions and engage in natural conversation."
        }
    }
}

// 角色行视图组件
struct RoleRowView: View {
    let role: String
    let description: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(description)
                    .font(.body)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .padding(.vertical, 4)
    }
}

// 模型行视图组件
struct ModelRowView: View {
    let model: LanguageModel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.body)
                Text(model.providerName)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .padding(.vertical, 4)
    }
} 