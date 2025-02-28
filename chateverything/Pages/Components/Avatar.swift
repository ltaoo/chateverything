import SwiftUI

enum AvatarSource {
    case asset(String)         // For images in Assets
    case network(String)       // For network URLs
    case data(Data)           // For image data
    
    var stringValue: String {
        switch self {
        case .asset(let name): return "asset://" + name
        case .network(let url): return url
        case .data(_): return "data://avatar"
        }
    }
    
    static func from(_ string: String) -> AvatarSource {
        if string.hasPrefix("http://") || string.hasPrefix("https://") {
            return .network(string)
        }
        return .asset(string)
    }
} 

struct Avatar: View {
    let source: AvatarSource
    var size: CGFloat = 40
    
    init(source: AvatarSource, size: CGFloat = 40) {
        self.source = source
        self.size = size
    }
    
    // Convenience initializer for string-based avatars
    init(uri: String, size: CGFloat = 40) {
        self.init(source: AvatarSource.from(uri), size: size)
    }
    
    var body: some View {
        Group {
            switch source {
            case .network(let url):
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        Image(systemName: "person.circle.fill")
                            .resizable()
                    case .empty:
                        ProgressView()
                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                    }
                }
                
            case .asset(let name):
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                
            case .data(let imageData):
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// Preview
struct Avatar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Asset image preview
            Avatar(source: .asset("default_avatar"), size: 60)
            
            // Network image preview
            Avatar(source: .network("https://example.com/avatar.jpg"), size: 80)
            
            // Data image preview
            Avatar(source: .data(UIImage(systemName: "person")!.pngData()!), size: 100)
            
            // String-based initialization
            Avatar(uri: "default_avatar")
            Avatar(uri: "https://example.com/avatar.jpg")
        }
    }
}
