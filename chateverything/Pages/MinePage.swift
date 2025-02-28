import AVFoundation
// Add these imports if they don't exist in other files
import Foundation
import SwiftUI
import UIKit  // Add this import for UIImage related types

struct MineView: View {
    let config: Config
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("isAutoMode") private var isAutoMode = false
    @State private var showToast = false
    @State private var toastMessage = ""

    func toggleAppearanceMode() {
        if isAutoMode {
            isAutoMode = false
            isDarkMode = true
            toastMessage = "已切换到深色模式"
        } else if isDarkMode {
            isDarkMode = false
            toastMessage = "已切换到浅色模式"
        } else {
            isAutoMode = true
            toastMessage = "已切换到自动模式"
        }
        showToast = true
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Spacer()
                // Button(action: toggleAppearanceMode) {
                //     Image(systemName: isAutoMode ? "circle.lefthalf.filled" :
                //                     isDarkMode ? "moon.fill" : "sun.max.fill")
                //         .font(.system(size: 20))
                //         .foregroundStyle(.white)
                // }
                // .padding(.trailing)
            }
            .padding(.top, DesignSystem.Spacing.medium)
            .padding(.bottom, DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.background)

            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.medium) {
                    // 个人信息卡片
                    ProfileCard(me: config.me, config: config)
                        .padding(.top, 20)

                    // 设置列表
                    SettingsList()
                }
                .padding(.bottom, DesignSystem.Spacing.medium)
            }
        }
        .background(DesignSystem.Colors.background)
        .overlay(
            ToastView(message: toastMessage, isShowing: $showToast)
        )
        .preferredColorScheme(isAutoMode ? nil : (isDarkMode ? .dark : .light))
    }
}

// 个人信息卡片视图
struct ProfileCard: View {
    @ObservedObject var me: RoleBiz

    let config: Config

    // @StateObject private var userProfile = UserProfile()
    @State private var showingImagePicker = false
    @State private var showingNicknameAlert = false
    @State private var newNickname = ""
    @State private var showingImageMenu = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    // 添加统计数据
    // let stats = [
    //     ("聊天记录", "3434"),
    //     ("生词本", "22"),
    //     ("待面试", "0"),
    //     ("收藏", "19")
    // ]

    let level: Int = 5
    let currentExp: Int = 720
    let maxExp: Int = 1000
    let isPremium: Bool = true

    var expPercentage: CGFloat {
        CGFloat(currentExp) / CGFloat(maxExp)
    }

    // 检查相机权限
    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            completion(false)
        }
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // 基本信息部分
            HStack(spacing: DesignSystem.Spacing.medium) {
                Avatar(
                    uri: me.avatar,
                    size: DesignSystem.AvatarSize.xLarge
                )

                VStack(alignment: .leading, spacing: 4) {
                    // 昵称
                    Button {
                        showingNicknameAlert = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(me.name)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.primary)

                            // 添加编辑图标
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal)

            // 统计数据
            HStack {
                // ForEach(stats, id: \.0) { stat in
                //     VStack(spacing: 8) {
                //         Text(stat.1)
                //             .font(.system(size: 20, weight: .medium))
                //             .foregroundColor(.primary)
                //         Text(stat.0)
                //             .font(.system(size: 14))
                //             .foregroundColor(.secondary)
                //     }
                //     .frame(maxWidth: .infinity)
                // }
            }
        }
        .padding(.vertical, 20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        // .confirmationDialog("修改头像", isPresented: $showingImageMenu) {
        //     Button("从相册选择") {
        //         sourceType = .photoLibrary
        //         showingImagePicker = true
        //     }
        //     Button("拍照") {
        //         checkCameraPermission { granted in
        //             if granted {
        //                 sourceType = .camera
        //                 showingImagePicker = true
        //             } else {
        //                 // 提示用户开启相机权限
        //                 if let url = URL(string: UIApplication.openSettingsURLString) {
        //                     UIApplication.shared.open(url)
        //                 }
        //             }
        //         }
        //     }
        //     Button("取消", role: .cancel) {}
        // }
        // .sheet(isPresented: $showingImagePicker) {
        //     ImagePicker(
        //         image: Binding(
        //             get: { nil },
        //             set: {
        //                 if let data = $0?.jpegData(compressionQuality: 0.2) {
        //                     self.config.updateMeAvatar(avatar: data)
        //                 }
        //             }),
        //         sourceType: sourceType)
        // }
        .sheet(isPresented: $showingNicknameAlert) {
            NavigationView {
                Form {
                    TextField("请输入新昵称", text: $newNickname)
                        .textInputAutocapitalization(.never)
                }
                .navigationTitle("修改昵称")
                .navigationBarItems(
                    leading: Button("取消", role: .cancel) {
                        showingNicknameAlert = false
                    },
                    trailing: Button("确定") {
                        if !newNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            self.config.updateMeName(name: newNickname)
                            showingNicknameAlert = false
                            newNickname = ""
                        }
                    }
                )
            }
            .presentationDetents([.height(200)])
        }
    }
}

// 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    let sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// 设置列表视图
struct SettingsList: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.colorScheme) var colorScheme

    // 获取版本号
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "未知"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "版本 \(version) (\(build))"
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                SettingsRow(icon: "gear", title: "通用设置")
                NavigationLink {
                    LLMProviderSettingsPage()
                } label: {
                    SettingsRow(icon: "brain", title: "语言模型")
                }
                NavigationLink {
                    TTSProviderSettingsPage()
                } label: {
                    SettingsRow(icon: "waveform", title: "语音设置")
                }
            }

            // 添加版本号显示
            HStack {
                Spacer()
                Text(appVersion)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Spacer()
            }
            .padding(.top, DesignSystem.Spacing.large)
            .padding(.bottom, DesignSystem.Spacing.medium)
        }
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.Radius.medium)
        .padding(.horizontal, DesignSystem.Spacing.medium)
    }
}

// 设置列表行视图
struct SettingsRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(DesignSystem.Gradients.iconGradient)
                .frame(width: 30)

            Text(title)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.background)
        .overlay(alignment: .bottom) {
            LinearGradient(
                stops: [
                    .init(color: DesignSystem.Colors.divider.opacity(0), location: 0),
                    .init(color: DesignSystem.Colors.divider.opacity(0.6), location: 0.2),
                    .init(color: DesignSystem.Colors.divider.opacity(0.6), location: 0.8),
                    .init(color: DesignSystem.Colors.divider.opacity(0), location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 0.5)
        }
    }
}

// 添加 ToastView
struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool

    var body: some View {
        if isShowing {
            VStack {
                Spacer()
                Text(message)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .padding(.bottom, 100)
            }
            .transition(.opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
    }
}
