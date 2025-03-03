import Foundation

let MockMessages = [
        ChatBoxBiz(
            id: UUID(),
            type: "message",
            created_at: Date(),
            isMe: true,
            payload_id: UUID(),
            session_id: UUID(),
            sender_id: UUID(),
            payload: ChatPayload.message(ChatTextMsgBiz(text: "你好，我是小明，很高兴认识你。", nodes: [])),
            loading: false
        )
        // LocalChatBox(
        //     id: UUID(),
        //     timestamp: Date(),
        //     isMe: false,
        //     isLoading: false,
        //     type: "message",
        //     box: ChatBoxBiz(
        //         id: UUID(),
        //         type: "message",
        //         created_at: Date(),
        //         isMe: false,
        //         payload_id: UUID(),
        //         session_id: UUID(),
        //         payload: ChatPayload.message(ChatTextMsgBiz(text: "你好，我是小明，很高兴认识你。", nodes: []))
        //     )
        // ),
        // LocalChatBox(
        //     id: UUID(),
        //     timestamp: Date(),
        //     isMe: true,
        //     isLoading: false,
        //     type: "message",
        //     box: ChatBoxBiz(
        //         id: UUID(),
        //         type: "message",
        //         created_at: Date(),
        //         isMe: true,
        //         payload_id: UUID(),
        //         session_id: UUID(),
        //         payload: ChatPayload.message(ChatTextMsgBiz(text: "你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。", nodes: []))
        //     )
        // ),
        // LocalChatBox(
        //     id: UUID(),
        //     timestamp: Date(),
        //     isMe: true,
        //     isLoading: false,
        //     type: "message",
        //     box: ChatBoxBiz(
        //         id: UUID(),
        //         type: "message",
        //         created_at: Date(),
        //         isMe: true,
        //         payload_id: UUID(),
        //         session_id: UUID(),
        //         payload: ChatPayload.message(ChatTextMsgBiz(text: "你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。", nodes: []))
        //     )
        // ),
        // LocalChatBox(
        //     id: UUID(),
        //     timestamp: Date(),
        //     isMe: true,
        //     isLoading: false,
        //     type: "message",
        //     box: ChatBoxBiz(
        //         id: UUID(),
        //         type: "message",
        //         created_at: Date(),
        //         isMe: true,
        //         payload_id: UUID(),
        //         session_id: UUID(),
        //         payload: ChatPayload.message(ChatTextMsgBiz(text: "你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。你好，我是小明，很高兴认识你。", nodes: []))
        //     )
        // ),
]
