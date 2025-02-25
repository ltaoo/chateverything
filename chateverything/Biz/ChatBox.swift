import Foundation
import CoreData

enum BoxPayloadTypes {
    case message(ChatMsgContent)
    case audio(ChatMsgAudio)
    case puzzle(ChatMsgPuzzle)
    case image(ChatMsgImage)
    case video(ChatMsgVideo)
    case error(ChatMsgError)
    case tipText(ChatMsgTipText)
    case time(ChatMsgTime)
}

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

    func blur() {
        self.blurred = true
    }

    func unblur() {
        self.blurred = false
    }

    func load(session: ChatSessionBiz, config: Config) {
        let store = config.store
        let sender = RoleBiz.Get(id: self.sender_id, store: store)
        guard let sender = sender else { return }
        if self.type == "message" {
            let req = NSFetchRequest<ChatMsgContent>(entityName: "ChatMsgContent")
            req.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.payload_id])
            if let message = try! store.container.viewContext.fetch(req).first {
                self.payload = sender.payloadBuilder.build(record: .message(message), role: sender, session: session, config: config)
            }
        }
        if self.type == "audio" {
            let req = NSFetchRequest<ChatMsgAudio>(entityName: "ChatMsgAudio")
            req.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.payload_id])
            if let audio = try! store.container.viewContext.fetch(req).first {
                self.payload = sender.payloadBuilder.build(record: .audio(audio), role: sender, session: session, config: config)
                // self.payload = .audio(ChatAudioBiz(text: audio.text!, nodes: [], url: audio.uri!, duration: audio.duration))
            }
        }
        if self.type == "puzzle" {
            let req = NSFetchRequest<ChatMsgPuzzle>(entityName: "ChatMsgPuzzle")
            req.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.payload_id])
            if let puzzle = try! store.container.viewContext.fetch(req).first {
                self.payload = sender.payloadBuilder.build(record: .puzzle(puzzle), role: sender, session: session, config: config)
                // let opts = puzzle.opts
                // let options = (ChatPuzzleBiz.optionsFromJSON(opts ?? "") ?? [] as! [ChatPuzzleOption]).map { ChatPuzzleOption(id: $0.id, text: $0.text) }
                // let selected = options.first { $0.id == puzzle.answer }
                // self.payload = .puzzle(ChatPuzzleBiz(title: puzzle.title!, options: options, answer: puzzle.answer ?? "", selected: selected, corrected: false))
            }
        }
        if self.type == "image" {
            let req = NSFetchRequest<ChatMsgImage>(entityName: "ChatMsgImage")
            req.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.payload_id])
            if let image = try! store.container.viewContext.fetch(req).first {
                self.payload = sender.payloadBuilder.build(record: .image(image), role: sender, session: session, config: config)
                // self.payload = .image(ChatImageBiz(url: image.url!, width: image.width, height: image.height))
            }
        }
        if self.type == "video" {
            let req = NSFetchRequest<ChatMsgVideo>(entityName: "ChatMsgVideo")
            req.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.payload_id])
            if let video = try! store.container.viewContext.fetch(req).first {
                self.payload = sender.payloadBuilder.build(record: .video(video), role: sender, session: session, config: config)
                // self.payload = .video(ChatVideoBiz(url: video.url!, thumbnail: video.thumbnail!, width: video.width, height: video.height, duration: video.duration))
            }
        }
        if self.type == "error" {
            let req = NSFetchRequest<ChatMsgError>(entityName: "ChatMsgError")
            req.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.payload_id])
            if let error = try! store.container.viewContext.fetch(req).first {
                self.payload = sender.payloadBuilder.build(record: .error(error), role: sender, session: session, config: config)
                // self.payload = .error(ChatErrorBiz(error: error.error!))
            }
        }
        if self.type == "tipText" {
            let req = NSFetchRequest<ChatMsgTipText>(entityName: "ChatMsgTipText")
            req.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.payload_id])
            if let tipText = try! store.container.viewContext.fetch(req).first {
                self.payload = sender.payloadBuilder.build(record: .tipText(tipText), role: sender, session: session, config: config)
                // self.payload = .tipText(ChatTipTextBiz(content: tipText.content!))
            }
        }
        if self.type == "time" {
            let req = NSFetchRequest<ChatMsgTime>(entityName: "ChatMsgTime")
            req.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.payload_id])
            if let time = try! store.container.viewContext.fetch(req).first {
                self.payload = sender.payloadBuilder.build(record: .time(time), role: sender, session: session, config: config)
                // self.payload = .time(ChatTimeBiz(time: time.time!))
            }
        }
    }
    func save(sessionId: UUID, store: ChatStore) {
        let context = store.container.viewContext
        
        // Check if record already exists
        let req = NSFetchRequest<ChatBox>(entityName: "ChatBox")
        req.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.id])
        
        do {
            let entity = ChatBox(context: context)
            entity.id = self.id
            entity.type = self.type
            entity.created_at = self.created_at
            entity.sender_id = self.sender_id
            entity.payload_id = self.payload_id
            entity.session_id = self.session_id
            
            // Save payload based on type
            if let payload = self.payload {
                switch payload {
                case .message(let messageBiz):
                    let messageCheck = NSFetchRequest<ChatMsgContent>(entityName: "ChatMsgContent")
                    messageCheck.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.payload_id])
                    if try context.fetch(messageCheck).isEmpty {
                        let message = ChatMsgContent(context: context)
                        message.id = self.payload_id
                        message.text = messageBiz.text
                    }
                    
                case .audio(let audioBiz):
                    let audioCheck = NSFetchRequest<ChatMsgAudio>(entityName: "ChatMsgAudio")
                    audioCheck.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.payload_id])
                    if try context.fetch(audioCheck).isEmpty {
                        let audio = ChatMsgAudio(context: context)
                        audio.id = self.payload_id
                        audio.text = audioBiz.text
                        audio.uri = audioBiz.url
                        audio.duration = audioBiz.duration
                    }
                    
                case .puzzle(let puzzleBiz):
                    let puzzleCheck = NSFetchRequest<ChatMsgPuzzle>(entityName: "ChatMsgPuzzle")
                    puzzleCheck.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.payload_id])
                    if try context.fetch(puzzleCheck).isEmpty {
                        let puzzle = ChatMsgPuzzle(context: context)
                        puzzle.id = self.payload_id
                        puzzle.title = puzzleBiz.title
                        puzzle.opts = puzzleBiz.optionsToJSON()
                        puzzle.other1 = [
                            "selected": puzzleBiz.selected?.id ?? "",
                            "corrected": puzzleBiz.corrected
                        ].toJSON()
                        puzzle.answer = puzzleBiz.answer
                        print("before save puzzle: \(puzzle.other1)")
                    }
                    
                case .image(let imageBiz):
                    let imageCheck = NSFetchRequest<ChatMsgImage>(entityName: "ChatMsgImage")
                    imageCheck.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.payload_id])
                    if try context.fetch(imageCheck).isEmpty {
                        let image = ChatMsgImage(context: context)
                        image.id = self.payload_id
                        image.url = imageBiz.url
                        image.width = imageBiz.width
                        image.height = imageBiz.height
                    }
                    
                case .video(let videoBiz):
                    let videoCheck = NSFetchRequest<ChatMsgVideo>(entityName: "ChatMsgVideo")
                    videoCheck.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.payload_id])
                    if try context.fetch(videoCheck).isEmpty {
                        let video = ChatMsgVideo(context: context)
                        video.id = self.payload_id
                        video.url = videoBiz.url
                        video.thumbnail = videoBiz.thumbnail
                        video.duration = videoBiz.duration
                        video.width = videoBiz.width
                        video.height = videoBiz.height
                    }

                case .error(let errorBiz):
                    let errorCheck = NSFetchRequest<ChatMsgError>(entityName: "ChatMsgError")
                    errorCheck.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.payload_id])
                    if try context.fetch(errorCheck).isEmpty {
                        let error = ChatMsgError(context: context)
                        error.id = self.payload_id
                        error.error = errorBiz.error
                    }

                case .tipText(let tipTextBiz):
                    let tipTextCheck = NSFetchRequest<ChatMsgTipText>(entityName: "ChatMsgTipText")
                    tipTextCheck.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.payload_id])
                    if try context.fetch(tipTextCheck).isEmpty {
                        let tipText = ChatMsgTipText(context: context)
                        tipText.id = self.payload_id
                        tipText.content = tipTextBiz.content
                    }

                case .time(let timeBiz):
                    let timeCheck = NSFetchRequest<ChatMsgTime>(entityName: "ChatMsgTime")
                    timeCheck.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", self.payload_id])
                    if try context.fetch(timeCheck).isEmpty {
                        let time = ChatMsgTime(context: context)
                        time.id = self.payload_id
                        time.time = timeBiz.time
                    }
                default:
                    break
                }
            }
            
            try context.save()
        } catch {
            print("Error saving ChatBox: \(error)")
        }
    }
    func entity(store: ChatStore) -> ChatBox {
        let context = store.container.viewContext
        let req = NSFetchRequest<ChatBox>(entityName: "ChatBox")
        req.predicate = NSPredicate(format: "id == %@", self.id as CVarArg)
        let entity = try! context.fetch(req).first!
        return entity
    }
    func updatePayload(payload: ChatPayload, store: ChatStore) {
        payload.update(id: self.payload_id, store: store)
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
    let width: CGFloat
    let height: CGFloat
    let duration: TimeInterval
}

