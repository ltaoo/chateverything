import QCloudRealTTS
import SwiftUI

struct GeneralSettingsPage: View {
    var config: Config

    init(config: Config) {
        self.config = config
    }

    var body: some View {
        VStack {
            List {
                GeneralLLMProviderSettingView(config: self.config)
                GeneralTTSProviderSettingView(config: self.config)
            }
            .listStyle(InsetGroupedListStyle())
        }
        .background(DesignSystem.Colors.background)
    }
}

struct GeneralTTSProviderSettingView: View {
    let config: Config

    // let controller = TTSProviderController

    @State var selectedProviderController: TTSProviderController?
    @State var count = 0
    private let debouncer = Debouncer(delay: 0.8)

    init(config: Config) {
        self.config = config

        if let v = config.ttsConfig["provider"] {
            if v is String {
                let controller = config.ttsProviderControllers.first {
                    $0.provider.id == v as! String
                }
                _selectedProviderController = State(initialValue: controller)
                if let controller = controller {
                    let schema = controller.provider.schema
                    schema.setValue(value: config.ttsConfig)
                    print("[VIEW]RoleTTSProviderSettingView init schema \(schema)")
                }
            }
        }
    }

    var enabledTTSProviders: [TTSProviderController] {
        config.ttsProviderControllers.filter { $0.value.enabled }
    }
    var selectedProvider: TTSProvider? {
        config.ttsProviders.first { $0.id == selectedProviderController?.id }
    }

    func handleChange() {
        debouncer.debounce {
            guard let provider = selectedProvider else {
                print("[VIEW]RoleTTSProviderSettingView handleChange provider is nil")
                return
            }
            let r = provider.schema.validate()
            if r.isValid == false {
                return
            }
            var v = r.value as! [String: Any]
            v["provider"] = selectedProviderController?.provider.id
            print("[VIEW]RoleTTSProviderSettingView handleChange \(v)")
            config.updateTTSConfig(value: v)
            self.count += 1
        }
    }

    var body: some View {
        Section(
            header: Text("语音设置")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        ) {
            Picker("语音引擎", selection: $selectedProviderController) {
                ForEach(enabledTTSProviders, id: \.id) { provider in
                    Text(provider.name)
                        .font(DesignSystem.Typography.bodyMedium)
                        .tag(provider)
                }
            }
            .onChange(of: selectedProviderController) { controller in
                // print("[VIEW]RoleTTSProviderSettingView selectedProviderController is changed \(controller)")
                self.handleChange()
            }
            if let provider = selectedProvider {
                form
            }
            if let provider = selectedProvider {
                GeneralVoiceTestButton(
                    controller: selectedProviderController!, provider: provider, config: config)
            }
        }
    }

    @ViewBuilder
    private var form: some View {
        if let schema = selectedProvider?.schema {
            ForEach(schema.orders, id: \.self) { key in
                if let field = schema.fields[key] {
                    switch field {
                    case .single(let formField):
                        switch formField.input {
                        case .InputString(let input):
                            TextField(
                                formField.label,
                                text: Binding(
                                    get: { input.value as? String ?? "" },
                                    set: { newValue in
                                        input.setValue(value: newValue)
                                        self.handleChange()
                                    }
                                )
                            )
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.vertical, 4)

                        case .InputNumber(let input):
                            TextField(
                                formField.label,
                                text: Binding(
                                    get: { String(input.value ?? 0) },
                                    set: { newValue in
                                        print("[VIEW]InputNumber \(formField.label) \(newValue)")
                                        input.setValue(value: Double(newValue))
                                        self.handleChange()
                                    }
                                )
                            )
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.vertical, 4)

                        case .InputBoolean(let input):
                            Toggle(
                                formField.label,
                                isOn: Binding(
                                    get: { input.value ?? false },
                                    set: { newValue in
                                        print("[VIEW]formField \(formField.label) \(newValue)")
                                        input.setValue(value: newValue)
                                        self.handleChange()
                                    }
                                ))

                        case .InputSelect(let input):
                            ObservablePicker(
                                field: formField,
                                onChange: { newValue in
                                    print("[VIEW]formField \(formField.label) \(newValue)")
                                    self.handleChange()
                                })

                        case .InputMultiSelect(let input):
                            // MultiSelect 需要特殊处理，这里暂时用普通的 Picker
                            Text("multi select")
                        // Picker(formField.label, selection: Binding(
                        //     get: { input.value?.first ?? "" },
                        //     set: { newValue in
                        //         input.setValue(value: [newValue])
                        //         self.handleChange()
                        //     }
                        // )) {
                        //     ForEach(input.options) { option in
                        //         Text(option.label).tag(option.value)
                        //     }
                        // }

                        case .InputSlider(let input):
                            VStack(alignment: .leading) {
                                Text(formField.label)
                                ObservableSlider(
                                    field: formField,
                                    onChange: { newValue in
                                        print("[VIEW]formField \(formField.label) \(newValue)")
                                        self.handleChange()
                                    })
                            }
                        }

                    case .array(_):
                        EmptyView()
                    case .object(_):
                        EmptyView()
                    }
                }
            }
        }
    }
}

