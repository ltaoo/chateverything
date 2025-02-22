import SwiftUI
import CoreData
import Foundation

struct RoleSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: ChatStore
    @Binding var path: NavigationPath
    @StateObject private var viewModel = RoleSelectionViewModel()
    @State private var isLoading = false
    
    var onCancel: () -> Void
    
    var body: some View {
        ZStack {
            VStack {
                List {
                    ForEach(viewModel.roles, id: \.id) { role in
                        RoleCard(role: role, onTap: {
                            DispatchQueue.main.async {
                                isLoading = true
                            }
                            // store.addSession(id: UUID(), user1_id: role.id, user2_id: Config.shared.userId)
    // DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
    //                                 isLoading = false
    //                                     path.append(Route.ChatDetailView(roleId: role.id))
    //                             }
                            // viewModel.createChatSession(for: role, in: viewContext) { success in
                            //     DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            //         isLoading = false
                            //         if success {
                            //             path.append(Route.ChatDetailView(roleId: role.id))
                            //         }
                            //     }
                            // }
                        })
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
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            }
        }
        .onAppear {
            // viewModel.fetchRoles(from: viewContext)
            viewModel.roles = DefaultRoles
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

class RoleSelectionViewModel: ObservableObject {
    @Published var roles: [RoleBiz] = []
    
    func fetchRoles(from context: NSManagedObjectContext) {
//        let request = NSFetchRequest<Role>(entityName: "Role")
//        
//        do {
//            let fetchedRoles = try context.fetch(request)
//            var results: [RoleBiz] = []
//            
//            fetchedRoles.forEach { role in
//                if let roleBiz = RoleBiz.from(role, config: config) {
//                    results.append(roleBiz)
//                }
//            }
//            
//            DispatchQueue.main.async {
//                self.roles = results
//            }
//        } catch {
//            print("Error fetching roles: \(error)")
//        }
    }
    
    func createChatSession(for role: RoleBiz, in context: NSManagedObjectContext, completion: @escaping (Bool) -> Void) {
        // guard let entity = NSEntityDescription.entity(forEntityName: "ChatSession", in: context) else {
        //     completion(false)
        //     return
        // }
        
        // let session = ChatSession(entity: entity, insertInto: context)
        // session.id = UUID()
        // session.user1_id = role.id
        // session.user2_id = Config.shared.userId
        // session.created_at = Date()
        
        // do {
        //     try context.save()
        //     completion(true)
        // } catch {
        //     print("Error saving chat session: \(error)")
        //     completion(false)
        // }
    }
} 
