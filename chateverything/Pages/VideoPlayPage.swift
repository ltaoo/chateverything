import SwiftUI
import AVKit

struct VideoPlayPage: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var player: AVPlayer?
    @State private var isFullScreen = false
    @State private var showControls = true
    @State private var selectedEpisode = 1
    @State private var selectedQuality = "1080p"
    
    // 视频质量选项
    let qualities = ["1080p", "720p", "480p"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 视频播放器
                if let player = player {
                    VideoPlayer(player: player)
                        .edgesIgnoringSafeArea(.all)
                }
                
                // 控制层
                if showControls {
                    VStack {
                        // 顶部工具栏
                        HStack {
                            Button(action: {
                                if isFullScreen {
                                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                                    isFullScreen = false
                                } else {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            Spacer()
                        }
                        
                        Spacer()
                        
                        // 底部控制栏
                        HStack {
                            // 剧集选择
                            Menu {
                                ForEach(1...10, id: \.self) { episode in
                                    Button(action: {
                                        selectedEpisode = episode
                                        // 这里添加切换剧集的逻辑
                                    }) {
                                        Text("第\(episode)集")
                                    }
                                }
                            } label: {
                                Text("第\(selectedEpisode)集")
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                            }
                            
                            Spacer()
                            
                            // 清晰度选择
                            Menu {
                                ForEach(qualities, id: \.self) { quality in
                                    Button(action: {
                                        selectedQuality = quality
                                        // 这里添加切换清晰度的逻辑
                                    }) {
                                        Text(quality)
                                    }
                                }
                            } label: {
                                Text(selectedQuality)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                            }
                            
                            // 全屏按钮
                            Button(action: {
                                isFullScreen.toggle()
                                if isFullScreen {
                                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                                } else {
                                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                                }
                            }) {
                                Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                        .padding(.bottom)
                        .background(LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.5)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                    }
                }
            }
            .onTapGesture {
                withAnimation {
                    showControls.toggle()
                }
            }
        }
        .onAppear {
            // 设置示例视频URL
            if let url = URL(string: "https://example.com/video.mp4") {
                player = AVPlayer(url: url)
                player?.play()
            }
        }
        .onDisappear {
            player?.pause()
        }
    }
}

// 支持横屏的修饰器
struct SupportedOrientationsModifier: ViewModifier {
    let supportedOrientations: UIInterfaceOrientationMask
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                UIApplication.shared.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
    }
}

extension View {
    func supportedOrientations(_ supportedOrientations: UIInterfaceOrientationMask) -> some View {
        modifier(SupportedOrientationsModifier(supportedOrientations: supportedOrientations))
    }
}

#Preview {
    VideoPlayPage()
}
