import Foundation
import CoreData

class ChatBoxBiz: ObservableObject, Identifiable, Equatable {
    var id: UUID
    var type: String
    var created_at: Date
    var isMe: Bool
    var payload_id: UUID
    var session_id: UUID
    var sender_id: UUID
    @Published var loading: Bool = true
    @Published var blurred: Bool = false
    @Published var speaking: Bool = false
    @Published var playing: Bool = false
    @Published var payload: ChatPayload?

    enum CodingKeys: String, CodingKey {
        case id, payload_id, session_id, receiver_id, sender_id, type, created_at
    }
    
    init(
        id: UUID,
        type: String,
        created_at: Date,
        isMe: Bool,
        payload_id: UUID,
        session_id: UUID,
        sender_id: UUID,
        payload: ChatPayload?,
        loading: Bool = false,
        blurred: Bool = false
    ) {
        self.id = id
        self.type = type
        self.created_at = created_at
        self.isMe = isMe
        self.payload_id = payload_id
        self.session_id = session_id
        self.sender_id = sender_id
        self.payload = payload
        self.loading = loading
        self.blurred = blurred
    }

    static func ==(lhs: ChatBoxBiz, rhs: ChatBoxBiz) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func from(_ entity: ChatBox, store: ChatStore) -> ChatBoxBiz {
        // guard let id = entity.id,
        //       let type = entity.type,
        //       let payload_id = entity.payload_id,
        //       let created_at = entity.created_at,
        //       let session_id = entity.session_id else {
        //     return nil
        // }
        let id = entity.id ?? UUID()
        let type = entity.type ?? ""
        let created_at = entity.created_at ?? Date()
        let session_id = entity.session_id ?? UUID()
        let payload_id = entity.payload_id ?? UUID()
        let sender_id = entity.sender_id ?? UUID()
        
        return ChatBoxBiz(
            id: id,
            type: type,
            created_at: created_at,
            isMe: false,
            payload_id: payload_id,
            session_id: session_id,
            sender_id: sender_id,
            payload: nil
        )
    }

    func setPayload(payload: ChatPayload) {
        self.loading = false
        self.payload = payload
    }

    func blur() {
        self.blurred = true
    }

    func unblur() {
        self.blurred = false
    }

