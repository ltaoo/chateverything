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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                AsyncImage(url: URL(string: role.avatar)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                }
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.name)
                        .font(.headline)
                    
                    Text(role.language)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            Text(role.desc)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .onTapGesture(perform: onTap)
    }
}
