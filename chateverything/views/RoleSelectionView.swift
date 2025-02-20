import SwiftUI
import CoreData
import Foundation


struct RoleSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    @State private var roles: [RoleBiz] = []
    @State private var isLoading = false  // 添加 loading 状态

    var onCancel: () -> Void
    
    func fetchRoles() {
	let r = NSFetchRequest<Role>(entityName: "Role")
        // let request = RoleEntity.fetchRequest()
        // request.sortDescriptors = [NSSortDescriptor(keyPath: \RoleEntity.created_at, ascending: false)]
        
        do {
            let fetchedRoles = try! viewContext.fetch(r) as [Role]
        //     roles = fetchedRoles
            
            // 打印每个角色的详细信息
        //     print("获取到 \(fetchedRoles.count) 个角色:")
	     var results: [RoleBiz] = []
        fetchedRoles.forEach({ (role) in
            results.append(RoleBiz.from(role)!)
        })
	DispatchQueue.main.async {
		self.roles = results
		// self.isLoading = false  // 数据加载完成后隐藏 loading
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
        //     self.isLoading = false  // 发生错误时也要隐藏 loading
        }
    }
    
    var body: some View {
        ZStack {  // 使用 ZStack 来叠加显示 loading
            VStack {
                List {
                    ForEach(roles, id: \.id) { role in
                    //     NavigationLink(destination: ChatDetailView()) {
                            RoleCard(role: role, onTap: {
				onCancel()
				DispatchQueue.main.async {
					isLoading = true
				}
				print("onTap \(role.name)")
				// 添加 200ms 延迟
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
					isLoading = false
					path.append(Route.ChatDetailView(roleId: role.id))  // 携带角色参数
				}
			})
                    //     }
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
            
            if isLoading {
                ProgressView()  // 显示系统默认的 loading 指示器
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            }
        }
        .onAppear {
            fetchRoles()
        }
    }
}

struct RoleCard: View {
    let role: RoleBiz
    var onTap: () -> Void
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(role.name ?? "未命名")
                    .font(.headline)
            }
            .onTapGesture {
                onTap()
            }
        }
        .padding(.vertical, 8)
    }
}

// #Preview {
//     RoleSelectionView()
// } 
