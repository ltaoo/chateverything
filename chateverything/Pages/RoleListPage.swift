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
                LazyVStack(spacing: DesignSystem.Spacing.medium) {
                    ForEach(roles) { role in
                        RoleCardInListPage(role: role, onTap: {
                            let session = ChatSessionBiz.create(role: role, in: config.store)
                            ChatSessionMemberBiz.create(role: role, session: session, in: config.store)
                            ChatSessionMemberBiz.create(role: config.me, session: session, in: config.store)
                            path.append(Route.ChatDetailView(sessionId: session.id))
                        }, onSecondaryTap: {
                            path.append(Route.RoleDetailView(roleId: role.id))
                        })
                    }
                }
                .padding(DesignSystem.Spacing.medium)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignSystem.Colors.accent.opacity(0.1),
                        DesignSystem.Colors.accent.opacity(0.2),
                        colorScheme == .dark 
                            ? Color.black.opacity(0.6) 
                            : DesignSystem.Colors.accent.opacity(0.4)
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
                .font(DesignSystem.Typography.headingMedium)
            
            Spacer()
            
            Button(action: onScanQRCode) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: DesignSystem.Spacing.large))
            }
            .padding(.horizontal, DesignSystem.Spacing.xSmall)
            
            Button(action: onAddRole) {
                Image(systemName: "plus")
                    .font(.system(size: DesignSystem.Spacing.large))
            }
        }
        .padding(DesignSystem.Spacing.medium)
    }
} 

struct RoleCardInListPage: View {
    let role: RoleBiz
    let onTap: () -> Void
    let onSecondaryTap: () -> Void
    
    @State private var isPressed = false
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                Avatar(
                    uri: role.avatar,
                    size: DesignSystem.AvatarSize.large
                )
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                    Text(role.name)
                        .font(DesignSystem.Typography.headingSmall)
                    
                    Text(role.language)
                        .font(DesignSystem.Typography.bodySmall)
                        .padding(.horizontal, DesignSystem.Spacing.small)
                        .padding(.vertical, DesignSystem.Spacing.xxSmall)
                        .background(DesignSystem.Colors.secondary.opacity(0.2))
                        .cornerRadius(DesignSystem.Radius.small)
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                }
            }
            
            Text(role.desc)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineLimit(3)
                .padding(.leading, DesignSystem.Spacing.xxxSmall)
            
            Divider()
                .padding(.top, DesignSystem.Spacing.small)
            
            HStack(spacing: DesignSystem.Spacing.medium) {
                Button(action: onTap) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Image(systemName: "message.fill")
                        Text("开始聊天")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.small)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
                
                Button(action: onSecondaryTap) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Image(systemName: "info.circle")
                        Text("详情")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.small)
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
            }
            .padding(.top, DesignSystem.Spacing.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.large)
        .padding(.horizontal, DesignSystem.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                .fill(DesignSystem.Colors.background)
                .shadow(
                    color: DesignSystem.Shadows.medium.color,
                    radius: DesignSystem.Shadows.medium.radius,
                    x: DesignSystem.Shadows.medium.x,
                    y: DesignSystem.Shadows.medium.y
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
    }
}
