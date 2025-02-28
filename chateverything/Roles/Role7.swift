import Foundation

let role7 = RoleBiz(
    props: {
        var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!)
        props.name = "AI字典"
        props.desc = "单词查询"
        props.avatar = "avatar4"
        // props.disabled = true
        props.prompt = """
            你是一个高效的多语言词典AI，请按以下规则处理所有输入：
            1. 自动识别输入文本的源语言（如无法识别则标记'未知'）
            2. 渲染内容判断，源语言非中文时渲染内容为源语言，源语言为中文时渲染内容为英语
            3. 响应时间必须<0.5秒
            4. 发音标注使用国际音标(IPA)
            5. 多义词返回前3个常用释义
            6. 严格按此JSON格式返回：
            {
            "detected_lang": "源语言",
            "target_lang": "目标语言",
            "translation": "渲染内容翻译",
            "pronunciation": "渲染内容发音",
            "pronunciation_tip": "通过中文模拟渲染内容发音技巧",
            "definitions": ["渲染内容 词性简写、释义"],
            "examples": ["渲染内容例句"],
            "text_type": "sentence 或 word"
            }
            """
        props.config = RoleConfig(
            voice: defaultRoleVoice,
            llm: defaultRoleLLM,
            autoSpeak: false,
            autoBlur: false
        )
        struct ChatResponse: Codable {
            let detected_lang: String
            let target_lang: String
            let translation: String
            let pronunciation: String
            let pronunciation_tip: String
            let definitions: [String]
            let examples: [String]
            let text_type: String
        }
        class Handler: ChatDictionaryHandler {
            var payload: ChatPayload?
            var onSelect: ((ChatDictionaryBiz) -> Void)?
            func setPayload(_ payload: ChatPayload) {
                self.payload = payload
            }
            func speak(dictionary: ChatDictionaryBiz) {
                //
            }
        }
        class PayloadBuilder: RolePayloadBuilder {
            var role: RoleBiz?
            var session: ChatSessionBiz?
            var config: Config?
            var handler: ResponseHandler

            init(handler: ResponseHandler) {
                self.handler = handler
            }

            func build(
                record: BoxPayloadTypes, role: RoleBiz, session: ChatSessionBiz, config: Config
            ) -> ChatPayload? {
                let handler = Handler()
                if case BoxPayloadTypes.dictionary(let dictionary) = record {
                    let payload = ChatPayload.dictionary(
                        ChatDictionaryBiz(
                            text: dictionary.text!,
                            detected_lang: dictionary.detected_lang!,
                            target_lang: dictionary.target_lang!,
                            translation: dictionary.translation!,
                            pronunciation: dictionary.pronunciation!,
                            pronunciation_tip: dictionary.pronunciation_tip!,
                            definitions: Array.fromJSON(dictionary.definitions!),
                            examples: Array.fromJSON(dictionary.examples!),
                            text_type: dictionary.text_type!
                        ))
                    handler.setPayload(payload)
                    handler.onSelect = { [weak handler] dictionary in
                        print("[BIZ]RoleBiz dictionaryHandler: \(dictionary)")
                    }
                    return payload
                }
                if case .message(let message) = record {
                    return ChatPayload.message(ChatMessageBiz2(text: message.text!, nodes: []))
                }
                if case .error(let error) = record {
                    return ChatPayload.error(ChatErrorBiz(error: error.error!))
                }
                return nil
            }
        }
        class ResponseHandler: RoleResponseHandler {
            func request(
                text: String,
                role: RoleBiz,
                session: ChatSessionBiz,
                config: Config
            ) {
                let loadingMessage = ChatBoxBiz(
                    id: UUID(),
                    type: "message",
                    created_at: Date(),
                    isMe: false,
                    payload_id: UUID(),
                    session_id: session.id,
                    sender_id: role.id,
                    payload: ChatPayload.message(ChatMessageBiz2(text: "", nodes: [])),
                    loading: true
                )
                DispatchQueue.main.async {
                    session.appendTmpBox(box: loadingMessage)
                }
                let events = LLMServiceEvents(
                    onStart: {
                        print("[BIZ]RoleBiz onStart")
                    },
                    onChunk: { chunk in
                        print("[BIZ]RoleBiz onChunk: \(chunk)")
                    },
                    onFinish: { result in
                        print("[BIZ]RoleBiz onFinish: \(result)")
                        Task {
                            do {
                                let d = (result as? String)?.data(using: .utf8)
                                print("[BIZ]RoleBiz onFinish: \(d)")
                                let data = try! JSONDecoder().decode(
                                    ChatResponse.self, from: d ?? Data())
                                DispatchQueue.main.async {
                                    session.removeLastBox()
                                    let box = ChatBoxBiz(
                                        id: UUID(),
                                        type: "dictionary",
                                        created_at: Date(),
                                        isMe: false,
                                        payload_id: UUID(),
                                        session_id: session.id,
                                        sender_id: role.id,
                                        payload: ChatPayload.dictionary(ChatDictionaryBiz(
                                            text: text,
                                            detected_lang: data.detected_lang,
                                            target_lang: data.target_lang,
                                            translation: data.translation,
                                            pronunciation: data.pronunciation,
                                            pronunciation_tip: data.pronunciation_tip,
                                            definitions: data.definitions,
                                            examples: data.examples,
                                            text_type: data.text_type
                                        )),
                                        loading: false,
                                        blurred: role.config.autoBlur
                                    )
                                    session.appendBox(box: box)
                                }
                            } catch {
                                print("[BIZ]RoleBiz onFinish: \(error)")
                            }
                        }
                    },
                    onError: { error in
                        print("[BIZ]RoleBiz onError: \(error)")
                        session.removeLastBox()
                        let box = ChatBoxBiz(
                            id: UUID(),
                            type: "error",
                            created_at: Date(),
                            isMe: false,
                            payload_id: UUID(),
                            session_id: session.id,
                            sender_id: role.id,
                            payload: ChatPayload.error(
                                ChatErrorBiz(error: error.localizedDescription)),
                            loading: false
                        )
                        session.appendBox(box: box)
                    }
                )
                role.llm?.setEvents(events: events)

                Task {
                    guard
                        let stream = role.llm?.chat(
                            messages: [
                                LLMServiceMessage(role: "system", content: role.prompt),
                                LLMServiceMessage(role: "user", content: text),
                            ])
                    else { return }
                }
            }
            public func start(
                role: RoleBiz,
                session: ChatSessionBiz,
                config: Config
            ) {
            }
            public func handle(
                text: String,
                role: RoleBiz,
                session: ChatSessionBiz,
                config: Config,
                completion: (([ChatBoxBiz]) -> Void)?
            ) {
                request(text: text, role: role, session: session, config: config)
            }
        }
        props.responseHandler = ResponseHandler()
        props.payloadBuilder = PayloadBuilder(handler: props.responseHandler as! ResponseHandler)
        return props
    }()
)
