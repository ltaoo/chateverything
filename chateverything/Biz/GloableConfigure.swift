import AVFoundation
import Foundation

public let SystemTTSVoices = AVSpeechSynthesisVoice.speechVoices()
// com.apple.speech.synthesis.voice.Bahh en-US Bahh
// com.apple.speech.synthesis.voice.Albert en-US Albert
// com.apple.eloquence.en-US.Rocko en-US Rocko
// com.apple.eloquence.en-US.Shelley en-US Shelley
// com.apple.speech.synthesis.voice.Princess en-US Superstar
// com.apple.eloquence.en-US.Eddy en-US Eddy 男声1
// com.apple.speech.synthesis.voice.Bells en-US Bells 歌唱男声
// com.apple.speech.synthesis.voice.Trinoids en-US Trinoids 机器人
// com.apple.speech.synthesis.voice.Kathy en-US Kathy 机器人
// com.apple.eloquence.en-US.Reed en-US Reed 男声1
// com.apple.speech.synthesis.voice.Boing en-US Boing 沙哑男声
// com.apple.speech.synthesis.voice.Whisper en-US Whisper 低语男声
// com.apple.speech.synthesis.voice.GoodNews en-US Good News 歌唱男声
// com.apple.speech.synthesis.voice.Deranged en-US Wobble 哭泣男声
// com.apple.ttsbundle.siri_Nicky_en-US_compact en-US Nicky 很好的女声
// com.apple.ttsbundle.siri_Aaron_en-US_compact en-US Aaron 男声2
// com.apple.voice.compact.en-US.Samantha en-US Samantha 女声2
// com.apple.speech.synthesis.voice.Ralph en-US Ralph 低沉男声
let personHaveGoodsVoices = ["Eddy", "Reed", "Nicky", "Aaron", "Samantha", "Ralph"]
let supportedLanguages = ["en-US", "ja-JP", "zh-CN"]

public let defaultSystemTTSVoices = SystemTTSVoices.filter {
    supportedLanguages.contains($0.language) && personHaveGoodsVoices.contains($0.name)
}
let a = defaultSystemTTSVoices.map() {
    print("\($0.name) \($0.language) \($0.identifier)")
    return
}
public let defaultSystemTTSVoice = defaultSystemTTSVoices.first!
public let defaultRoleTTS =
    [
        "provider": "system", "language": "en-US", "viceType": defaultSystemTTSVoice.identifier,
        "speed": 0.5, "volume": 1.0, "pitch": 1.0,
    ] as [String: Any]
public let defaultRoleLLM = ["provider": "build-in", "model": "deepseek-v3-241226"] as [String: Any]