    func load(store: ChatStore) {
        if self.type == "message" {
            let req = NSFetchRequest<ChatMsgContent>(entityName: "ChatMsgContent")
            req.predicate = NSPredicate(format: "id == %@", self.payload_id as! any CVarArg as CVarArg)
            if let message = try! store.container.viewContext.fetch(req).first {
                self.payload = .message(ChatMessageBiz2(text: "发出的消息", nodes: []))
            }
        }
        // if self.type == "audio" {
        //     let req = NSFetchRequest<ChatAudio>(entityName: "ChatAudio")
        //     req.predicate = NSPredicate(format: "id == %@", self.payload_id as! any CVarArg as CVarArg)
        //     if let audio = try! store.container.viewContext.fetch(req).first {
        //         self.payload = .audio(ChatAudioBiz(text: audio.content, url: audio.url, duration: audio.duration))
        //     }
        // }
        if self.type == "question" {
            let req = NSFetchRequest<ChatMsgPuzzle>(entityName: "ChatMsgPuzzle")
            req.predicate = NSPredicate(format: "id == %@", self.payload_id as! any CVarArg as CVarArg)
            if let question = try! store.container.viewContext.fetch(req).first {
                let options = [
                    ChatPuzzleOption(id: "1", text: "选项1"),
                    ChatPuzzleOption(id: "2", text: "选项2"),
                    ChatPuzzleOption(id: "3", text: "选项3"),
                ]
                self.payload = .puzzle(ChatPuzzleBiz(question: "请选出正确的选项", options: options, correctOption: options[0], selectedOption: nil, isCorrect: false))
            }
        }
    }
    func save(sessionId: UUID, store: ChatStore) {
        let context = store.container.viewContext
        
        // Check if record already exists
        let fetchRequest = NSFetchRequest<ChatBox>(entityName: "ChatBox")
        fetchRequest.predicate = NSPredicate(format: "id == %@", self.id as CVarArg)
        
        do {
            let existingRecords = try context.fetch(fetchRequest)
            if !existingRecords.isEmpty {
                // Record already exists, skip saving
                return
            }
            
            // Create new record
            let entity = ChatBox(context: context)
            entity.id = self.id
            entity.type = self.type
            entity.payload_id = self.payload_id
            entity.created_at = self.created_at
            entity.session_id = self.session_id
            
            // Save payload based on type
            if let payload = self.payload {
                switch payload {
                case .message(let messageBiz):
                    let messageCheck = NSFetchRequest<ChatMsgContent>(entityName: "ChatMsgContent")
                    messageCheck.predicate = NSPredicate(format: "id == %@", self.payload_id as CVarArg)
                    if try context.fetch(messageCheck).isEmpty {
                        let message = ChatMsgContent(context: context)
                        message.id = self.payload_id
                        message.text = messageBiz.text
                    }
                    
                case .audio(let audioBiz):
                    let audioCheck = NSFetchRequest<ChatMsgAudio>(entityName: "ChatMsgAudio")
                    audioCheck.predicate = NSPredicate(format: "id == %@", self.payload_id as CVarArg)
                    if try context.fetch(audioCheck).isEmpty {
                        let audio = ChatMsgAudio(context: context)
                        audio.id = self.payload_id
                        audio.text = audioBiz.text
                        audio.uri = audioBiz.url
                        audio.duration = audioBiz.duration
                    }
                    
                // case .puzzle(let puzzleBiz):
                //     let puzzleCheck = NSFetchRequest<ChatQuestion>(entityName: "ChatQuestion")
                //     puzzleCheck.predicate = NSPredicate(format: "id == %@", self.payload_id as CVarArg)
                //     if try context.fetch(puzzleCheck).isEmpty {
                //         let puzzle = ChatQuestion(context: context)
                //         puzzle.id = self.payload_id
                //         puzzle.question = puzzleBiz.question
                //         // Save other puzzle properties as needed
                //     }
                    
                // case .image(let imageBiz):
                //     let imageCheck = NSFetchRequest<ChatImage>(entityName: "ChatImage")
                //     imageCheck.predicate = NSPredicate(format: "id == %@", self.payload_id as CVarArg)
                //     if try context.fetch(imageCheck).isEmpty {
                //         let image = ChatImage(context: context)
                //         image.id = self.payload_id
                //         image.url = imageBiz.url
                //         image.width = imageBiz.width
                //         image.height = imageBiz.height
                //     }
                    
                // case .video(let videoBiz):
                //     let videoCheck = NSFetchRequest<ChatVideo>(entityName: "ChatVideo")
                //     videoCheck.predicate = NSPredicate(format: "id == %@", self.payload_id as CVarArg)
                //     if try context.fetch(videoCheck).isEmpty {
                //         let video = ChatVideo(context: context)
                //         video.id = self.payload_id
                //         video.url = videoBiz.url
                //         video.thumbnail = videoBiz.thumbnail
                //         video.duration = videoBiz.duration
                //     }
                    
                // Add other cases as needed
                default:
                    break
                }
            }
            
            try context.save()
        } catch {
            print("Error saving ChatBox: \(error)")
        }
    }
} 


struct ChatMessageStruct: Codable {
    let text: String
    // let nodes: [MsgTextNode]
}

struct ChatAudioStruct: Codable {
    let text: String
    let url: URL
    let duration: TimeInterval
}

struct ChatImageStruct: Codable {
    let url: URL
    let width: CGFloat
    let height: CGFloat
}

struct ChatVideoStruct: Codable {
    let url: URL
    let thumbnail: URL
    let duration: TimeInterval
}

