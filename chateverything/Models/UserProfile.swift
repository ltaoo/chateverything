import SwiftUI

class UserProfile: ObservableObject {
    @Published var nickname: String {
        didSet {
            UserDefaults.standard.set(nickname, forKey: "userNickname")
        }
    }
    
    @Published var avatarImage: UIImage? {
        didSet {
            if let imageData = avatarImage?.jpegData(compressionQuality: 0.8) {
                UserDefaults.standard.set(imageData, forKey: "userAvatar")
            }
        }
    }
    
    init() {
        // Load saved nickname or use default
        self.nickname = UserDefaults.standard.string(forKey: "userNickname") ?? "新用户"
        
        // Load saved avatar
        if let imageData = UserDefaults.standard.data(forKey: "userAvatar"),
           let image = UIImage(data: imageData) {
            self.avatarImage = image
        } else {
            self.avatarImage = nil
        }
    }
} 