import SwiftUI

struct RoleCreatePage: View {
    var path: NavigationPath
    var config: Config
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var role: RoleBiz
    @State private var name: String = "assistant" // 默认名称
    @State private var desc: String = ""
    @State private var prompt: String = ""
    @State private var showingAvatarPicker = false
    @State private var selectedAvatar: String = "bot_avatar_1" // 修改默认头像
    
    // 可选的头像列表
    private let avatarOptions = (1...9).map { "bot_avatar\($0)" }
    
    init(path: NavigationPath, config: Config) {
        self.config = config
        self.path = path
        
        // 创建一个新的角色实例
        let newRole = RoleBiz(props: RoleProps(id: UUID()))
        _role = StateObject(wrappedValue: newRole)
    }
    
    private func saveRole() {
        role.name = name
        role.prompt = prompt
        role.desc = desc
        role.avatar = selectedAvatar // 设置选中的头像
        
        // 保存角色到配置中
        //        config.addRole(role: role)
        dismiss()
    }
    
    var body: some View {
        List {
            Section(header:
                        Text("基本信息")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            ) {
                VStack(spacing: 24) {
                    // 头像和名称垂直布局
                    VStack(spacing: 16) {
                        // 头像选择
                        Image(selectedAvatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(DesignSystem.Colors.secondaryBackground, lineWidth: 1)
                            )
                            .onTapGesture {
                                showingAvatarPicker = true
                            }
                        
                        // 昵称输入
                        TextField("角色昵称", text: $name, prompt: Text("请输入角色昵称"))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 200) // 限制输入框宽度
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()

                     // 提示词输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("角色描述")
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextEditor(text: $desc)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(DesignSystem.Colors.secondaryBackground, lineWidth: 1)
                            )
                    }

                    Divider()
                    
                    // 提示词输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("角色设定")
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextEditor(text: $prompt)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(DesignSystem.Colors.secondaryBackground, lineWidth: 1)
                            )
                    }
                }
                .padding(.vertical, 8)
            }
            
            // 复用 RoleDetailPage 中的配置部分
            RoleLLMProviderSettingView(role: role, config: config)
            RoleTTSProviderSettingView(role: role, config: config)
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("创建角色")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveRole()
                }
                .disabled(name.isEmpty)
            }
        }
        .sheet(isPresented: $showingAvatarPicker) {
            AvatarPickerView(selectedAvatar: $selectedAvatar)
        }
    }
}

// 头像选择器视图
struct AvatarPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedAvatar: String
    private let avatarOptions = (1...9).map { "bot_avatar_\($0)" }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(avatarOptions, id: \.self) { avatar in
                        Image(avatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(selectedAvatar == avatar ? 
                                           DesignSystem.Colors.primary : Color.clear, 
                                           lineWidth: 3)
                            )
                            .onTapGesture {
                                selectedAvatar = avatar
                                dismiss()
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("选择头像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}
