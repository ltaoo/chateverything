import Foundation

// 场景分类
enum SceneCategory: String, CaseIterable {
    case daily = "日常生活"
    case business = "商务职场"
    case travel = "旅游出行"
    case study = "学习教育"
}

// 场景数据结构
struct LearningScenario: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let talker: RoleBiz
    let category: SceneCategory
    let tags: [String]
    let background: String?
    let example: [[String: String]]
    let keywords: [[String: String]]
}

// 场景数据
let scenarios: [LearningScenario] = [
    // 日常生活场景
    LearningScenario(
        title: "Dining in the Restaurant",
        description:
            "这段对话主要围绕顾客在餐厅用餐的过程展开。服务员迎接无预订的顾客，安排靠窗座位并递上菜单。顾客请服务员推荐特色菜，点了一份三分熟牛排，顾客本人要了一杯红酒，同伴要了一杯柠檬水。服务员告知稍等，随后上菜。顾客用餐结束后要账单，得知总价 55 美元后付账并让服务员留零钱，服务员致谢并祝顾客晚安。",
        talker: RoleBiz(
            props: {
                var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-300000000001")!)
                props.name = "服务员"
                props.avatar = "avatar1"
                props.prompt = "你扮演「服务员」"
                props.type = "scene"
                return props
            }()),
        category: .daily,
        tags: ["en-US", "A2", "5min"],
        background: nil,
        example: [
            [
                "role": "服务员", "isMe": "false",
                "content": "Good evening! Welcome to our restaurant. Do you have a reservation?",
            ],
            [
                "role": "顾客", "isMe": "true",
                "content": "Good evening! No, we don't. Do you have any available tables?",
            ],
            [
                "role": "服务员", "isMe": "false",
                "content":
                    "Sure, follow me. This table by the window is available. Here's the menu.",
            ],
            [
                "role": "顾客", "isMe": "true",
                "content": "Thank you. Can you recommend some specialties?",
            ],
            [
                "role": "服务员", "isMe": "false",
                "content":
                    "Sure. Our steak and seafood pasta are very popular. Which one would you prefer?",
            ],
            [
                "role": "顾客", "isMe": "true",
                "content": "I'd like the steak. Medium - rare, please.",
            ],
            [
                "role": "服务员", "isMe": "false",
                "content":
                    "Very well. And would you like something to drink? We have excellent red wine.",
            ],
            [
                "role": "顾客", "isMe": "true",
                "content": "Yes, a glass of red wine for me. What about you, honey?",
            ],
            ["role": "顾客同伴", "isMe": "false", "content": "I'll have a glass of lemonade."],
            [
                "role": "服务员", "isMe": "false",
                "content": "OK. Please wait a moment. Your food and drinks will be ready soon.",
            ],
            [
                "role": "服务员", "isMe": "false",
                "content":
                    "(After a while) Here's your steak and red wine, and your lemonade. Enjoy your meal!",
            ],
            ["role": "顾客", "isMe": "true", "content": "Thank you. It all looks delicious."],
            [
                "role": "顾客", "isMe": "true",
                "content": "(After finishing the meal) Waiter, can I have the bill, please?",
            ],
            ["role": "服务员", "isMe": "false", "content": "Sure. Here it is. The total is $55."],
            ["role": "顾客", "isMe": "true", "content": "Here you are. Keep the change."],
            ["role": "服务员", "isMe": "false", "content": "Thank you very much. Have a nice night!"],
        ],
        keywords: [
            ["v": "reservation", "t": "预订"],
            ["v": "available tables", "t": "空桌"],
            ["v": "menu", "t": "菜单"],
            ["v": "specialties", "t": "特色菜"],
            ["v": "steak", "t": "牛排"],
            ["v": "seafood pasta", "t": "海鲜意面"],
            ["v": "medium - rare", "t": "五分熟"],
            ["v": "drink", "t": "饮料"],
            ["v": "red wine", "t": "红酒"],
        ]
    ),
    LearningScenario(
        title: "Conversation about Shopping",
        description:
            "“我”询问朋友一天过得如何，朋友表示过得不错且刚购物完。“我”好奇其所购物品，朋友称买了水果和一件新T恤。“我”提到水果有益健康并询问种类，得知是苹果和香蕉，还表示这也是自己的最爱，又询问T恤如何，朋友形容T恤很酷，是蓝色且带有有趣图案。",
        talker: RoleBiz(
            props: {
                var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-300000000002")!)
                props.name = "朋友"
                props.avatar = "avatar1"
                props.prompt = "你扮演「朋友」"
                props.type = "scene"
                return props
            }()),
        category: .daily,
        tags: ["en-US", "A2", "2min"],
        background: nil,
        example: [
            ["role": "Me", "isMe": "true", "content": "Hi! How's your day going?"],
            [
                "role": "Friend", "isMe": "false",
                "content": "It's going pretty well. I just finished shopping.",
            ],
            ["role": "Me", "isMe": "true", "content": "That sounds fun. What did you buy?"],
            [
                "role": "Friend", "isMe": "false",
                "content": "I bought some fruits and a new T - shirt.",
            ],
            [
                "role": "Me", "isMe": "true",
                "content": "Fruits are healthy. What kind of fruits did you get?",
            ],
            ["role": "Friend", "isMe": "false", "content": "I got some apples and bananas."],
            [
                "role": "Me", "isMe": "true",
                "content": "Nice! Apples and bananas are my favorites too. How's the T - shirt?",
            ],
            [
                "role": "Friend", "isMe": "false",
                "content": "It's really cool. It's blue and has a funny picture on it.",
            ],
        ],
        keywords: [
            ["v": "shopping", "t": "购物"],
            ["v": "fruits", "t": "水果"],
            ["v": "T - shirt", "t": "T恤"],
            ["v": "picture", "t": "图片"],
        ]
    ),
    LearningScenario(
        title: "At the Restaurant: Ordering a Meal",
        description:
            "该对话主要围绕顾客在餐厅点餐的过程展开。顾客首先点了蘑菇汤作为开胃菜，接着选择了三分熟的烤牛排搭配烤蔬菜作为主菜，还点了一杯赤霞珠红葡萄酒来搭配食物，最后决定要一份巧克力慕斯作为甜点。服务员表示会尽快准备好餐点，并祝顾客用餐愉快。",
        talker: RoleBiz(
            props: {
                var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-300000000003")!)
                props.name = "服务员"
                props.avatar = "avatar1"
                props.prompt = "你扮演「服务员」"
                props.type = "scene"
                return props
            }()),
        category: .daily,
        tags: ["en-US", "C1", "3min"],
        background: "background1",
        example: [
            [
                "role": "Waiter", "isMe": "false",
                "content": "Good evening! Welcome to our restaurant. Are you ready to order?",
            ],
            [
                "role": "Customer", "isMe": "true",
                "content": "Yes, I'd like to start with a bowl of mushroom soup as an appetizer.",
            ],
            ["role": "Waiter", "isMe": "false", "content": "Certainly. And for your main course?"],
            [
                "role": "Customer", "isMe": "true",
                "content":
                    "I'll have the grilled steak, medium - rare. Could you also serve it with a side of roasted vegetables?",
            ],
            [
                "role": "Waiter", "isMe": "false",
                "content": "No problem. Would you like something to drink?",
            ],
            [
                "role": "Customer", "isMe": "true",
                "content":
                    "A glass of red wine to accompany my meal, please. A Cabernet Sauvignon would be great.",
            ],
            [
                "role": "Waiter", "isMe": "false",
                "content":
                    "Excellent choice. We have a very good Cabernet Sauvignon from our cellar. Is there anything else?",
            ],
            [
                "role": "Customer", "isMe": "true",
                "content":
                    "For dessert, I think I'll go for the chocolate mousse. I have a sweet tooth.",
            ],
            [
                "role": "Waiter", "isMe": "false",
                "content": "That sounds delicious. Your order will be ready soon. Enjoy your meal!",
            ],
        ],
        keywords: [
            ["v": "appetizer", "t": "开胃菜"],
            ["v": "mushroom soup", "t": "蘑菇汤"],
            ["v": "grilled steak", "t": "烤牛排"],
            ["v": "medium - rare", "t": "三分熟"],
            ["v": "roasted vegetables", "t": "烤蔬菜"],
            ["v": "accompany", "t": "搭配；陪伴"],
            ["v": "Cabernet Sauvignon", "t": "赤霞珠（一种红葡萄酒）"],
            ["v": "cellar", "t": "酒窖"],
            ["v": "dessert", "t": "甜点"],
            ["v": "chocolate mousse", "t": "巧克力慕斯"],
            ["v": "sweet tooth", "t": "爱吃甜食的人"],
        ]
    ),
    LearningScenario(
        title: "Ordering Coffee in a Coffee Shop",
        description: "顾客在咖啡店点咖啡，店员介绍咖啡种类和规格，顾客选择了中杯加了糖的卡布奇诺，付款后等待并拿到咖啡，整个过程交流愉快。",
        talker: RoleBiz(
            props: {
                var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-300000000004")!)
                props.name = "店员"
                props.avatar = "avatar1"
                props.prompt = "你扮演「店员」"
                props.type = "scene"
                return props
            }()),
        category: .daily,
        tags: ["en-US", "A1", "5min"],
        background: nil,
        example: [
            ["role": "店员", "isMe": "false", "content": "Hello! Welcome to our coffee shop."],
            ["role": "顾客", "isMe": "true", "content": "Hello! I'd like some coffee."],
            [
                "role": "店员", "isMe": "false",
                "content": "Sure. We have different kinds of coffee. Do you like black coffee?",
            ],
            [
                "role": "顾客", "isMe": "true",
                "content": "No, I don't like black coffee. It's too bitter.",
            ],
            ["role": "店员", "isMe": "false", "content": "How about cappuccino? It has milk in it."],
            ["role": "顾客", "isMe": "true", "content": "Cappuccino? Sounds good. I like milk."],
            [
                "role": "店员", "isMe": "false",
                "content": "Great! Do you want a small, medium or large cappuccino?",
            ],
            ["role": "顾客", "isMe": "true", "content": "I want a medium one."],
            ["role": "店员", "isMe": "false", "content": "Okay. Do you need any sugar or cream?"],
            ["role": "顾客", "isMe": "true", "content": "Yes, please. I like a little sugar."],
            [
                "role": "店员", "isMe": "false",
                "content": "Sure. Anything else? We also have some delicious cakes.",
            ],
            ["role": "顾客", "isMe": "true", "content": "No, thank you. Just the coffee."],
            [
                "role": "店员", "isMe": "false",
                "content": "Alright. The medium cappuccino with sugar is $3.5.",
            ],
            ["role": "顾客", "isMe": "true", "content": "Here is the money."],
            [
                "role": "店员", "isMe": "false",
                "content": "Thank you. Please wait a moment. Your coffee will be ready soon.",
            ],
            ["role": "顾客", "isMe": "true", "content": "Okay. I can wait."],
            ["role": "店员", "isMe": "false", "content": "Here is your cappuccino. Enjoy it!"],
            ["role": "顾客", "isMe": "true", "content": "Thank you. It looks nice."],
            [
                "role": "店员", "isMe": "false",
                "content": "If you need anything else, just let me know.",
            ],
            ["role": "顾客", "isMe": "true", "content": "Sure. Have a good day!"],
        ],
        keywords: [
            ["v": "coffee", "t": "咖啡"],
            ["v": "black coffee", "t": "黑咖啡"],
            ["v": "cappuccino", "t": "卡布奇诺"],
            ["v": "bitter", "t": "苦的"],
            ["v": "milk", "t": "牛奶"],
            ["v": "small", "t": "小的"],
            ["v": "medium", "t": "中等的"],
            ["v": "large", "t": "大的"],
            ["v": "sugar", "t": "糖"],
            ["v": "cream", "t": "奶油"],
            ["v": "cake", "t": "蛋糕"],
            ["v": "money", "t": "钱"],
        ]
    ),

    // 商务职场场景
    LearningScenario(
        title: "Asking for the Location of a Printer",
        description:
            "新员工向同事询问打印机的位置，同事告知打印机在二楼 203 房间，新员工表示感谢，同事回应不客气。",
        talker: RoleBiz(
            props: {
                var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-300000000005")!)
                props.name = "同事"
                props.avatar = "avatar1"
                props.prompt = "你扮演「同事」"
                props.type = "scene"
                return props
            }()),
        category: .business,
        tags: ["en-US", "C1", "5min"],
        background: nil,
        example: [
            [
                "role": "Manager", "isMe": "false",
                "content": "Hi! Excuse me. Where is the printer?",
            ],
            [
                "role": "Employee", "isMe": "true",
                "content": "Hello! It's on the second floor, Room 203.",
            ],
            ["role": "Manager", "isMe": "false", "content": "Thank you very much."],
            ["role": "Employee", "isMe": "true", "content": "You're welcome."],
        ],
        keywords: [
            ["v": "printer", "t": "打印机"],
            ["v": "second floor", "t": "二楼"],
            ["v": "room", "t": "房间"],
            ["v": "thank you", "t": "谢谢你"],
            ["v": "you're welcome", "t": "不客气"],
        ]),
    LearningScenario(
        title: "New Employee Orientation",
        description:
            "新员工第一天到公司，与同事交流了解公司的基本情况，如办公座位、工作时间、午休时间、食堂位置和着装要求等。之后领导前来与新员工见面，并为其安排了当天的工作任务，包括整理文件和录入数据，要求在下午下班前完成，新员工表示会尽力做好。",
        talker: RoleBiz(
            props: {
                var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-300000000006")!)
                props.name = "同事"
                props.avatar = "avatar1"
                props.prompt = "你扮演「同事」"
                props.type = "scene"
                return props
            }()),
        category: .business,
        tags: ["en-US", "A1", "5min"],
        background: nil,
        example: [
            ["role": "我", "isMe": "true", "content": "Good morning! I'm the new employee."],
            ["role": "同事 A", "isMe": "false", "content": "Good morning! Welcome to our company."],
            ["role": "我", "isMe": "true", "content": "Thank you. Where should I sit?"],
            [
                "role": "同事 A", "isMe": "false",
                "content": "Over there, near the window. That's your desk.",
            ],
            ["role": "我", "isMe": "true", "content": "Great! What time do we start work?"],
            ["role": "同事 A", "isMe": "false", "content": "We start at 9 o'clock."],
            ["role": "我", "isMe": "true", "content": "Got it. And when is the lunch break?"],
            ["role": "同事 A", "isMe": "false", "content": "It's from 12 to 1 pm."],
            ["role": "我", "isMe": "true", "content": "Okay. Is there a cafeteria in the company?"],
            ["role": "同事 A", "isMe": "false", "content": "Yes, it's on the first floor."],
            [
                "role": "我", "isMe": "true",
                "content": "That's convenient. What about the dress code?",
            ],
            [
                "role": "同事 A", "isMe": "false",
                "content": "It's business casual. No need to be too formal.",
            ],
            ["role": "我", "isMe": "true", "content": "Understood. When will I meet the boss?"],
            [
                "role": "同事 A", "isMe": "false",
                "content": "The boss will come to see you later. Just wait a bit.",
            ],
            ["role": "领导", "isMe": "false", "content": "Hello! You must be the new staff."],
            ["role": "我", "isMe": "true", "content": "Yes, sir. Nice to meet you."],
            [
                "role": "领导", "isMe": "false",
                "content": "Nice to meet you too. I'll introduce your tasks today.",
            ],
            ["role": "我", "isMe": "true", "content": "Sure, I'm listening."],
            ["role": "领导", "isMe": "false", "content": "First, you need to organize these files."],
            ["role": "我", "isMe": "true", "content": "Okay. How should I organize them?"],
            [
                "role": "领导", "isMe": "false",
                "content": "Sort them by date. Put the newest on the top.",
            ],
            ["role": "我", "isMe": "true", "content": "Understood. Then what?"],
            [
                "role": "领导", "isMe": "false",
                "content": "After that, you'll enter some data into the computer.",
            ],
            ["role": "我", "isMe": "true", "content": "No problem. Where can I find the data?"],
            ["role": "领导", "isMe": "false", "content": "It's on these papers. Just type them in."],
            [
                "role": "我", "isMe": "true",
                "content": "All right. How long do I have to finish these tasks?",
            ],
            [
                "role": "领导", "isMe": "false",
                "content": "You can finish them by the end of this afternoon.",
            ],
            ["role": "我", "isMe": "true", "content": "Okay, I'll try my best."],
            [
                "role": "领导", "isMe": "false",
                "content": "Good. If you have any questions, ask your colleagues.",
            ],
            ["role": "我", "isMe": "true", "content": "Sure. Thank you for your guidance."],
        ],
        keywords: [
            ["v": "new employee", "t": "新员工"],
            ["v": "company", "t": "公司"],
            ["v": "desk", "t": "办公桌"],
            ["v": "start work", "t": "开始工作"],
            ["v": "lunch break", "t": "午休"],
            ["v": "cafeteria", "t": "食堂"],
            ["v": "dress code", "t": "着装要求"],
            ["v": "business casual", "t": "商务休闲装"],
            ["v": "formal", "t": "正式的"],
            ["v": "boss", "t": "老板"],
            ["v": "staff", "t": "员工"],
            ["v": "task", "t": "任务"],
            ["v": "organize", "t": "整理"],
            ["v": "file", "t": "文件"],
            ["v": "sort", "t": "分类"],
            ["v": "date", "t": "日期"],
            ["v": "newest", "t": "最新的"],
            ["v": "data", "t": "数据"],
            ["v": "computer", "t": "电脑"],
            ["v": "type in", "t": "输入"],
            ["v": "finish", "t": "完成"],
            ["v": "afternoon", "t": "下午"],
            ["v": "try one's best", "t": "尽力"],
            ["v": "guidance", "t": "指导"],
        ]
    ),
    LearningScenario(
        title: "Business Meeting to Address Declining Sales",
        description:
            "此商务职场场景对话围绕公司季度销售数据下降展开。经理提出需要集思广益制定创新策略来扭转这一趋势，员工分析市场动态，提出针对性营销活动、与供应商合作及精简内部流程等建议。经理认可方向并要求员工起草包含时间表和职责分配的详细行动计划，员工表示会立即着手并提议定期召开进度会议以监控实施情况并适时调整，双方强调有效沟通与协调的重要性，确保团队成员支持这些举措。",
        talker: RoleBiz(
            props: {
                var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-300000000007")!)
                props.name = "经理"
                props.avatar = "avatar1"
                props.prompt = "你扮演「经理」"
                props.type = "scene"
                return props
            }()),
        category: .business,
        tags: ["en-US", "C1", "5min"],
        background: nil,
        example: [
            [
                "role": "Manager", "isMe": "false",
                "content":
                    "We've been observing a dip in our quarterly sales figures. We need to brainstorm some innovative strategies to reverse this trend.",
            ],
            [
                "role": "Employee", "isMe": "true",
                "content":
                    "I've been analyzing the market dynamics. Our competitors have introduced some aggressive pricing models. Perhaps we could consider a targeted marketing campaign to highlight our unique value proposition.",
            ],
            [
                "role": "Manager", "isMe": "false",
                "content":
                    "That's a valid point. But we also need to ensure that our product remains cost - effective without compromising on quality. How do you suggest we balance these two aspects?",
            ],
            [
                "role": "Employee", "isMe": "true",
                "content":
                    "We could explore partnerships with suppliers to negotiate better deals. Also, streamline our internal processes to cut down on inefficiencies. This way, we can reduce costs while maintaining the high - end quality our customers expect.",
            ],
            [
                "role": "Manager", "isMe": "false",
                "content":
                    "I like the direction you're taking. However, we need to implement these changes in a timely manner. Can you draft a detailed action plan with timelines and assign responsibilities?",
            ],
            [
                "role": "Employee", "isMe": "true",
                "content":
                    "Sure. I'll start working on it right away. We should also set up regular progress meetings to monitor the implementation and make adjustments as needed.",
            ],
            [
                "role": "Manager", "isMe": "false",
                "content":
                    "Agreed. Effective communication and coordination will be key. Let's ensure that everyone on the team is on board with these initiatives.",
            ],
        ],
        keywords: [
            ["v": "dip", "t": "下降；减少"],
            ["v": "quarterly", "t": "季度的"],
            ["v": "brainstorm", "t": "集思广益；头脑风暴"],
            ["v": "innovative", "t": "创新的"],
            ["v": "strategy", "t": "策略；战略"],
            ["v": "reverse", "t": "扭转；反转"],
            ["v": "market dynamics", "t": "市场动态"],
            ["v": "aggressive", "t": "激进的；有进取心的"],
            ["v": "pricing model", "t": "定价模式"],
            ["v": "targeted", "t": "有针对性的"],
            ["v": "marketing campaign", "t": "营销活动"],
            ["v": "unique value proposition", "t": "独特价值主张"],
            ["v": "cost - effective", "t": "性价比高的；划算的"],
            ["v": "compromise", "t": "妥协；让步"],
            ["v": "explore", "t": "探索；探究"],
            ["v": "partnership", "t": "合作伙伴关系"],
            ["v": "negotiate", "t": "谈判；协商"],
            ["v": "streamline", "t": "精简；使效率更高"],
            ["v": "inefficiency", "t": "无效率；低效"],
            ["v": "timely", "t": "及时的"],
            ["v": "draft", "t": "起草；草拟"],
            ["v": "action plan", "t": "行动计划"],
            ["v": "timeline", "t": "时间表；时间线"],
            ["v": "assign", "t": "分配；指派"],
            ["v": "responsibility", "t": "责任；职责"],
            ["v": "progress meeting", "t": "进度会议"],
            ["v": "monitor", "t": "监控；监测"],
            ["v": "implementation", "t": "实施；执行"],
            ["v": "adjustment", "t": "调整"],
            ["v": "coordination", "t": "协调；协作"],
            ["v": "initiative", "t": "倡议；举措"],
        ]
    ),
    LearningScenario(
        title: "Dealing with Last - Minute Project Scope Changes",
        description:
            "该商务职场对话聚焦于客户在最后时刻提出的项目范围变更，要求添加用户分析模块，这会影响项目的时间表和预算。团队成员提出先聚焦核心功能，将新模块的集成作为第二阶段，以满足最初的截止日期。项目负责人认可此方法，但强调要与客户清晰沟通权衡之处，并评估技术可行性。团队成员将准备详细报告并在会议上向客户说明，同时项目负责人提议尽早让技术团队参与提供意见，以做出明智决策并避免潜在挫折。",
        talker: RoleBiz(
            props: {
                var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-300000000008")!)
                props.name = "项目负责人"
                props.avatar = "avatar1"
                props.prompt = "你扮演「项目负责人」"
                props.type = "scene"
                return props
            }()),
        category: .business,
        tags: ["en-US", "C1", "5min"],
        background: nil,
        example: [
            [
                "role": "Project Leader", "isMe": "false",
                "content":
                    "The client has just sent over some last - minute changes to the project scope. They want to add a new module for user analytics. This will inevitably impact our project timeline and budget.",
            ],
            [
                "role": "Team Member", "isMe": "true",
                "content":
                    "That's quite a significant addition. We'll need to conduct a thorough impact analysis. How flexible are we with the current budget and timeline?",
            ],
            [
                "role": "Project Leader", "isMe": "false",
                "content":
                    "The budget has a bit of a buffer, but the timeline is very tight. We're already committed to delivering the project by the end - of - month deadline. We can't afford any major delays.",
            ],
            [
                "role": "Team Member", "isMe": "true",
                "content":
                    "Understood. Maybe we can prioritize tasks more effectively. We could focus on the core features first and then integrate the new module as a secondary phase. This way, we can meet the initial deadline and then work on the analytics module later.",
            ],
            [
                "role": "Project Leader", "isMe": "false",
                "content":
                    "That's a reasonable approach. But we need to communicate this clearly to the client. They need to be aware of the trade - offs involved. We should also assess the technical feasibility of integrating the new module later without causing any compatibility issues.",
            ],
            [
                "role": "Team Member", "isMe": "true",
                "content":
                    "Agreed. I'll prepare a detailed report on the impact analysis, including the proposed phased approach. We can present it to the client in the upcoming meeting and address any concerns they may have.",
            ],
            [
                "role": "Project Leader", "isMe": "false",
                "content":
                    "Great. And we should also involve the technical team early on to get their input on the feasibility. This way, we can make well - informed decisions and avoid any potential setbacks.",
            ],
        ],
        keywords: [
            ["v": "last - minute", "t": "最后时刻的；紧急的"],
            ["v": "project scope", "t": "项目范围"],
            ["v": "module", "t": "模块"],
            ["v": "user analytics", "t": "用户分析"],
            ["v": "inevitably", "t": "不可避免地"],
            ["v": "impact", "t": "影响"],
            ["v": "timeline", "t": "时间表；时间线"],
            ["v": "budget", "t": "预算"],
            ["v": "thorough", "t": "彻底的；全面的"],
            ["v": "impact analysis", "t": "影响分析"],
            ["v": "flexible", "t": "灵活的"],
            ["v": "buffer", "t": "缓冲；余量"],
            ["v": "commit", "t": "承诺；保证"],
            ["v": "deadline", "t": "截止日期"],
            ["v": "prioritize", "t": "优先处理；排序"],
            ["v": "core features", "t": "核心功能"],
            ["v": "integrate", "t": "整合；集成"],
            ["v": "secondary phase", "t": "第二阶段"],
            ["v": "initial", "t": "最初的；开始的"],
            ["v": "trade - off", "t": "权衡；取舍"],
            ["v": "technical feasibility", "t": "技术可行性"],
            ["v": "compatibility issues", "t": "兼容性问题"],
            ["v": "detailed report", "t": "详细报告"],
            ["v": "proposed", "t": "提议的；建议的"],
            ["v": "phased approach", "t": "分阶段方法"],
            ["v": "address", "t": "处理；解决"],
            ["v": "concern", "t": "担忧；关注"],
            ["v": "involve", "t": "涉及；让……参与"],
            ["v": "input", "t": "意见；建议"],
            ["v": "well - informed", "t": "明智的；有见识的"],
            ["v": "potential", "t": "潜在的"],
            ["v": "setback", "t": "挫折；阻碍"],
        ]
    ),

    // 旅游场景
    LearningScenario(
        title: "Asking for Directions",
        description:
            "该对话围绕游客在旅游过程中的交通和餐饮需求展开。游客先询问去博物馆的公交信息，包括乘车路线、票价、耗时和换乘情况；之后又询问附近餐厅的位置、是否提供早餐等信息，路人都给予了详细的解答。",
        talker: RoleBiz(
            props: {
                var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-300000000009")!)
                props.name = "路人"
                props.avatar = "avatar1"
                props.prompt = "你扮演「路人」"
                props.type = "scene"
                return props
            }()),
        category: .travel,
        tags: ["en-US", "A1", "3min"],
        background: nil,
        example: [
            ["role": "游客", "isMe": "true", "content": "Excuse me. Can I go to the museum by bus?"],
            [
                "role": "路人", "isMe": "false",
                "content": "Yes, you can. You can take the No. 5 bus.",
            ],
            ["role": "游客", "isMe": "true", "content": "Where is the bus stop?"],
            ["role": "路人", "isMe": "false", "content": "It's over there, across the street."],
            ["role": "游客", "isMe": "true", "content": "How much is the bus ticket?"],
            ["role": "路人", "isMe": "false", "content": "It's two dollars."],
            [
                "role": "游客", "isMe": "true",
                "content": "How long does it take to get to the museum?",
            ],
            ["role": "路人", "isMe": "false", "content": "About 20 minutes."],
            ["role": "游客", "isMe": "true", "content": "Does the bus go directly to the museum?"],
            [
                "role": "路人", "isMe": "false",
                "content": "No, you need to transfer at the next stop.",
            ],
            ["role": "游客", "isMe": "true", "content": "Which bus should I transfer to?"],
            ["role": "路人", "isMe": "false", "content": "You should transfer to the No. 10 bus."],
            ["role": "游客", "isMe": "true", "content": "Thank you very much."],
            ["role": "路人", "isMe": "false", "content": "You're welcome."],
            [
                "role": "游客", "isMe": "true",
                "content": "Excuse me. Is there a restaurant near here?",
            ],
            [
                "role": "路人", "isMe": "false",
                "content": "Yes, there is a pizza restaurant around the corner.",
            ],
            ["role": "游客", "isMe": "true", "content": "How far is it?"],
            ["role": "路人", "isMe": "false", "content": "It's about 5 minutes' walk."],
            ["role": "游客", "isMe": "true", "content": "Do they serve breakfast?"],
            [
                "role": "路人", "isMe": "false",
                "content": "Yes, they do. They have very good coffee, too.",
            ],
            [
                "role": "游客", "isMe": "true",
                "content": "Great! I want to go there. How can I get there?",
            ],
            [
                "role": "路人", "isMe": "false",
                "content": "Just go straight and turn left at the first crossing.",
            ],
            ["role": "游客", "isMe": "true", "content": "Thank you for your help."],
            ["role": "路人", "isMe": "false", "content": "Have a nice day!"],
        ],
        keywords: [
            ["v": "museum", "t": "博物馆"],
            ["v": "bus", "t": "公交车"],
            ["v": "bus stop", "t": "公交车站"],
            ["v": "ticket", "t": "车票"],
            ["v": "transfer", "t": "换乘"],
            ["v": "restaurant", "t": "餐厅"],
            ["v": "pizza", "t": "披萨"],
            ["v": "breakfast", "t": "早餐"],
            ["v": "coffee", "t": "咖啡"],
        ]
    ),
    LearningScenario(
        title: "Hotel Check-in",
        description:
            "该对话是游客在酒店前台办理入住的场景。游客表明有预订，前台核实信息并告知费用及支付方式，游客选择信用卡支付。之后游客询问电梯位置、酒店是否有游泳池及开放时间、是否需额外付费，还询问了酒店餐厅及早餐时间，前台都一一作答。",
        talker: RoleBiz(
            props: {
                var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-300000000010")!)
                props.name = "前台"
                props.avatar = "avatar1"
                props.prompt = "你扮演「前台」"
                props.type = "scene"
                return props
            }()),
        category: .travel,
        tags: ["en-US", "A1", "3min"],
        background: nil,
        example: [
            ["role": "游客", "isMe": "true", "content": "Hello. I have a reservation."],
            ["role": "酒店前台", "isMe": "false", "content": "May I have your name, please?"],
            ["role": "游客", "isMe": "true", "content": "My name is Tom Smith."],
            [
                "role": "酒店前台", "isMe": "false",
                "content": "Let me check. Yes, here it is. A single room for three nights.",
            ],
            ["role": "游客", "isMe": "true", "content": "That's right. How much do I need to pay?"],
            [
                "role": "酒店前台", "isMe": "false",
                "content": "The total cost is $300. You can pay by credit card or cash.",
            ],
            ["role": "游客", "isMe": "true", "content": "I'll pay by credit card."],
            ["role": "酒店前台", "isMe": "false", "content": "OK. Please swipe your card here."],
            ["role": "游客", "isMe": "true", "content": "Here you are."],
            [
                "role": "酒店前台", "isMe": "false",
                "content": "Thank you. Here's your receipt. Your room number is 305.",
            ],
            ["role": "游客", "isMe": "true", "content": "Where can I find the elevator?"],
            [
                "role": "酒店前台", "isMe": "false",
                "content": "It's just around the corner on your right.",
            ],
            ["role": "游客", "isMe": "true", "content": "Is there a swimming pool in the hotel?"],
            [
                "role": "酒店前台", "isMe": "false",
                "content": "Yes, there is. It's on the fifth floor.",
            ],
            ["role": "游客", "isMe": "true", "content": "When is it open?"],
            ["role": "酒店前台", "isMe": "false", "content": "It opens from 7:00 am to 9:00 pm."],
            [
                "role": "游客", "isMe": "true",
                "content": "Do I need to pay extra for using the swimming pool?",
            ],
            ["role": "酒店前台", "isMe": "false", "content": "No, it's free for hotel guests."],
            [
                "role": "游客", "isMe": "true",
                "content": "Great! Is there a restaurant in the hotel?",
            ],
            [
                "role": "酒店前台", "isMe": "false",
                "content": "Yes, there is a buffet restaurant on the second floor.",
            ],
            ["role": "游客", "isMe": "true", "content": "What time does it serve breakfast?"],
            ["role": "酒店前台", "isMe": "false", "content": "From 6:30 am to 9:30 am."],
            ["role": "游客", "isMe": "true", "content": "Thank you for all the information."],
            ["role": "酒店前台", "isMe": "false", "content": "You're welcome. Enjoy your stay!"],
        ],
        keywords: [
            ["v": "reservation", "t": "预订"],
            ["v": "single room", "t": "单人间"],
            ["v": "credit card", "t": "信用卡"],
            ["v": "cash", "t": "现金"],
            ["v": "receipt", "t": "收据"],
            ["v": "room number", "t": "房间号"],
            ["v": "elevator", "t": "电梯"],
            ["v": "swimming pool", "t": "游泳池"],
            ["v": "open", "t": "开放"],
            ["v": "extra", "t": "额外的"],
            ["v": "free", "t": "免费的"],
            ["v": "buffet restaurant", "t": "自助餐厅"],
            ["v": "breakfast", "t": "早餐"],
        ]
    ),
    // 学习场景
    LearningScenario(
        title: "On the Way to Math Class",
        description: "这段对话主要围绕两个朋友在去上数学课的路上展开交流，包括询问彼此状态、确认课程安排、寻找教室、讨论是否需要计算器以及对数学老师的评价等内容。",
        talker: RoleBiz(
            props: {
                var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-300000000011")!)
                props.name = "朋友"
                props.avatar = "avatar1"
                props.prompt = "你扮演「朋友」"
                props.type = "scene"
                return props
            }()),
        category: .study,
        tags: ["en-US", "A1", "3min"],
        background: nil,
        example: [
            ["role": "Me", "isMe": "true", "content": "Hi! How are you today?"],
            ["role": "Friend", "isMe": "false", "content": "I'm fine, thank you. And you?"],
            [
                "role": "Me", "isMe": "true",
                "content": "I'm good too. Are you ready for the class?",
            ],
            ["role": "Friend", "isMe": "false", "content": "Yes, I am. I have my books."],
            ["role": "Me", "isMe": "true", "content": "Great! What class is first?"],
            ["role": "Friend", "isMe": "false", "content": "It's math class."],
            ["role": "Me", "isMe": "true", "content": "Oh, I like math. Do you like it?"],
            ["role": "Friend", "isMe": "false", "content": "Yes, I do. It's interesting."],
            ["role": "Me", "isMe": "true", "content": "Where is the math classroom?"],
            ["role": "Friend", "isMe": "false", "content": "It's on the second floor, Room 201."],
            ["role": "Me", "isMe": "true", "content": "Ok, let's go. Do we need a calculator?"],
            ["role": "Friend", "isMe": "false", "content": "Yes, we do. I have one."],
            ["role": "Me", "isMe": "true", "content": "That's good. I forgot mine."],
            ["role": "Friend", "isMe": "false", "content": "Don't worry. You can use mine."],
            ["role": "Me", "isMe": "true", "content": "Thank you so much. You're so kind."],
            [
                "role": "Friend", "isMe": "false",
                "content": "You're welcome. Here we are at the classroom.",
            ],
            ["role": "Me", "isMe": "true", "content": "Let's go in. Who is our math teacher?"],
            ["role": "Friend", "isMe": "false", "content": "Mr. Smith. He is very nice."],
            ["role": "Me", "isMe": "true", "content": "I heard about him. Is he strict?"],
            ["role": "Friend", "isMe": "false", "content": "No, he isn't. He is very patient."],
            [
                "role": "Me", "isMe": "true",
                "content": "That's great. I'm looking forward to his class.",
            ],
            ["role": "Friend", "isMe": "false", "content": "Me too. Let's sit down."],
        ],
        keywords: [
            ["v": "fine", "t": "好的"],
            ["v": "ready", "t": "准备好的"],
            ["v": "class", "t": "课程"],
            ["v": "books", "t": "书"],
            ["v": "math", "t": "数学"],
            ["v": "interesting", "t": "有趣的"],
            ["v": "classroom", "t": "教室"],
            ["v": "second", "t": "第二"],
            ["v": "floor", "t": "楼层"],
            ["v": "calculator", "t": "计算器"],
            ["v": "forgot", "t": "忘记"],
            ["v": "kind", "t": "善良的"],
            ["v": "welcome", "t": "受欢迎的"],
            ["v": "teacher", "t": "老师"],
            ["v": "nice", "t": "友好的"],
            ["v": "strict", "t": "严格的"],
            ["v": "patient", "t": "有耐心的"],
            ["v": "looking forward to", "t": "期待"],
        ]
    ),
    LearningScenario(
        title: "Preparing for the Science Class",
        description: "对话是两个同学之间的交流，先聊了周末的情况，接着讨论当天下午的科学课，包括上课地点、老师、学习内容、实验安排等，还涉及到借用放大镜的事情。",
        talker: RoleBiz(
            props: {
                var props = RoleProps(id: UUID(uuidString: "00000000-0000-0000-0000-300000000012")!)
                props.name = "同学"
                props.avatar = "avatar1"
                props.prompt = "你扮演「同学」"
                props.type = "scene"
                return props
            }()),
        category: .study,
        tags: ["en-US", "A1", "3min"],
        background: nil,
        example: [
            ["role": "Me", "isMe": "true", "content": "Hello! How was your weekend?"],
            [
                "role": "Classmate", "isMe": "false",
                "content": "It was great! I watched a movie. How about you?",
            ],
            [
                "role": "Me", "isMe": "true",
                "content": "I studied at home. Are we having a science class today?",
            ],
            [
                "role": "Classmate", "isMe": "false",
                "content": "Yes, we are. It's in the afternoon.",
            ],
            [
                "role": "Me", "isMe": "true",
                "content": "Do we need to bring anything for the science class?",
            ],
            [
                "role": "Classmate", "isMe": "false",
                "content": "I think we need to bring our notebooks.",
            ],
            ["role": "Me", "isMe": "true", "content": "Okay. Where is the science lab?"],
            ["role": "Classmate", "isMe": "false", "content": "It's next to the art room."],
            ["role": "Me", "isMe": "true", "content": "Got it. Who is the science teacher?"],
            ["role": "Classmate", "isMe": "false", "content": "Ms. Brown. She's very friendly."],
            [
                "role": "Me", "isMe": "true",
                "content": "I hope I can understand her well. Is her class difficult?",
            ],
            [
                "role": "Classmate", "isMe": "false",
                "content": "Not really. She explains things clearly.",
            ],
            [
                "role": "Me", "isMe": "true",
                "content": "That's good. What are we going to learn in the science class?",
            ],
            ["role": "Classmate", "isMe": "false", "content": "I heard we'll learn about plants."],
            [
                "role": "Me", "isMe": "true",
                "content": "Plants? That sounds interesting. Do we need to do experiments?",
            ],
            [
                "role": "Classmate", "isMe": "false",
                "content": "Yes, we do. We'll observe plant growth.",
            ],
            [
                "role": "Me", "isMe": "true",
                "content": "Wow, I'm excited. Do we need any tools for the experiment?",
            ],
            ["role": "Classmate", "isMe": "false", "content": "Maybe some magnifying glasses."],
            [
                "role": "Me", "isMe": "true",
                "content": "I don't have a magnifying glass. Can I borrow yours?",
            ],
            ["role": "Classmate", "isMe": "false", "content": "Sure! No problem."],
            ["role": "Me", "isMe": "true", "content": "Thank you so much. You're a big help."],
            [
                "role": "Classmate", "isMe": "false",
                "content": "You're welcome. See you in the science class.",
            ],
        ],
        keywords: [
            ["v": "weekend", "t": "周末"],
            ["v": "science", "t": "科学"],
            ["v": "notebook", "t": "笔记本"],
            ["v": "lab", "t": "实验室"],
            ["v": "art room", "t": "美术室"],
            ["v": "friendly", "t": "友好的"],
            ["v": "explain", "t": "解释"],
            ["v": "clearly", "t": "清楚地"],
            ["v": "plants", "t": "植物"],
            ["v": "experiment", "t": "实验"],
            ["v": "observe", "t": "观察"],
            ["v": "growth", "t": "生长"],
            ["v": "tool", "t": "工具"],
            ["v": "magnifying glass", "t": "放大镜"],
            ["v": "borrow", "t": "借"],
        ]
    ),
]
