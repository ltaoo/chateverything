import SwiftUI
import CoreData

struct ChatConfigView: View {
    @Binding var isPresented: Bool
    let onComplete: (Role?) -> Void
    
    // 添加 CoreData 获取请求
    @FetchRequest(
        entity: Role.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Role.name, ascending: true)]
    ) private var roles: FetchedResults<Role>
    
    @State private var selectedRole: Role?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("选择角色")) {
                    Picker("角色", selection: $selectedRole) {
                        Text("无").tag(Optional<Role>.none)
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
