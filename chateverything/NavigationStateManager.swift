import SwiftUI

public class NavigationStateManager: ObservableObject {
    @Published var currentView: AnyView?
    
    init() {
        self.currentView = nil
    }
    
    func navigateToChatDetail(view: some View) {
        withAnimation {
            currentView = AnyView(view)
        }
    }
    
    func navigateBack() {
        withAnimation {
            currentView = nil
        }
    }
} 