public let DefaultRoles: [RoleBiz] = [
    RoleBiz(
        props: {
            var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
            props.name = "Lily Smith"
            props.desc = "活泼开朗、好奇心强、友善热情，喜欢结交新朋友"
            props.avatar = "avatar13"
            props.prompt = """
                你的设定是
                姓名:Lily Smith
                年龄:18岁
                身份:高中生
                外貌:一头金色长发，明亮的蓝色眼睛，皮肤白皙，身材苗条。总是背着一个印有可爱卡通图案的书包。
                性格:活泼开朗、好奇心强、友善热情，喜欢结交新朋友。
                爱好:听流行音乐、看青春电影、和朋友们一起逛街。
                梦想:考上一所著名的艺术院校，学习服装设计。
                英语口语水平:中等偏上，能流畅表达日常话题，但在专业领域词汇和复杂语法上还有提升空间。
                沟通过程要正常、自然，不要包含口语之外的任何内容，不要主动说明自己的信息，可以引导对方聊一些简单的话题。
                """
            props.config = RoleConfig(
                voice: [
                    "provider": "system", "language": "en-US",
                    "viceType": "com.apple.ttsbundle.siri_Nicky_en-US_compact", "speed": 0.5,
                    "volume": 1.0, "pitch": 1.0,
                ],
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
            voice: defaultRoleTTS,
            llm: defaultRoleLLM
        )
    ),
    RoleBiz(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "David Brown",
        desc: "冷静理智、有责任心、果断且具有领导能力，在工作中注重效率和质量",
        avatar: "avatar11",
        prompt: """
            你的设定是
            姓名:David Brown
            年龄:30 岁
            身份:软件公司的项目经理
            外貌:留着利落的短发，眼神专注而自信，经常穿着整洁的西装，系着简约的领带。
            性格:冷静理智、有责任心、果断且具有领导能力，在工作中注重效率和质量。
            爱好:阅读商业管理书籍、打高尔夫球、观看科技类纪录片。
            梦想:带领团队开发出具有创新性的软件产品，在行业内取得显著成就。
            英语口语水平:高级，能够熟练运用专业词汇进行商务谈判和技术交流，语言表达准确、流畅。
            沟通过程要正常、自然，不要包含口语之外的任何内容，不要主动说明自己的信息，可以引导对方聊一些复杂的话题。
        """,
        language: "en-US",
        created_at: Date(),
        config: RoleConfig(
            voice: [
                "provider": "system", "language": "en-US",
                "viceType": "com.apple.speech.synthesis.voice.Ralph", "speed": 0.5, "volume": 1.0,
                "pitch": 1.0,
            ],
            llm: ["provider": "deepseek", "model": "deepseek-chat", "stream": true]
        )
    ),
    RoleBiz(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        name: "Alex Chen",
        desc: "勇敢无畏、乐观豁达、充满冒险精神，喜欢尝试新鲜事物",
        avatar: "avatar12",
        prompt: """
            你的设定是
            姓名:Alex Chen
            年龄:25 岁
            身份:自由职业者，同时也是一名旅行博主
            外貌:皮肤晒成健康的小麦色，眼神中充满了探索的渴望，背着一个大大的旅行背包，穿着舒适的户外服装。
            性格:勇敢无畏、乐观豁达、充满冒险精神，喜欢尝试新鲜事物。
            爱好:徒步旅行、拍摄风景照片、品尝各地美食。
            梦想:环游世界，用镜头记录下不同国家和地区的风土人情，分享给更多的人。
            英语口语水平:良好，在旅游相关话题上词汇丰富，能够与不同国家的人进行无障碍交流。
            沟通过程要正常、自然，不要包含口语之外的任何内容，不要主动说明自己的信息，可以引导对方聊一些复杂的话题。
        """,
        language: "en-US",
        created_at: Date(),
        config: RoleConfig(
            voice: [
                "provider": "system", "language": "en-US",
                "viceType": "com.apple.ttsbundle.siri_Aaron_en-US_compact", "speed": 0.5, "volume": 1.0,
                "pitch": 1.0,
            ],
            llm: defaultRoleLLM
        )
    ),
    RoleBiz(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
        name: "小林（こばやし）",
        desc: "热情开朗，健谈，有很强的责任心，工作时认真严谨，休息时喜欢放松娱乐",
        avatar: "avatar10",
        prompt: """
            你的设定是
            姓名：小林（こばやし）
            年龄：28 岁
            职业：广告公司文案策划
            性格：热情开朗，健谈，有很强的责任心，工作时认真严谨，休息时喜欢放松娱乐。
            爱好：喜欢看电影，喜欢旅游，喜欢美食，喜欢运动，喜欢音乐，喜欢读书，喜欢玩游戏。
            梦想：希望自己能够成为一名优秀的广告文案策划，能够写出优秀的广告文案，能够帮助客户解决问题，能够获得客户的认可。
            日语口语水平：日语母语者，日语口语水平良好，能够流利表达日常话题，但在专业领域词汇和复杂语法上还有提升空间。
            沟通过程要正常、自然，不要包含口语之外的任何内容，不要主动说明自己的信息，可以引导对方聊一些简单的话题。
            """,
        language: "ja-JP",
        created_at: Date(),
        config: RoleConfig(
            voice: [
                "provider": "system", "language": "ja-JP",
                "viceType": "com.apple.ttsbundle.siri_Aaron_ja-JP_compact", "speed": 0.5,
                "volume": 1.0,
                "pitch": 1.0,
            ],
            llm: defaultRoleLLM
        )
    ),
     RoleBiz(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
        name: "美纪（みき）",
        desc: "热情开朗，健谈，有很强的责任心，工作时认真严谨，休息时喜欢放松娱乐",
        avatar: "avatar9",
        prompt: """
            姓名：美纪（みき）
            年龄：20 岁
            职业：大学二年级学生，专业是文学
            性格：温柔文静，有点害羞，但内心充满好奇心，对新事物很感兴趣。
            爱好：阅读、写作、参加社团活动
            梦想：成为一名优秀的作家，写出优秀的作品，能够获得读者的认可。
            日语口语水平：日语母语者，日语口语水平良好，能够流利表达日常话题，但在专业领域词汇和复杂语法上还有提升空间。
            沟通过程要正常、自然，不要包含口语之外的任何内容，不要主动说明自己的信息，可以引导对方聊一些简单的话题。
        """,
        language: "ja-JP",
        created_at: Date(),
        config: RoleConfig(
            voice: [
                "provider": "system", "language": "ja-JP",
                "viceType": "com.apple.ttsbundle.siri_Nicky_en-US_compact", "speed": 0.5,
                "volume": 1.0,
                "pitch": 1.0,
            ],
            llm: defaultRoleLLM
        )
    ),
    RoleBiz(
        props: {
            var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-100000000000")!)
            props.name = "系统女声"
            props.desc = ""
            props.avatar = "avatar7"
            props.disabled = true
            props.prompt = ""
            props.config = RoleConfig(
                voice: [
                    "provider": "system", "language": "en-US",
                    "viceType": "com.apple.voice.compact.en-US.Samantha", "speed": 0.5,
                    "volume": 1.0, "pitch": 1.0,
                ],
                llm: defaultRoleLLM
            )
            return props
        }()),
    RoleBiz(
        props: {
            var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-100000000001")!)
            props.name = "系统男声"
            props.desc = ""
            props.avatar = "avatar7"
            props.disabled = true
            props.prompt = ""
            props.config = RoleConfig(
                voice: [
                    "provider": "system", "language": "en-US",
                    "viceType": "com.apple.ttsbundle.siri_Aaron_en-US_compact", "speed": 0.8,
                    "volume": 1.0, "pitch": 1.0,
                ],
                llm: defaultRoleLLM
            )
            return props
        }()),
    role6,
    role7,
]

// 示例配置
public let TTSProviders: [TTSProvider] = [
    TTSProvider(
        id: "system",
        name: "系统",
        logo_uri: "chateverything",
        // logo_uri: "provider_light_system",
        credential: nil,
        schema: FormObjectField(
            id: "schema",
            key: "schema",
            label: "Schema",
            required: true,
            fields: [
                "language": .single(
                    FormField(
                        id: "language",
                        key: "language",
                        label: "语言",
                        required: false,
                        input: .InputSelect(
                            SelectInput(
                                id: "language",
                                disabled: false,
                                defaultValue: "en-US",
                                options: [
                                    FormSelectOption(
                                        id: "en-US", label: "英文", value: "en-US", description: "英文"),
                                    FormSelectOption(
                                        id: "zh-CN", label: "中文", value: "zh-CN", description: "中文"),
                                    FormSelectOption(
                                        id: "jp-JP", label: "日文", value: "jp-JP", description: "日文"),
                                ]
                            ))
                    )),
                "viceType": .single(
                    FormField(
                        id: "viceType",
                        key: "viceType",
                        label: "角色",
                        required: false,
                        input: .InputSelect(
                            SelectInput(
                                id: "viceType",
                                disabled: false,
                                defaultValue: defaultRoleTTS["viceType"] as? String
                                    ?? defaultSystemTTSVoice.identifier,
                                options: defaultSystemTTSVoices.map { voice in
                                    FormSelectOption(
                                        id: voice.identifier,
                                        label: "\(voice.name) \(voice.language)",
                                        value: voice.identifier, description: voice.name)
                                }
                            ))
                    )),
                "volume": .single(
                    FormField(
                        id: "volume",
                        key: "volume",
                        label: "音量",
                        required: false,
                        input: .InputSlider(
                            SliderInput(
                                id: "volume",
                                defaultValue: 1.0,
                                min: 0.0,
                                max: 1.0,
                                step: 0.1
                            ))
                    )),
                "speed": .single(
                    FormField(
                        id: "speed",
                        key: "speed",
                        label: "语速",
                        required: false,
                        input: .InputSlider(
                            SliderInput(
                                id: "speed",
                                defaultValue: 0.5,
                                min: 0.0,
                                max: 1.0,
                                step: 0.1
                            ))
                    )),
                "pitch": .single(
                    FormField(
                        id: "pitch",
                        key: "pitch",
                        label: "音调",
                        required: false,
                        input: .InputSlider(
                            SliderInput(
                                id: "pitch",
                                defaultValue: 1.0,
                                min: 0.0,
                                max: 2.0,
                                step: 0.1
                            ))
                    )),
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
                "appId": .single(
                    FormField(
                        id: "appId",
                        key: "appId",
                        label: "AppID",
                        required: false,
                        input: .InputString(
                            StringInput(
                                id: "appId",
                                defaultValue: nil
                            ))
                    )),
                "secretId": .single(
                    FormField(
                        id: "secretId",
                        key: "secretId",
                        label: "SecretID",
                        required: false,
                        input: .InputString(
                            StringInput(
                                id: "secretId",
                                defaultValue: nil
                            ))
                    )),
                "secretKey": .single(
                    FormField(
                        id: "secretKey",
                        key: "secretKey",
                        label: "SecretKey",
                        required: false,
                        input: .InputString(
                            StringInput(
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
                "voiceType": .single(
                    FormField(
                        id: "voiceType",
                        key: "voiceType",
                        label: "角色",
                        required: true,
                        input: .InputSelect(
                            SelectInput(
                                id: "voiceType",
                                defaultValue: "502001",
                                // https://cloud.tencent.com/document/product/1073/92668
                                options: [
                                    FormSelectOption(
                                        id: "1001", label: "智瑜", value: "1001", description: "智瑜"),
                                    FormSelectOption(
                                        id: "1002", label: "智聆", value: "1002", description: "智聆"),
                                    FormSelectOption(
                                        id: "1003", label: "智美", value: "1003", description: "智美"),
                                    FormSelectOption(
                                        id: "1004", label: "智云", value: "1004", description: "智云"),
                                    FormSelectOption(
                                        id: "1005", label: "智莉", value: "1005", description: "智莉"),
                                    FormSelectOption(
                                        id: "1007", label: "智娜", value: "1007", description: "智娜"),
                                    FormSelectOption(
                                        id: "1008", label: "智琪", value: "1008", description: "智琪"),
                                    FormSelectOption(
                                        id: "1009", label: "智芸", value: "1009", description: "智芸"),
                                    FormSelectOption(
                                        id: "1010", label: "智华", value: "1010", description: "智华"),
                                    FormSelectOption(
                                        id: "1017", label: "智蓉", value: "1017", description: "智蓉"),
                                    FormSelectOption(
                                        id: "1018", label: "智靖", value: "1018", description: "智靖"),
                                    FormSelectOption(
                                        id: "501008", label: "WeJames", value: "501008",
                                        description: "英文男声"),
                                    FormSelectOption(
                                        id: "501009", label: "WeWinny", value: "501009",
                                        description: "英文女声"),
                                    FormSelectOption(
                                        id: "101050", label: "WeJack", value: "101050",
                                        description: "英文男声"),
                                    FormSelectOption(
                                        id: "101051", label: "WeRose", value: "101051",
                                        description: "英文女声"),
                                    FormSelectOption(
                                        id: "502001", label: "智小柔", value: "502001",
                                        description: "对话女声"),
                                    FormSelectOption(
                                        id: "501000", label: "智斌", value: "501000",
                                        description: "阅读男声"),
                                    FormSelectOption(
                                        id: "501001", label: "智兰", value: "501001",
                                        description: "资讯女声"),
                                    FormSelectOption(
                                        id: "501002", label: "智菊", value: "501002",
                                        description: "阅读女声"),
                                    FormSelectOption(
                                        id: "501003", label: "智宇", value: "501003",
                                        description: "阅读男声"),
                                    FormSelectOption(
                                        id: "501004", label: "月华", value: "501004",
                                        description: "对话女声"),
                                    FormSelectOption(
                                        id: "501005", label: "飞镜", value: "501005",
                                        description: "对话男声"),
                                ]
                            ))
                    )),
                "language": .single(
                    FormField(
                        id: "language",
                        key: "language",
                        label: "语言",
                        required: false,
                        input: .InputSelect(
                            SelectInput(
                                id: "language",
                                defaultValue: "en-US",
                                options: [
                                    FormSelectOption(
                                        id: "en-US", label: "英文", value: "en-US", description: "英文"),
                                    FormSelectOption(
                                        id: "zh-CN", label: "中文", value: "zh-CN", description: "中文"),
                                    FormSelectOption(
                                        id: "jp-JP", label: "日文", value: "jp-JP", description: "日文"),
                                ]
                            ))
                    )),
                "volume": .single(
                    FormField(
                        id: "volume",
                        key: "volume",
                        label: "音量",
                        required: false,
                        input: .InputSlider(
                            SliderInput(
                                id: "volume",
                                defaultValue: 1.0,
                                min: -10.0,
                                max: 10.0
                            ))
                    )),
                "speed": .single(
                    FormField(
                        id: "speed",
                        key: "speed",
                        label: "语速",
                        required: false,
                        input: .InputSlider(
                            SliderInput(
                                id: "speed",
                                defaultValue: 1.0,
                                min: 0.0,
                                max: 1.0,
                                step: 0.1
                            ))
                    )),
                "codec": .single(
                    FormField(
                        id: "codec",
                        key: "codec",
                        label: "编码",
                        required: false,
                        input: .InputSelect(
                            SelectInput(
                                id: "codec",
                                defaultValue: "pcm",
                                options: [
                                    FormSelectOption(
                                        id: "pcm", label: "pcm", value: "pcm", description: "pcm")
                                ]
                            ))
                    )),
                "stream": .single(
                    FormField(
                        id: "stream",
                        key: "stream",
                        label: "流式",
                        required: false,
                        input: .InputBoolean(
                            BooleanInput(
                                id: "stream",
                                defaultValue: false
                            ))
                    )),
            ],
            orders: ["voiceType", "language", "volume", "speed", "codec", "stream"]
        )
    ),
]
