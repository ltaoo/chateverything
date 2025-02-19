import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "Model")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("loadPersistentStores Error: \(error.localizedDescription)")
            }
        }
        
        // 创建默认角色
        RoleEntity.createDefaultRoles(in: container.viewContext)
    }
} 
