import SwiftUI

struct RoleListPage: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @Binding var path: NavigationPath
    var config: Config

    @State private var roles: [RoleBiz] = DefaultRoles
    @State private var gradientStart = UnitPoint(x: 0, y: 0)
    @State private var gradientEnd = UnitPoint(x: 1, y: 1)
    @State private var selectedChat: ChatSessionBiz?

    init(path: Binding<NavigationPath>, config: Config) {
        self.config = config
        _path = path
    }

    var body: some View {
        VStack(spacing: 0) {
            RoleListHeader(
                onScanQRCode: {
                    // TODO: 处理扫码动作
                },
                onAddRole: {
                    // TODO: 处理新增动作
                }
            )
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(roles) { role in
                        RoleCardInListPage(role: role) {
                            let session = ChatSessionBiz.create(role: role, in: config.store)
                            ChatSessionMemberBiz.create(role: role, session: session, in: config.store)
                            ChatSessionMemberBiz.create(role: config.me, session: session, in: config.store)
                            path.append(Route.ChatDetailView(sessionId: session.id))
                        }
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.accentColor.opacity(0.1),
                        Color.accentColor.opacity(0.2),
                        colorScheme == .dark 
                            ? Color.black.opacity(0.6) 
                            : Color.accentColor.opacity(0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }
}

struct RoleListHeader: View {
    var onScanQRCode: () -> Void
    var onAddRole: () -> Void
    
    var body: some View {
        HStack {
            Text("角色列表")
                .font(.title2)
                .bold()
            
            Spacer()
            
            Button(action: onScanQRCode) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 20))
            }
            .padding(.horizontal, 8)
            
            Button(action: onAddRole) {
                Image(systemName: "plus")
                    .font(.system(size: 20))
            }
        }
        .padding()
    }
} 

struct RoleCardInListPage: View {
    let role: RoleBiz
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: role.avatar)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 56)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                        .frame(width: 56, height: 56)
                }
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(role.name)
                        .font(.title3)
                        .bold()
                    
                    Text(role.language)
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                }
            }
            
            Text(role.desc)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .padding(.leading, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                isPressed = true
                isLoading = true
            }
            
            // 添加触觉反馈
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            
            // 延迟重置按压状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
            
            onTap()
            
            // 模拟加载完成后重置状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
}
