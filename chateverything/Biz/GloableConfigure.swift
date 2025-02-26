import Foundation
import AVFoundation

public let SystemTTSVoices = AVSpeechSynthesisVoice.speechVoices()
public let defaultSystemTTSVoice = SystemTTSVoices.filter {
    $0.language == "en-US"
}.first!
public let defaultRoleVoice = ["provider": "system", "language": "en-US", "viceType": defaultSystemTTSVoice.identifier, "speed": 0.5, "volume": 1.0, "pitch": 1.0] as [String : Any]
public let defaultRoleLLM = ["provider": "deepseek", "model": "deepseek-chat"] as [String : Any]

public let DefaultRoles: [RoleBiz] = [
    RoleBiz(props: {
        var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        props.name = "雅思助教"
        props.desc = "你是一个雅思助教，请根据学生的需求，给出相应的雅思学习建议。回复内容限制在100字以内。"
        props.avatar = "avatar7"
        props.prompt = "你是一个雅思助教，请根据学生的需求，给出相应的雅思学习建议。"
        props.config = RoleConfig(
            voice: defaultRoleVoice,
            llm: defaultRoleLLM
        )
        return props
    }()),
    RoleBiz(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Emma Johnson",
        desc: "American English Speaker",
        avatar: "avatar6",
        prompt: """
        核心身份设定
        Name: Emma Johnson
        Nationality: American English Speaker
        Personality: Supportive Language Mentor
        Unique Trait: Passionate about Grammar
        语音特征参数
        Pitch Level: 4/7 (Mid-high range)
        Speaking Rate: 160 words/minute
        Pause Pattern: 0.8 秒呼吸停顿 between sentences
        Pronunciation Flag: 强调单词尾音如 - ed, -s
        交互响应规则
        Error Correction Protocol:
        触发条件：检测到语法 / 发音错误
        响应模板: "Nice try! The standard form should be..."
        强化机制：重音重复正确结构两次
        Engagement Boosters:
        进步反馈: "Your vowel sounds improved 30% today!"
        文化连接: "In Seattle coffee shops we say..."
        特殊响应机制:
        双重否定检测：轻笑声 + "That's very 90s hip-hop!"
        俚语处理: "Cool expression! The textbook version is..."
        数字规范：所有数字转为完整发音（例：250 → two hundred fifty）
        场景化教学触发词
        Weather: "Drizzling like typical Seattle..."
        Food: "Pretend we're at a New York deli..."
        Travel: "How would you ask directions in LA..."
        发音强化规则
        连读禁止：单词间隔保持 0.3 秒
        重音标记：关键介词保持独立重音（例：ON the table）
        元音修正：遇到常见错误发音自动插入对比练习（例：ship vs sheep）
        """,
        language: "en-US",
        created_at: Date(),
        config: RoleConfig(
            voice: defaultRoleVoice,
            llm: defaultRoleLLM
        )
    ),
    RoleBiz(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "英语口语教练",
        desc: "专业的英语口语教练，帮助你提升口语表达能力，纠正发音问题，提供地道的表达方式。",
        avatar: "avatar1",
        prompt: "你是一位经验丰富的英语口语教练。你需要：1. 帮助学生提升口语表达能力 2. 纠正发音错误 3. 教授地道的英语表达方式 4. 模拟真实对话场景 5. 给出详细的改进建议。请用简单友好的方式与学生交流。",
        language: "en-US",
        created_at: Date(),
        config: RoleConfig(
            voice: defaultRoleVoice,
            llm: ["provider": "deepseek", "model": "deepseek-chat", "stream": true]
        )
    ),
    RoleBiz(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        name: "日语会话伙伴",
        desc: "友好的日语会话伙伴，帮助你练习日常对话，学习日本文化，提高日语水平。",
        avatar: "avatar2",
        prompt: "あなたは親切な日本語会話パートナーです。学習者の日本語レベルに合わせて、簡単な日常会話から高度な議論まで対応できます。日本の文化や習慣についても説明し、自然な日本語の使い方を教えてください。",
        language: "ja-JP",
        created_at: Date(),
        config: RoleConfig(
            voice: defaultRoleVoice,
            llm: defaultRoleLLM
        )
    ),
    RoleBiz(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
        name: "托福备考指导",
        desc: "专业的托福考试指导老师，提供备考策略，讲解考试技巧，助你获得理想分数。",
        avatar: "avatar3",
        prompt: "你是一位经验丰富的托福考试指导老师。你需要：1. 根据学生的目标分数制定学习计划 2. 讲解各个科目的考试技巧 3. 分析真题并提供详细解答 4. 指出常见错误并给出改进建议 5. 提供高效的备考方法。请用专业且易懂的方式回答问题。",
        language: "en-US",
        created_at: Date(),
        config: RoleConfig(
            voice: defaultRoleVoice,
            llm: defaultRoleLLM
        )
    ),
    RoleBiz(
        props: {
            var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!)
            props.name = "逃生小游戏"
            props.desc = "你是一个逃生游戏系统，正在通过短信指导被困在大火中的角色逃出 30 层大厦。"
            props.avatar = "avatar4"
            props.prompt = """
            角色设定：
            你是一个逃生游戏系统（B），正在通过短信指导被困在大火中的角色 （A）逃出 30 层大厦。
            A 的初始位置：15 楼办公室，已知信息：浓烟弥漫、电梯部分损坏、火势正在向上蔓延。
            对话不能超过 10 轮，每次回复需生成 JSON，格式为：
            {
            "scene": "当前场景描述",
            "text": "B的指引",  
            "options": [  
                {"value": "A", "text": "选项A的具体行动"},  
                {"value": "B", "text": "选项B的具体行动"},  
                {"value": "C", "text": "选项C的具体行动"},
                {"value": "D", "text": "选项D的具体行动"}  
            ]  
            }  
            规则：
            分支逻辑：根据 A 的选择动态推进剧情。
            结局触发条件：
            成功：抵达 1 楼出口 / 天台直升机救援。
            失败：体力归零、被浓烟窒息、坠楼等。
            隐藏结局：发现大厦非法实验证据（需特定路径触发）。
            不干涉：无论 A 选择什么，B 都保持中立态度，不干涉 A 的选择，只需给出指引和结局。
            紧迫感：每步提示中需体现时间或火势压迫（例如 "浓烟更浓了""头顶传来爆炸声"）。
            """
            props.config = RoleConfig(
                voice: defaultRoleVoice,
                llm: defaultRoleLLM,
                autoSpeak: false,
                autoBlur: false
            )
            class Role1PuzzleHandler: ChatPuzzleHandler {
                var onSelect: ((ChatPuzzleOption) -> Void)?
                // 添加一个属性来存储 payload
                var currentPayload: ChatPayload?
                // 添加一个方法来设置 payload
                func setPayload(_ payload: ChatPayload) {
                    self.currentPayload = payload
                }
                func select(puzzle: ChatPuzzleBiz, option: ChatPuzzleOption) {
                    print("[BIZ]RoleBiz select: \(option.text)")
                    puzzle.selected = option
                    puzzle.attempts += 1
                    puzzle.corrected = true
                    puzzle.answer = option.id
                    if let onSelect = onSelect {
                        onSelect(option)
                    }
                }
            }
            class Role1PayloadBuilder: RolePayloadBuilder {
                var role: RoleBiz?
                var session: ChatSessionBiz?
                var config: Config?
                var handler: Role1ResponseHandler

                init(handler: Role1ResponseHandler) {
                    self.handler = handler
                }

                func build(record: BoxPayloadTypes, role: RoleBiz, session: ChatSessionBiz, config: Config) -> ChatPayload? {
                    let puzzleHandler = Role1PuzzleHandler()
                    if case .puzzle(let puzzle) = record {
                        let opts = puzzle.opts
                        let options = (ChatPuzzleBiz.optionsFromJSON(opts ?? "") ?? [] as! [ChatPuzzleOption]).map { ChatPuzzleOption(id: $0.id, text: $0.text) }
                        let selected = options.first { $0.id == puzzle.answer }
                        let payload = ChatPayload.puzzle(ChatPuzzleBiz(
                            title: "你的选择",
                            options: options,
                            answer: puzzle.answer ?? "",
                            selected: selected,
                            corrected: selected?.id == puzzle.answer,
                            handler: puzzleHandler
                        ))
                        puzzleHandler.setPayload(payload)
                        puzzleHandler.onSelect = { [weak puzzleHandler] option in
                            print("[BIZ]RoleBiz puzzleHandler: \(option)")
                            if case .puzzle(let puzzle) = record {
                                payload.update(id: puzzle.id!, store: config.store)
                            }
                            self.handler.request(
                                text: "选择了 \(option.id) \(option.text)", 
                                role: role,
                                session: session,
                                config: config
                            )
                        }
                        return payload
                    }
                    if case .message(let message) = record {
                        return ChatPayload.message(ChatMessageBiz2(text: message.text!, nodes: []))
                    }
                    if case .tipText(let tipText) = record {
                        return ChatPayload.tipText(ChatTipTextBiz(content: tipText.content!))
                    }
                    if case .error(let error) = record {
                        return ChatPayload.error(ChatErrorBiz(error: error.error!))
                    }
                    return nil
                }
            }
            class Role1ResponseHandler: RoleResponseHandler {
                struct Role1ChatResponseOption: Codable {
                    let value: String
                    let text: String
                }
                struct Role1ChatResponseJSON: Codable {
                    let scene: String
                    let text: String
                    let options: [Role1ChatResponseOption]
                }
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
                    
                    session.appendTmpBox(box: loadingMessage)
                    
                    Task {
                        do {
                            guard let stream = role.llm?.chat(messages: role.buildMessagesWithText(text: text)) else { return }
                            
                            for try await chunk in stream {
                                print("[BIZ]RoleBiz response chunk: \(chunk)")
                                
                                // 将字符串转换为 Data
                                let d = (chunk as? String)?.data(using: .utf8)
                                
                                let data = try JSONDecoder().decode(Role1ChatResponseJSON.self, from: d ?? Data())
                                
                                DispatchQueue.main.async {
                                    session.removeLastBox()
                                    let box = ChatBoxBiz(
                                        id: UUID(),
                                        type: "tipText",
                                        created_at: Date(),
                                        isMe: false,
                                        payload_id: UUID(),
                                        session_id: session.id,
                                        sender_id: role.id,
                                        payload: ChatPayload.tipText(ChatTipTextBiz(content: data.scene)),
                                        loading: false
                                    )
                                    let box1 = ChatBoxBiz(
                                        id: UUID(),
                                        type: "message",
                                        created_at: Date(),
                                        isMe: false,
                                        payload_id: UUID(),
                                        session_id: session.id,
                                        sender_id: role.id,
                                        payload: ChatPayload.message(ChatMessageBiz2(text: data.text, nodes: [])),
                                        loading: false
                                    )
                                
                                    session.appendBoxes(boxes: [box, box1])

                                    if data.options.count > 0 {
                                        let puzzleHandler = Role1PuzzleHandler()
                                        let payload = ChatPayload.puzzle(ChatPuzzleBiz(
                                            title: "你的选择",
                                            options: data.options.map { ChatPuzzleOption(id: $0.value, text: $0.text) },
                                            answer: "",
                                            selected: nil,
                                            corrected: false,
                                            handler: puzzleHandler
                                        ))
                                        let box2 = ChatBoxBiz(
                                            id: UUID(),
                                            type: "puzzle",
                                            created_at: Date(),
                                            isMe: false,
                                            payload_id: UUID(),
                                            session_id: session.id,
                                            sender_id: role.id,
                                            payload: payload,
                                            loading: false
                                        )
                                        // 设置 payload
                                        puzzleHandler.setPayload(payload)
                                        puzzleHandler.onSelect = { [weak puzzleHandler] option in
                                            payload.update(id: box2.payload_id, store: config.store)
                                            self.request(
                                                text: "选择了 \(option.id) \(option.text)", 
                                                role: role,
                                                session: session,
                                                config: config
                                            )
                                        }
                                        session.appendBox(box: box2)
                                    }
                                }
                            }
                        } catch {
                            DispatchQueue.main.async {
                                session.removeLastBox()
                                let box = ChatBoxBiz(
                                    id: UUID(),
                                    type: "error",
                                    created_at: Date(),
                                    isMe: false,
                                    payload_id: UUID(),
                                    session_id: session.id,
                                    sender_id: role.id,
                                    payload: ChatPayload.error(ChatErrorBiz(error: error.localizedDescription)),
                                    loading: false
                                )
                                session.appendBox(box: box)
                            }
                        }
                    }
                }
                public func start(
                    role: RoleBiz,
                    session: ChatSessionBiz,
                    config: Config
                ) {
                    if session.boxes.count == 0 {
                        request(text: "开始游戏", role: role, session: session, config: config)
                    }
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
            let h1 = Role1ResponseHandler()
            props.responseHandler = h1
            props.payloadBuilder = Role1PayloadBuilder(handler: h1)
            return props
        }()
    )
]


