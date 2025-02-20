import SwiftUI
import CoreData

struct RoleSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var roles: [RoleBiz] = []
    
    func fetchRoles() {
	let r = NSFetchRequest<Role>(entityName: "Role")
        // let request = RoleEntity.fetchRequest()
        // request.sortDescriptors = [NSSortDescriptor(keyPath: \RoleEntity.created_at, ascending: false)]
        
        do {
            let fetchedRoles = try! viewContext.fetch(r) as [Role]
        //     roles = fetchedRoles
            
            // 打印每个角色的详细信息
            print("获取到 \(fetchedRoles.count) 个角色:")
	     var results: [RoleBiz] = []
        fetchedRoles.forEach({ (role) in
            results.append(RoleBiz.from(role)!)
        })
	DispatchQueue.main.async {
		self.roles = results
	}
        //     for (index, role) in fetchedRoles.enumerated() {
        //         print("""
        //             角色 \(index + 1):
        //             - 名称: \(role.name ?? "未命名")
        //             - 提示词: \(role.prompt ?? "无")
        //             - 创建时间: \(role.created_at ?? Date())
        //             ----------------------
        //             """)
        //     }
        } catch {
            print("Error fetching roles: \(error)")
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(roles, id: \.id) { role in
                    RoleRow(role: role)
                        .onTapGesture {
                            // 选择角色后的处理
                            dismiss()
                        }
                }
            }
            .navigationTitle("选择角色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            fetchRoles()
        }
    }
}

struct RoleRow: View {
    let role: RoleBiz
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(role.name ?? "未命名")
                    .font(.headline)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    RoleSelectionView()
} 
