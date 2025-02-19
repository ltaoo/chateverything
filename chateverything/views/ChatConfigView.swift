import SwiftUI
import CoreData

struct ChatConfigView: View {
    @Binding var isPresented: Bool
    let onComplete: (RoleEntity?) -> Void
    
    // 添加 CoreData 获取请求
    @FetchRequest(
        entity: RoleEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \RoleEntity.name, ascending: true)]
    ) private var roles: FetchedResults<RoleEntity>
    
    @State private var selectedRole: RoleEntity?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("选择角色")) {
                    Picker("角色", selection: $selectedRole) {
                        Text("无").tag(Optional<RoleEntity>.none)
                        ForEach(roles, id: \.self) { role in
                            Text(role.name ?? "未命名").tag(Optional(role))
                        }
                    }
                }
                
                Section {
                    Button("开始对话") {
                        onComplete(selectedRole)
                        isPresented = false
                    }
                }
            }
            .navigationTitle("新对话")
            .navigationBarItems(trailing: Button("取消") {
                isPresented = false
            })
        }
    }
} 