struct ChatPuzzleStruct: Codable {
    let question: String
    let options: [ChatPuzzleOption]
    let correctOption: ChatPuzzleOption?
}

struct ChatStatsStruct: Codable {
    let title: String
    let priceRange: ClosedRange<Double>
}

struct ChatErrorStruct: Codable {
    let error: String
}

struct ChatTipStruct: Codable {
    let title: String
    let content: String
    let type: String
}

// MARK: - 消息载荷类型
enum ChatPayload: Encodable {
    case message(ChatMessageBiz2)
    case image(ChatImageBiz)
    case video(ChatVideoBiz)
    case puzzle(ChatPuzzleBiz)
    case audio(ChatAudioBiz)
    case estimate(ChatStatsBiz)
    case error(ChatErrorBiz)
    case tip(ChatTipBiz)
    case unknown(type: String)
    
    // 自定义解码逻辑（关键部分）
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PayloadCodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "message":
            let message = try ChatMessageStruct(from: decoder)
            self = .message(ChatMessageBiz2.from(data: message))
        case "audio":
            let audio = try ChatAudioStruct(from: decoder)
            self = .audio(ChatAudioBiz.from(data: audio))
        case "image":
            let image = try ChatImageStruct(from: decoder)
            self = .image(ChatImageBiz.from(data: image))
        case "video":
            let video = try ChatVideoStruct(from: decoder)
            self = .video(ChatVideoBiz.from(data: video))
        case "puzzle":
            let puzzle = try ChatPuzzleStruct(from: decoder)
            self = .puzzle(ChatPuzzleBiz.from(data: puzzle))
        case "estimate":
            let estimate = try ChatStatsStruct(from: decoder)
            self = .estimate(ChatStatsBiz.from(data: estimate))
        case "error":
            let error = try ChatErrorStruct(from: decoder)
            self = .error(ChatErrorBiz.from(data: error))
        case "tip":
            let tip = try ChatTipStruct(from: decoder)
            self = .tip(ChatTipBiz.from(data: tip))
        default:
            self = .unknown(type: type)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: PayloadCodingKeys.self)
        
        switch self {
        case .message(let message):
            try container.encode("message", forKey: .type)
            try message.encode(to: encoder)
        case .image(let image):
            try container.encode("image", forKey: .type)
            try image.encode(to: encoder)
        case .video(let video):
            try container.encode("video", forKey: .type)
            try video.encode(to: encoder)
        case .puzzle(let puzzle):
            try container.encode("puzzle", forKey: .type)
            try puzzle.encode(to: encoder)
        case .audio(let audio):
            try container.encode("audio", forKey: .type)
            try audio.encode(to: encoder)
        case .estimate(let estimate):
            try container.encode("estimate", forKey: .type)
            try estimate.encode(to: encoder)
        case .error(let error):
            try container.encode("error", forKey: .type)
            try error.encode(to: encoder)
        case .tip(let tip):
            try container.encode("tip", forKey: .type)
            try tip.encode(to: encoder)
        case .unknown(let type):
            try container.encode(type, forKey: .type)
        }
    }
    
    func encode() -> (text: String, type: String) {
        switch self {
        case .message(let message):
            return (text: message.text, type: "message")
        case .audio(let audio):
            return (text: audio.text, type: "audio")
        case .image(let image):
            return (text: image.url.absoluteString, type: "image")
        case .video(let video):
            return (text: video.url.absoluteString, type: "video")
        case .puzzle(let puzzle):
            return (text: puzzle.question, type: "puzzle")
        case .estimate(let estimate):
            return (text: estimate.title, type: "estimate")
        case .error(let error):
            return (text: error.error, type: "error")
        case .tip(let tip):
            return (text: tip.title, type: "tip")
        case .unknown(let type):
            return (text: "Unknown content", type: type)
        }
    }
    
    private enum PayloadCodingKeys: String, CodingKey {
        case type
        case data
    }
}
struct MsgTextNode: Codable, Identifiable, Equatable {
    let id: Int
    let text: String
    let type: String
    let error: TextError?
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case type
        case error
    }
}
struct TextError: Codable, Equatable {
    let type: String
    let reason: String
    let correction: String
}
func splitTextToNodes(text: String) -> [MsgTextNode] {
    var nodeId = 0
    var result: [MsgTextNode] = []
    
    let words = text.split(omittingEmptySubsequences: false, whereSeparator: { $0.isWhitespace })
    for word in words {
        nodeId += 1
        let node = MsgTextNode(
            id: nodeId,
            text: String(word),
            type: word.allSatisfy { $0.isWhitespace } ? "space" : "text",
            error: nil
        )
        result.append(node)
    }
    
    return result
}
extension String {
    func split(includesSeparators: Bool, 
              whereSeparator isSeparator: (Character) -> Bool) -> [Substring] {
        var result: [Substring] = []
        var start = self.startIndex
        
        for i in self.indices {
            if isSeparator(self[i]) {
                if i > start {
                    result.append(self[start..<i])
                }
                if includesSeparators {
                    result.append(self[i...i])
                }
                start = self.index(after: i)
            }
        }
        
        if start < self.endIndex {
            result.append(self[start..<self.endIndex])
        }
        
        return result
    }
}


