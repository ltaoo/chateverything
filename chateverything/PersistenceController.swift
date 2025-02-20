import CoreData

class PersistenceController {
    static let shared = PersistenceController()
    static var container: NSPersistentContainer = {
                let container = NSPersistentContainer(name: "Model")
                container.loadPersistentStores { description, error in
                    if let error = error {
                         fatalError("Unable to load persistent stores: \(error)")
                    }
                }
                return container
            }()
        
        var context: NSManagedObjectContext {
            return Self.container.viewContext
        }
    
//    let container: NSPersistentContainer
    
    init() {
//        container = NSPersistentContainer(name: "Model")
        
//        container.loadPersistentStores { description, error in
//            if let error = error {
//                fatalError("loadPersistentStores Error: \(error.localizedDescription)")
//            }
//        }
        
//        let user = UserEntity(context: container.viewContext)
        // user.id = UUID()
        // user.name = "John Doe"
        // user.avatar = "https://example.com/avatar.png"
        // user.created_at = Date()
        // 创建默认角色
    }
} 
