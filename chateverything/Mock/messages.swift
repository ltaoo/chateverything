import Foundation

let MockMessages = [
        LocalChatBox(
            id: UUID(),
            timestamp: Date(),
            isMe: true,
            isLoading: false,
            type: "message",
            audioURL: nil,
            box: ChatBoxBiz(
                id: UUID(),
                type: "message",
                payload_id: UUID(),
                created_at: Date(),
                session_id: UUID(),
                payload: ChatPayload.message(ChatMessageBiz2(text: "你好，我是小明，很高兴认识你。", nodes: []))
            )
        ),
        LocalChatBox(
            id: UUID(),
            timestamp: Date(),
            isMe: false,
            isLoading: false,
            type: "message",
            audioURL: nil,
            box: ChatBoxBiz(
                id: UUID(),
                type: "message",
                payload_id: UUID(),
                created_at: Date(),
                session_id: UUID(),
                payload: ChatPayload.message(ChatMessageBiz2(text: "你好，我是小明，很高兴认识你。", nodes: []))
            )
        ),
        LocalChatBox(
            id: UUID(),
            timestamp: Date(),
            isMe: true,
            isLoading: false,
            type: "message",
            audioURL: nil,
            box: ChatBoxBiz(
                id: UUID(),
                type: "message",
                payload_id: UUID(),
                created_at: Date(),
                session_id: UUID(),
                payload: ChatPayload.message(ChatMessageBiz2(text: "你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。", nodes: []))
            )
        ),
        LocalChatBox(
            id: UUID(),
            timestamp: Date(),
            isMe: true,
            isLoading: false,
            type: "message",
            audioURL: nil,
            box: ChatBoxBiz(
                id: UUID(),
                type: "message",
                payload_id: UUID(),
                created_at: Date(),
                session_id: UUID(),
                payload: ChatPayload.message(ChatMessageBiz2(text: "你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。", nodes: []))
            )
        ),
        LocalChatBox(
            id: UUID(),
            timestamp: Date(),
            isMe: true,
            isLoading: false,
            type: "message",
            audioURL: nil,
            box: ChatBoxBiz(
                id: UUID(),
                type: "message",
                payload_id: UUID(),
                created_at: Date(),
                session_id: UUID(),
                payload: ChatPayload.message(ChatMessageBiz2(text: "你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。", nodes: []))
            )
        ),
    ]