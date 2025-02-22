import SwiftUI

class CapsuleButtonViewModel: ObservableObject {
    @Published var isVisible = true
    @Published var buttonText = "随机问题"
    @Published var buttonIcon = "shuffle"
    
    func toggleVisibility() {
        isVisible.toggle()
    }
    
    func updateButton(text: String, icon: String) {
        buttonText = text
        buttonIcon = icon
    }
} 