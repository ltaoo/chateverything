import SwiftUI

struct Avatar: View {
    let uri: String
    var size: CGFloat = 40 // 默认大小

    init(uri: String, size: CGFloat = 40) {
        self.uri = uri
        self.size = size
    }
    
    private var isNetworkImage: Bool {
        uri.hasPrefix("http://") || uri.hasPrefix("https://")
    }
    
    var body: some View {
        Group {
            if isNetworkImage {
                // 网络图片
                AsyncImage(url: URL(string: uri)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        // 加载失败时显示默认图片
                        Image(systemName: "person.circle.fill")
                            .resizable()
                    case .empty:
                        // 加载中显示进度指示器
                        ProgressView()
                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                    }
                }
            } else {
                // 本地图片
                Image(uri)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// 预览
struct Avatar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 本地图片预览
            Avatar(uri: "default_avatar", size: 60)
            
            // 网络图片预览
            Avatar(uri: "https://example.com/avatar.jpg", size: 80)
            
            // 默认大小预览
            Avatar(uri: "default_avatar")
        }
    }
}