class ChatAudioBiz: ObservableObject, Encodable {
    static func from(data: ChatAudioStruct) -> ChatAudioBiz {
        return ChatAudioBiz(text: data.text, nodes: [], url: data.url, duration: data.duration)
    }

    let contentType = "audio"
    @Published var text: String
    @Published var nodes: [MsgTextNode]
    @Published var url: URL
    @Published var duration: TimeInterval
    @Published var ok = false

    init(text: String, nodes: [MsgTextNode], url: URL, duration: TimeInterval) {
        self.text = text
        self.nodes = nodes
        self.url = url
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey {
        case contentType
        case text
        case url
        case duration
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(text, forKey: .text)
        try container.encode(url, forKey: .url)
        try container.encode(duration, forKey: .duration)
    }
}

// MARK: - 具体消息类型实现
class ChatMessageBiz2: ObservableObject, Encodable {
    static func from(data: ChatMessageStruct) -> ChatMessageBiz2 {
        return ChatMessageBiz2(text: data.text, nodes: [])
    }
    
    let contentType = "message"
    @Published var text: String
    @Published var nodes: [MsgTextNode]
    @Published var ok = false

    init(text: String, nodes: [MsgTextNode]) {
        self.text = text
        self.nodes = nodes

        // self.split(text: text)
    }

    func split(text: String) {
        self.nodes = splitTextToNodes(text: text)
        self.ok = true
    }
    func updateText(text: String) {
        self.text = text
        self.split(text: text)
    }

    enum CodingKeys: String, CodingKey {
        case contentType
        case text
        case nodes
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(text, forKey: .text)
        try container.encode(nodes, forKey: .nodes)
    }
}

class ChatImageBiz: Encodable {
    static func from(data: ChatImageStruct) -> ChatImageBiz {
        return ChatImageBiz(url: data.url, width: data.width, height: data.height)
    }
    
    let contentType = "image"
    let url: URL
    let width: CGFloat
    let height: CGFloat

    init(url: URL, width: CGFloat, height: CGFloat) {
        self.url = url
        self.width = width
        self.height = height
    }

    enum CodingKeys: String, CodingKey {
        case contentType
        case url
        case width
        case height
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(url, forKey: .url)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
}

class ChatVideoBiz: Encodable {
    static func from(data: ChatVideoStruct) -> ChatVideoBiz {
        return ChatVideoBiz(url: data.url, thumbnail: data.thumbnail, duration: data.duration)
    }
    
    let contentType = "video"
    let url: URL
    let thumbnail: URL
    let duration: TimeInterval

