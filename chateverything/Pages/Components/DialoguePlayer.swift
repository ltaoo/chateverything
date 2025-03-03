import Foundation
import SwiftUI

class DialoguePlayerViewModel: ObservableObject {
    let scenario: LearningScenario
    let dialogues: [DialogueMessage]
    let config: Config
    let role1: RoleBiz?
    let role2: RoleBiz?

    @Published var isPlaying: Bool = false
    @Published var currentIndex: Int = 0
    @Published var canPlay: Bool = false

    init(scenario: LearningScenario, dialogues: [DialogueMessage], config: Config) {
        self.scenario = scenario
        self.dialogues = dialogues
        self.role1 = scenario.talker
        self.role2 = config.me
        self.config = config

        // Create a weak reference to avoid capturing self
        let events = TTSCallback(
            onStart: {
                print("[BIZ]DialoguePlayer startPlayback onStart")
            },
            onComplete: { [weak self] in
                print("[BIZ]DialoguePlayer startPlayback onComplete")
                if self?.isPlaying == true {
                    sleep(1)
                    self?.startPlayback()
                }
            },
            onCancel: {
                print("[BIZ]DialoguePlayer startPlayback onCancel")
                self.isPlaying = false
            }
        )
        if self.role1 != nil {
            self.role1!.updateTTS(config: config)
            if self.role1!.tts != nil {
                self.role1!.tts?.setEvents(callback: events)
            }
        }
        if self.role2 != nil {
            self.role2!.updateTTS(config: config)
            if self.role2!.tts != nil {
                self.role2!.tts?.setEvents(callback: events)
            }
        }
        if self.role1 != nil && self.role2 != nil {
            if self.role1!.tts != nil && self.role2!.tts != nil {
                self.canPlay = true
            }
        }
    }

    func handlePlayback() {
        if self.isPlaying {
            self.isPlaying = false
            self.stopPlayback()
        } else {
            self.startPlayback()
        }
    }

    private func startPlayback() {
        isPlaying = true
        // 如果已经播放到最后，重新开始
        if currentIndex > dialogues.count - 1 {
            isPlaying = false
            currentIndex = 0
            return
        }
        let msg = dialogues[currentIndex]
        currentIndex += 1
        guard let role1 = role1, let role2 = role2 else {
            return
        }
        if msg.isMe {
            if role2.tts != nil {
                print("[BIZ]DialoguePlayer startPlayback role2.tts?.speak \(msg.content)")
                role2.tts?.speak(msg.content)
            }
        } else {
            if role1.tts != nil {
                print("[BIZ]DialoguePlayer startPlayback role1.tts?.speak \(msg.content)")
                role1.tts?.speak(msg.content)
            }
        }
    }

    private func stopPlayback() {
        isPlaying = false
        currentIndex = 0
        if role1 != nil {
            role1!.tts?.stop()
        }
        if role2 != nil {
            role2!.tts?.stop()
        }
    }
}

struct DialoguePlayer: View {
    let config: Config
    @StateObject var model: DialoguePlayerViewModel

    private let messageDisplayDuration: TimeInterval = 2.0  // 每条消息显示时间

    init(scenario: LearningScenario, dialogues: [DialogueMessage], config: Config) {
        let model = DialoguePlayerViewModel(
            scenario: scenario, dialogues: dialogues, config: config)
        self._model = StateObject(wrappedValue: model)
        self.config = config
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // 控制按钮
            if model.canPlay {
                HStack {
                    Spacer()
                    Button(action: model.handlePlayback) {
                        ZStack {
                            // 渐变背景圆圈
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            DesignSystem.Colors.primary,
                                            DesignSystem.Colors.primary.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(
                                    color: DesignSystem.Colors.primary.opacity(0.3),
                                    radius: 10,
                                    x: 0,
                                    y: 5
                                )
                            
                            // 播放/暂停图标
                            Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 35, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: model.isPlaying ? 0 : 2) // 播放图标稍微偏右以视觉居中
                        }
                        .scaleEffect(model.isPlaying ? 0.95 : 1) // 按下时的缩放动画
                        .animation(.spring(response: 0.3), value: model.isPlaying)
                    }
                    Spacer()
                }
                .padding(.top, DesignSystem.Spacing.medium)
            }
            Spacer()

            // 对话内容展示
            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(Array(model.dialogues.enumerated()), id: \.element.id) { index, message in
                    SceneTextMsgView(text: message.content, isMe: message.isMe)
                }
            }

        }
    }

}

// 定义对话消息的数据结构
struct DialogueMessage: Identifiable, Hashable {
    let id = UUID()
    let content: String
    let isMe: Bool

    static func == (lhs: DialogueMessage, rhs: DialogueMessage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

private struct SceneTextMsgView: View {
    let text: String
    let isMe: Bool

    var body: some View {
        VStack(alignment: isMe ? .trailing : .leading, spacing: DesignSystem.Spacing.xxSmall) {
            HStack {
                if isMe { Spacer() }
                HStack(spacing: 0) {
                    if !isMe {
                        // 左侧小矩形
                        Rectangle()
                            .fill(DesignSystem.Colors.secondaryBackground)
                            .frame(width: 16, height: 16)
                            .cornerRadius(DesignSystem.Radius.small)
                            .rotationEffect(.degrees(45))
                            .offset(x: 12)
                    }
                    VStack(
                        alignment: isMe ? .trailing : .leading,
                        spacing: DesignSystem.Spacing.xxSmall
                    ) {
                        Text(text)
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(
                                isMe ? .white : DesignSystem.Colors.textPrimary)
                    }
                    .padding(DesignSystem.Spacing.medium)
                    .background(
                        isMe
                            ? DesignSystem.Colors.primary
                            : DesignSystem.Colors.secondaryBackground
                    )
                    .cornerRadius(DesignSystem.Radius.large)

                    if isMe {
                        // 右侧小矩形
                        Rectangle()
                            .fill(DesignSystem.Colors.primary)
                            .frame(width: 16, height: 16)
                            .cornerRadius(DesignSystem.Radius.small)
                            .rotationEffect(.degrees(45))
                            .offset(x: -12)
                    }
                }
                if !isMe { Spacer() }
            }
        }
    }
}