struct GeneralVoiceTestButton: View {
    let controller: TTSProviderController
    let provider: TTSProvider
    let config: Config
    @State var tts: TTSEngine?
    @State var player: PCMStreamPlayer?
    @State private var isLoading = false
    @State private var statusMessage = ""
    @State private var isError = false

    private func testVoice() async {
        isLoading = true
        statusMessage = "正在初始化语音引擎..."
        isError = false

        let text1 = "Hello! The weather is beautiful today. Would you like to go for a walk?"
        let text2 = "你好！今天天气真好。要不要一起去散步？"
        let text3 = "こんにちは！今日は天気が良いですね。一緒に散歩しませんか？"

        let r = provider.schema.validate()
        let lang = r.value["language"] as? String ?? "en-US"
        let text = {
            switch lang {
            case "en-US": return text1
            case "zh-CN": return text2
            case "jp-JP": return text3
            default: return text2
            }
        }()
        tts = {
            switch provider.id {
            case "tencent": return TencentTTSEngine()
            case "system": return SystemTTSEngine()
            default: return SystemTTSEngine()
            }
        }()
        let events = TTSCallback(
            onStart: {
                statusMessage = "正在生成语音..."
            },
            onData: { data in
                statusMessage = "正在生成语音... \(data.count) bytes"
            },
            onComplete: {
                statusMessage = "语音测试完成"
                isLoading = false
            },
            onCancel: {
                statusMessage = "语音测试取消"
            },
            onError: { error in
                statusMessage = "语音测试失败: \(error.localizedDescription)"
                isLoading = false
            })
        tts!.setEvents(callback: events)
        let credential = controller.value.credential
        var config = self.config.ttsConfig
        for (key, value) in credential {
            config[key] = value
        }
        tts!.setConfig(config: config)
        tts!.speak(text)

        isError = false
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Button(action: {
                Task {
                    await testVoice()
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 8)
                    }
                    Text(isLoading ? "生成语音中..." : "测试语音")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.xSmall)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignSystem.Colors.primary)
            )
            .disabled(isLoading)

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(
                        isError ? DesignSystem.Colors.error : DesignSystem.Colors.textSecondary
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 4)
            }
        }
        .onDisappear {
            tts?.stop()
        }
    }
}

struct GeneralLLMProviderSettingView: View {
    let config: Config
    @State var selectedProviderController: LLMProviderController?
    private let debouncer = Debouncer(delay: 0.8)
    @State var count: Int = 0

    init(config: Config) {
        self.config = config

        if let providerId = config.llmConfig["provider"] as? String {
            _selectedProviderController = State(
                initialValue: config.llmProviderControllers.first { $0.provider.id == providerId })
        }
    }

    var enabledProvidersControllers: [LLMProviderController] {
        config.llmProviderControllers.filter { $0.value.enabled } as [LLMProviderController]
    }
    var selectedProvider: LLMProvider? {
        config.llmProviders.first { $0.id == selectedProviderController?.id }
    }

    func handleChange(controller: LLMProviderController, model: LLMProviderModelController) {
        let v = ["provider": controller.provider.id, "model": model.id] as [String: Any]
        print("[VIEW]RoleLLMProviderSettingView handleChange \(v)")
        config.updateLLMConfig(value: v)
    }
    var body: some View {
        Section(
            header: Text("语言模型")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        ) {
            ForEach(enabledProvidersControllers, id: \.id) { (controller: LLMProviderController) in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(controller.provider.logo_uri)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                        Text(controller.provider.name)
                            .font(DesignSystem.Typography.bodyLarge)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    .padding(.bottom, 4)

                    GeneralModelListView(
                        config: config, controller: controller,
                        onTap: { model in
                            self.handleChange(controller: controller, model: model)
                        })
                }
            }
        }
    }
}

struct GeneralModelListView: View {
    @ObservedObject var config: Config
    let controller: LLMProviderController
    let onTap: (LLMProviderModelController) -> Void

    @State var count = 0

    var models: [LLMProviderModelController] {
        return controller.models.filter { $0.enabled }
    }

    var body: some View {
        ForEach(models, id: \.id) { (sub: LLMProviderModelController) in
            let m: LLMProviderModelController = sub
            let provider = config.llmConfig["provider"] as? String
            let model = config.llmConfig["model"] as? String
            let isSelected: Bool = provider == controller.provider.id && model == m.id
            HStack {
                Text(sub.id)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected
                            ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryBackground)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                onTap(sub)
                self.count += 1
            }
        }
    }
}