    init(url: URL, thumbnail: URL, duration: TimeInterval) {
        self.url = url
        self.thumbnail = thumbnail
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey {
        case contentType
        case url
        case thumbnail
        case duration
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(url, forKey: .url)
        try container.encode(thumbnail, forKey: .thumbnail)
        try container.encode(duration, forKey: .duration)
    }
}

class ChatPuzzleBiz: ObservableObject, Encodable {
    static func from(data: ChatPuzzleStruct) -> ChatPuzzleBiz {
        return ChatPuzzleBiz(question: data.question, options: data.options, correctOption: data.correctOption, selectedOption: nil, isCorrect: false)
    }

    let contentType = "puzzle"
    let question: String
    let options: [ChatPuzzleOption]
    let correctOption: ChatPuzzleOption?
    var selectedOption: ChatPuzzleOption?
    var isCorrect: Bool

    var attempts: Int = 0

    init(question: String, options: [ChatPuzzleOption], correctOption: ChatPuzzleOption?, selectedOption: ChatPuzzleOption?, isCorrect: Bool) {
        self.question = question
        self.options = options
        self.correctOption = correctOption
        self.selectedOption = selectedOption
        self.isCorrect = isCorrect
    }

    func selectOption(option: ChatPuzzleOption) {
        self.selectedOption = option
        self.attempts += 1
        self.isCorrect = self.correctOption?.id == option.id
    }
    func isSelected(option: ChatPuzzleOption) -> Bool {
        return self.selectedOption?.id == option.id
    }
    func isCorrect(option: ChatPuzzleOption) -> Bool {
        return self.correctOption?.id == option.id
    }

    enum CodingKeys: String, CodingKey {
        case contentType
        case question
        case options
        case correctOption
        case selectedOption
        case isCorrect
        case attempts
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(question, forKey: .question)
        try container.encode(options, forKey: .options)
        try container.encode(correctOption, forKey: .correctOption)
        try container.encode(selectedOption, forKey: .selectedOption)
        try container.encode(isCorrect, forKey: .isCorrect)
        try container.encode(attempts, forKey: .attempts)
    }
}

class ChatPuzzleOption: Codable, Equatable, Identifiable {
    let id: String
    let text: String
    
    init(id: String, text: String) {
        self.id = id
        self.text = text
    }

    static func == (lhs: ChatPuzzleOption, rhs: ChatPuzzleOption) -> Bool {
        return lhs.id == rhs.id
    }
}

class ChatStatsBiz: Encodable {
    static func from(data: ChatStatsStruct) -> ChatStatsBiz {
        return ChatStatsBiz(title: data.title, priceRange: data.priceRange)
    }

    let contentType = "stats"
    let title: String
    let priceRange: ClosedRange<Double>

    init(title: String, priceRange: ClosedRange<Double>) {
        self.title = title
        self.priceRange = priceRange
    }

    enum CodingKeys: String, CodingKey {
        case contentType
        case title
        case priceRange
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(title, forKey: .title)
        try container.encode(priceRange, forKey: .priceRange)
    }
}

class ChatErrorBiz: Encodable {
    static func from(data: ChatErrorStruct) -> ChatErrorBiz {
        return ChatErrorBiz(error: data.error)
    }

    let contentType = "error"
    let error: String
    
    init(error: String) {
        self.error = error
    }

    enum CodingKeys: String, CodingKey {
        case contentType
        case error
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(error, forKey: .error)
    }
}

class ChatTipBiz: Encodable {
    static func from(data: ChatTipStruct) -> ChatTipBiz {
        return ChatTipBiz(title: data.title, content: data.content, type: data.type)
    }

    let contentType = "tip"
    let title: String
    let content: String
    let type: String
    
    init(title: String, content: String, type: String) {
        self.title = title
        self.content = content
        self.type = type
    }

    enum CodingKeys: String, CodingKey {
        case contentType
        case title
        case content
        case type
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(type, forKey: .type)
    }
}
