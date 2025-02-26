import Foundation

let role6 = RoleBiz(
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