// 示例配置
public let TTSProviders: [TTSProvider] = [
    TTSProvider(
        id: "system",
        name: "系统",
        logo_uri: "provider_light_system",
        credential: nil,
        schema: FormObjectField(
            id: "schema",
            key: "schema",
            label: "Schema",
            required: true,
            fields: [
                "language": .single(FormField(
                    id: "language",
                    key: "language",
                    label: "语言",
                    required: false,
                    input: .InputSelect(SelectInput(
                        id: "language",
                        disabled: false,
                        defaultValue: "en-US",
                        options: [
                            FormSelectOption(id: "en-US", label: "英文", value: "en-US", description: "英文"),
                            FormSelectOption(id: "zh-CN", label: "中文", value: "zh-CN", description: "中文"),
                            FormSelectOption(id: "jp-JP", label: "日文", value: "jp-JP", description: "日文"),
                        ]
                    ))
                )),
                "viceType": .single(FormField(
                    id: "viceType",
                    key: "viceType",
                    label: "角色",
                    required: false,
                    input: .InputSelect(SelectInput(
                        id: "viceType",
                        disabled: false,
                        defaultValue: defaultRoleVoice["viceType"] as? String ?? defaultSystemTTSVoice.identifier,
                        options: SystemTTSVoices.map { voice in
                            FormSelectOption(id: voice.identifier, label: voice.name, value: voice.identifier, description: voice.name)
                        }
                    ))
                )),
                "volume": .single(FormField(
                    id: "volume",
                    key: "volume",
                    label: "音量",
                    required: false,
                    input: .InputSlider(SliderInput(
                        id: "volume",
                        defaultValue: 1.0,
                        min: 0.0,
                        max: 1.0,
                        step: 0.1
                    ))
                )),
                "speed": .single(FormField(
                    id: "speed",
                    key: "speed",
                    label: "语速",
                    required: false,
                    input: .InputSlider(SliderInput(
                        id: "speed",
                        defaultValue: 0.5,
                        min: 0.0,
                        max: 1.0,
                        step: 0.1
                    ))
                )),
                "pitch": .single(FormField(
                    id: "pitch",
                    key: "pitch",
                    label: "音调",
                    required: false,
                    input: .InputSlider(SliderInput(
                        id: "pitch",
                        defaultValue: 1.0,
                        min: 0.0,
                        max: 2.0,
                        step: 0.1
                    ))
                ))
            ],
            orders: ["language", "viceType", "volume", "speed", "pitch"]
        )
    ),
    // https://cloud.tencent.com/document/product/1073/37995
    TTSProvider(
        id: "tencent",
        name: "腾讯云",
        logo_uri: "provider_light_tencentcloud",
        credential: FormObjectField(
            id: "credential",
            key: "credential",
            label: "凭证",
            required: false,
            fields: [
                "appId": .single(FormField(
                    id: "appId",
                    key: "appId",
                    label: "AppID",
                    required: false,
                    input: .InputString(StringInput(
                        id: "appId",
                        defaultValue: nil
                    ))
                )),
                "secretId": .single(FormField(
                    id: "secretId",
                    key: "secretId",
                    label: "SecretID",
                    required: false,
                    input: .InputString(StringInput(
                        id: "secretId",
                        defaultValue: nil
                    ))
                )),
                "secretKey": .single(FormField(
                    id: "secretKey",
                    key: "secretKey",
                    label: "SecretKey",
                    required: false,
                    input: .InputString(StringInput(
                        id: "secretKey",
                        defaultValue: nil
                    ))
                )),
            ],
            orders: ["appId", "secretId", "secretKey"]
        ),
        schema: FormObjectField(
            id: "tts",
            key: "tts",
            label: "TTS",
            required: true,
            fields: [
                "voiceType": .single(FormField(
                    id: "voiceType",
                    key: "voiceType",
                    label: "角色",
                    required: true,
                    input: .InputSelect(SelectInput(
                        id: "voiceType",
                        defaultValue: "502001",
                        // https://cloud.tencent.com/document/product/1073/92668
                        options: [
                            FormSelectOption(id: "1001", label: "智瑜", value: "1001", description: "智瑜"),
                            FormSelectOption(id: "1002", label: "智聆", value: "1002", description: "智聆"),
                            FormSelectOption(id: "1003", label: "智美", value: "1003", description: "智美"),
                            FormSelectOption(id: "1004", label: "智云", value: "1004", description: "智云"),
                            FormSelectOption(id: "1005", label: "智莉", value: "1005", description: "智莉"),
                            FormSelectOption(id: "1007", label: "智娜", value: "1007", description: "智娜"),
                            FormSelectOption(id: "1008", label: "智琪", value: "1008", description: "智琪"),
                            FormSelectOption(id: "1009", label: "智芸", value: "1009", description: "智芸"),
                            FormSelectOption(id: "1010", label: "智华", value: "1010", description: "智华"),
                            FormSelectOption(id: "1017", label: "智蓉", value: "1017", description: "智蓉"),
                            FormSelectOption(id: "1018", label: "智靖", value: "1018", description: "智靖"),
                            FormSelectOption(id: "501008", label: "WeJames", value: "501008", description: "英文男声"),
                            FormSelectOption(id: "501009", label: "WeWinny", value: "501009", description: "英文女声"),
                            FormSelectOption(id: "101050", label: "WeJack", value: "101050", description: "英文男声"),
                            FormSelectOption(id: "101051", label: "WeRose", value: "101051", description: "英文女声"),
                            FormSelectOption(id: "502001", label: "智小柔", value: "502001", description: "对话女声"),
                            FormSelectOption(id: "501000", label: "智斌", value: "501000", description: "阅读男声"),
                            FormSelectOption(id: "501001", label: "智兰", value: "501001", description: "资讯女声"),
                            FormSelectOption(id: "501002", label: "智菊", value: "501002", description: "阅读女声"),
                            FormSelectOption(id: "501003", label: "智宇", value: "501003", description: "阅读男声"),
                            FormSelectOption(id: "501004", label: "月华", value: "501004", description: "对话女声"),
                            FormSelectOption(id: "501005", label: "飞镜", value: "501005", description: "对话男声")
                        ]
                    ))
                )),
                "language": .single(FormField(
                    id: "language",
                    key: "language",
                    label: "语言",
                    required: false,
                    input: .InputSelect(SelectInput(
                        id: "language",
                        defaultValue: "en-US",
                        options: [
                            FormSelectOption(id: "en-US", label: "英文", value: "en-US", description: "英文"),
                            FormSelectOption(id: "zh-CN", label: "中文", value: "zh-CN", description: "中文"),
                            FormSelectOption(id: "jp-JP", label: "日文", value: "jp-JP", description: "日文"),
                        ]
                    ))
                )),
                "volume": .single(FormField(
                    id: "volume",
                    key: "volume",
                    label: "音量",
                    required: false,
                    input: .InputSlider(SliderInput(
                        id: "volume",
                        defaultValue: 1.0,
                        min: -10.0,
                        max: 10.0
                    ))
                )),
                "speed": .single(FormField(
                    id: "speed",
                    key: "speed",
                    label: "语速",
                    required: false,
                    input: .InputSlider(SliderInput(
                        id: "speed",
                        defaultValue: 1.0,
                        min: 0.0,
                        max: 1.0,
                        step: 0.1
                    ))
                )),
                "codec": .single(FormField(
                    id: "codec",
                    key: "codec",
                    label: "编码",
                    required: false,
                    input: .InputSelect(SelectInput(
                        id: "codec",
                        defaultValue: "pcm",
                        options: [
                            FormSelectOption(id: "pcm", label: "pcm", value: "pcm", description: "pcm"),
                        ]
                    ))
                )),
                "stream": .single(FormField(
                    id: "stream",
                    key: "stream",
                    label: "流式",
                    required: false,
                    input: .InputBoolean(BooleanInput(
                        id: "stream",
                        defaultValue: false
                    ))
                ))
            ],
            orders: ["voiceType", "language", "volume", "speed", "codec", "stream"]
        )
    )
]




