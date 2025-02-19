import SwiftUI

class NavigationStateManager: ObservableObject {
    @Published var path: [ChatDetailView] = []
    
    func navigate(to view: ChatDetailView) {
        path.append(view)
    }
    
    func navigateBack() {
        _ = path.popLast()
    }
    
    func navigateToRoot() {
        path.removeAll()
    }
} 