struct ChatPuzzleStruct: Codable {
    let title: String
    let options: [ChatPuzzleOption]
    let answer: String
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

struct ChatTimeStruct: Codable {
    let time: Date
}

struct ChatTipTextStruct: Codable {
    let content: String
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
    case time(ChatTimeBiz)
    case tipText(ChatTipTextBiz)
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
        case "time":
            let time = try ChatTimeStruct(from: decoder)
            self = .time(ChatTimeBiz.from(data: time))
        case "tipText":
            let tipText = try ChatTipTextStruct(from: decoder)
            self = .tipText(ChatTipTextBiz.from(data: tipText))
        default:
            self = .unknown(type: type)
        }
    }

    func update(id: UUID, store: ChatStore) {
        let context = store.container.viewContext
        do {
            switch self {
            case .message(let messageBiz):
                let messageCheck = NSFetchRequest<ChatMsgContent>(entityName: "ChatMsgContent")
                messageCheck.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", id])
                let message = try context.fetch(messageCheck).first!
                message.text = messageBiz.text
                
            case .audio(let audioBiz):
                let audioCheck = NSFetchRequest<ChatMsgAudio>(entityName: "ChatMsgAudio")
                audioCheck.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", id])
                let audio = try context.fetch(audioCheck).first!
                audio.text = audioBiz.text
                audio.uri = audioBiz.url
                audio.duration = audioBiz.duration
                
            case .puzzle(let puzzleBiz):
                let puzzleCheck = NSFetchRequest<ChatMsgPuzzle>(entityName: "ChatMsgPuzzle")
                puzzleCheck.predicate = NSPredicate(format: "%K == %@", argumentArray: ["id", id])
                let puzzle = try context.fetch(puzzleCheck).first!
                puzzle.title = puzzleBiz.title
                puzzle.opts = puzzleBiz.optionsToJSON()
                puzzle.other1 = [
                    "selected": puzzleBiz.selected?.id ?? "",
                    "corrected": puzzleBiz.corrected
                ].toJSON()
                puzzle.answer = puzzleBiz.answer
                print("[BIZ]ChatPayload update puzzle: \(puzzleBiz.corrected) \(puzzle.other1)")
            default:
                break
            }
            
            try context.save()
        } catch {
            print("Error updating payload: \(error)")
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
        case .time(let time):
            try container.encode("time", forKey: .type)
            try time.encode(to: encoder)
        case .tipText(let tipText):
            try container.encode("tipText", forKey: .type)
            try tipText.encode(to: encoder)
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
            return (text: puzzle.title, type: "puzzle")
        case .estimate(let estimate):
            return (text: estimate.title, type: "estimate")
        case .error(let error):
            return (text: error.error, type: "error")
        case .tip(let tip):
            return (text: tip.title, type: "tip")
        case .time(let time):
            return (text: time.time.description, type: "time")
        case .tipText(let tipText):
            return (text: tipText.content, type: "tipText")
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
    func updateText(text: String, config: Config) {
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
        return ChatVideoBiz(url: data.url, thumbnail: data.thumbnail, width: data.width, height: data.height, duration: data.duration)
    }
    
    let contentType = "video"
    let url: URL
    let thumbnail: URL
    let width: CGFloat
    let height: CGFloat
    let duration: TimeInterval

    init(url: URL, thumbnail: URL, width: CGFloat, height: CGFloat, duration: TimeInterval) {
        self.url = url
        self.thumbnail = thumbnail
        self.width = width
        self.height = height
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

protocol ChatPuzzleHandler {
    func select(puzzle: ChatPuzzleBiz, option: ChatPuzzleOption)
}
class DefaultChatPuzzleHandler: ChatPuzzleHandler {
    func select(puzzle: ChatPuzzleBiz, option: ChatPuzzleOption) {
        puzzle.selected = option
        puzzle.attempts += 1
        puzzle.corrected = puzzle.answer == option.id
    }
}

class ChatPuzzleBiz: ObservableObject, Encodable {
    static func from(data: ChatPuzzleStruct) -> ChatPuzzleBiz {
        return ChatPuzzleBiz(title: data.title, options: data.options, answer: data.answer, selected: nil, corrected: false)
    }

    let contentType = "puzzle"
    let title: String
    let options: [ChatPuzzleOption]
    var answer: String
    @Published var selected: ChatPuzzleOption?
    @Published var corrected: Bool

    var handler: ChatPuzzleHandler = DefaultChatPuzzleHandler()

    var attempts: Int = 0

    init(title: String, options: [ChatPuzzleOption], answer: String, selected: ChatPuzzleOption?, corrected: Bool, handler: ChatPuzzleHandler = DefaultChatPuzzleHandler()) {
        self.title = title
        self.options = options
        self.answer = answer
        self.selected = selected
        self.corrected = corrected
        self.handler = handler
    }

    func selectOption(option: ChatPuzzleOption) {
        print("[BIZ]ChatPuzzleBiz selectOption: \(option.text) \(selected == nil)")
        if selected == nil {
            self.handler.select(puzzle: self, option: option)
        }
    }
    func isSelected(option: ChatPuzzleOption) -> Bool {
        return self.selected?.id == option.id
    }
    func isCorrect(option: ChatPuzzleOption) -> Bool {
        return self.corrected || self.answer == option.id
    }

    enum CodingKeys: String, CodingKey {
        case contentType
        case title
        case options
        case answer
        case selected
        case corrected
        case attempts
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(title, forKey: .title)
        try container.encode(options, forKey: .options)
        try container.encode(answer, forKey: .answer)
        try container.encode(selected, forKey: .selected)
        try container.encode(corrected, forKey: .corrected)
        try container.encode(attempts, forKey: .attempts)
    }

    // Add new method to convert options to string
    func optionsToJSON() -> String? {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(options)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error encoding options: \(error)")
            return nil
        }
    }
    
    // Add new method to convert string back to options
    static func optionsFromJSON(_ string: String) -> [ChatPuzzleOption]? {
        let decoder = JSONDecoder()
        guard let data = string.data(using: .utf8) else { return nil }
        do {
            return try decoder.decode([ChatPuzzleOption].self, from: data)
        } catch {
            print("Error decoding options: \(error)")
            return nil
        }
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

class ChatTipTextBiz: Encodable {
    static func from(data: ChatTipTextStruct) -> ChatTipTextBiz {
        return ChatTipTextBiz(content: data.content)
    }

    let contentType = "tipText"
    let content: String
    
    init(content: String) {
        self.content = content
    }

    enum CodingKeys: String, CodingKey {
        case contentType
        case content
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(content, forKey: .content)
    }
}

class ChatTimeBiz: Encodable {
    static func from(data: ChatTimeStruct) -> ChatTimeBiz {
        return ChatTimeBiz(time: data.time)
    }
    
    let contentType = "time"
    let time: Date
    
    init(time: Date) {
        self.time = time
    }
    
    enum CodingKeys: String, CodingKey {
        case contentType
        case time
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(time, forKey: .time)
    }
}

extension Dictionary where Key == String {
    func toJSON(pretty: Bool = false) -> String {
        do {
            let options: JSONSerialization.WritingOptions = pretty ? .prettyPrinted : []
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: options)
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            print("Error converting dictionary to JSON: \(error)")
            return "{}"
        }
    }
    
    static func fromJSON(_ jsonString: String) -> [String: Any] {
        guard let jsonData = jsonString.data(using: .utf8) else { return [:] }
        
        do {
            if let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                return dict
            }
            return [:]
        } catch {
            print("Error parsing JSON string to dictionary: \(error)")
            return [:]
        }
    }
}
