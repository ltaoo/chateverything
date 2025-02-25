import Foundation
import CoreData

class ChatStore: ObservableObject {
    @Published var sessions: [ChatSessionBiz] = []
    
    public let container: NSPersistentContainer
    
    init(container: NSPersistentContainer) {
        self.container = container
    }
    
    func loadInitialSessions(limit: Int) {
    }
} 
