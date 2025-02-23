import SwiftUI

// 配置项的值类型枚举
enum FormInputType: Codable {
    case string(StringInput)           // 字符串类型
    case number(NumberInput)          // 数值类型
    case boolean(BooleanInput)        // 布尔类型
    case select(SelectInput)          // 单选类型
    case multiSelect(MultiSelectInput) // 多选类型
    case slider(SliderInput)          // 滑块类型(数值范围)
    
    // 添加编码和解码的实现
    private enum CodingKeys: String, CodingKey {
        case type, value
    }
}

// 使用协议而不是类
protocol FormInputProtocol: Codable, ObservableObject {
    associatedtype ValueType: Codable
    var value: ValueType { get set }
}

// 基础输入类
class FormInput<T: Codable>: ObservableObject {
    let id: String
    @Published var placeholder: String?
    @Published var disabled: Bool = false
    @Published var defaultValue: T?
    @Published var value: T?
    var onChange: ((T?) -> Void)?
    
    init(
        id: String,
        placeholder: String? = nil,
	disabled: Bool = false,
        defaultValue: T? = nil,
        onChange: ((T?) -> Void)? = nil
    ) {
        self.id = id
        self.placeholder = placeholder
        self.disabled = disabled
        self.defaultValue = defaultValue
        self.value = defaultValue
        self.onChange = onChange
    }

    func setValue(value: T?) {
        self.value = value
        onChange?(value)
    }
    func clear() {
        self.value = nil
        onChange?(nil)
    }
    func disable() {
        self.disabled = true
    }
    func enable() {
        self.disabled = false
    }
}

// 字符串输入
class StringInput: FormInput<String> {
    // 可以添加字符串特有的属性
    let maxLength: Int?
    
    init(
        id: String,
        placeholder: String? = nil,
	disabled: Bool = false,
        defaultValue: String? = nil,
        maxLength: Int? = nil,
        onChange: ((String?) -> Void)? = nil
    ) {
        self.maxLength = maxLength
        super.init(
            id: id,
            placeholder: placeholder,
            disabled: disabled,
            defaultValue: defaultValue,
            onChange: onChange
        )
    }
}

// 数值输入
class NumberInput: FormInput<Double> {
    let min: Double?
    let max: Double?
    
    init(
        id: String,
        placeholder: String? = nil,
        disabled: Bool = false,
        defaultValue: Double? = nil,
        min: Double? = nil,
        max: Double? = nil,
        onChange: ((Double?) -> Void)? = nil
    ) {
        self.min = min
        self.max = max
        super.init(
            id: id,
            placeholder: placeholder,
            disabled: disabled,
            defaultValue: defaultValue,
            onChange: onChange
        )
    }
}

// 布尔输入
class BooleanInput: FormInput<Bool> {}

// 配置项的选项
struct FormSelectOption: Identifiable, Codable {
    let id: String
    let label: String
    let value: String
    let description: String?
}

// 选择输入
class SelectInput: FormInput<String> {
    let options: [FormSelectOption]
    
    init(
        id: String,
        placeholder: String? = nil,
        disabled: Bool = false,
        defaultValue: String? = nil,
        options: [FormSelectOption],
        onChange: ((String?) -> Void)? = nil
    ) {
        self.options = options
        super.init(
            id: id,
            placeholder: placeholder,
            disabled: disabled,
            defaultValue: defaultValue,
            onChange: onChange
        )
    }
}

// 多选输入
class MultiSelectInput: FormInput<[String]> {
    let options: [FormSelectOption]
    
    init(
        id: String,
        placeholder: String? = nil,
        disabled: Bool = false,
        defaultValue: [String]? = nil,
        options: [FormSelectOption],
        onChange: (([String]?) -> Void)? = nil
    ) {
        self.options = options
        super.init(
            id: id,
            placeholder: placeholder,
            disabled: disabled,
            defaultValue: defaultValue,
            onChange: onChange
        )
    }
}

// 滑块输入
class SliderInput: FormInput<Double> {
    let min: Double
    let max: Double
    let step: Double
    
    init(
        id: String,
        placeholder: String? = nil,
        disabled: Bool = false,
        defaultValue: Double? = nil,
        min: Double,
        max: Double,
        step: Double = 1,
        onChange: ((Double?) -> Void)? = nil
    ) {
        self.min = min
        self.max = max
        self.step = step
        super.init(
            id: id,
            placeholder: placeholder,
            disabled: disabled,
            defaultValue: defaultValue,
            onChange: onChange
        )
    }
}

struct FieldError: Identifiable {
	let id: String
	let message: String
}

// 配置项定义
struct FormField: Identifiable {
    let id: String           // 配置项唯一标识
    let key: String         // 配置项键名
    let label: String       // 显示标签
    let required: Bool      // 是否必填
    let placeholder: String? // 输入提示
    let input: FormInputType  // 值类型
    let errors: [FieldError] = [] // 错误信息
}
// 然后修改 FormObjectField 的定义
struct FormObjectField: Identifiable {
    let id: String
    let key: String
    let label: String
    let required: Bool
    let fields: [String:AnyFormField]
}
struct FormArrayField: Identifiable {
    let id: String
    let key: String
    let label: String
    let required: Bool
    let field: (_ index: Int) -> AnyFormField
}

// 首先定义一个新的枚举类型来表示所有可能的字段类型
enum AnyFormField: Identifiable {
    case single(FormField)
    case array(FormArrayField)
    case object(FormObjectField)
    
    var id: String {
        switch self {
        case .single(let field): return field.id
        case .array(let field): return field.id
        case .object(let field): return field.id
        }
    }
}

let fields  = FormObjectField(
	id: "goods",
	key: "goods",
	label: "商品",
	required: true,
	fields: [
		"name": .single(FormField(
			id: "name",
			key: "name",
			label: "名称",
			required: true,
			placeholder: "请输入名称",
			input: .string(StringInput(id: "name", placeholder: "请输入名称", defaultValue: nil, onChange: nil))
		)),
		"skus": .array(FormArrayField(
			id: "skus",
			key: "skus",
			label: "SKU",
			required: true,
			field: { index in
				.object(FormObjectField(
					id: "sku-name-\(index)",
					key: "sku-name-\(index)",
					label: "名称",
					required: true,
					fields: [
						"name": .single(FormField(
							id: "sku-name-\(index)",
							key: "sku-name-\(index)",
							label: "名称",
							required: true,
							placeholder: "请输入SKU名称",
							input: .string(StringInput(id: "sku-name-\(index)", placeholder: "请输入SKU名称", defaultValue: nil, onChange: nil))
						)),
						"number": .single(FormField(
							id: "sku-number-\(index)",
							key: "sku-number-\(index)",
							label: "数量",
							required: true,
							placeholder: "请输入SKU数量",
							input: .number(NumberInput(id: "sku-number-\(index)", placeholder: "请输入SKU数量", defaultValue: nil, onChange: nil))
						)),
						"price": .single(FormField(
							id: "sku-price-\(index)",
							key: "sku-price-\(index)",
							label: "价格",
							required: true,
							placeholder: "请输入SKU价格",
							input: .number(NumberInput(id: "sku-price-\(index)", placeholder: "请输入SKU价格", defaultValue: nil, onChange: nil))
						)),
					]
				))
			}
		))
	]
)
