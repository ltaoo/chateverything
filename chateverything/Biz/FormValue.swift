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
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .string(let input):
            try container.encode("string", forKey: .type)
            try container.encode(input, forKey: .value)
        case .number(let input):
            try container.encode("number", forKey: .type)
            try container.encode(input, forKey: .value)
        case .boolean(let input):
            try container.encode("boolean", forKey: .type)
            try container.encode(input, forKey: .value)
        case .select(let input):
            try container.encode("select", forKey: .type)
            try container.encode(input, forKey: .value)
        case .multiSelect(let input):
            try container.encode("multiSelect", forKey: .type)
            try container.encode(input, forKey: .value)
        case .slider(let input):
            try container.encode("slider", forKey: .type)
            try container.encode(input, forKey: .value)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "string":
            self = .string(try container.decode(StringInput.self, forKey: .value))
        case "number":
            self = .number(try container.decode(NumberInput.self, forKey: .value))
        case "boolean":
            self = .boolean(try container.decode(BooleanInput.self, forKey: .value))
        case "select":
            self = .select(try container.decode(SelectInput.self, forKey: .value))
        case "multiSelect":
            self = .multiSelect(try container.decode(MultiSelectInput.self, forKey: .value))
        case "slider":
            self = .slider(try container.decode(SliderInput.self, forKey: .value))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type")
        }
    }
}

// 使用协议而不是类
protocol FormInputProtocol: Codable, ObservableObject {
    associatedtype ValueType: Codable
    var value: ValueType { get set }
}

// 定义一个新的协议来规范所有输入类型的行为
protocol FormInputBehavior {
    associatedtype T
    var value: T? { get set }
    var disabled: Bool { get set }
    var onChange: ((T?) -> Void)? { get set }
    
    func setValue(value: T?)
    func clear()
    func disable()
    func enable()
}

// 修改基础输入类以实现该协议
class FormInput<T: Codable>: ObservableObject, FormInputBehavior, Codable {
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

    enum CodingKeys: String, CodingKey {
        case id
        case placeholder
        case disabled
        case defaultValue
        case value
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
        disabled = try container.decode(Bool.self, forKey: .disabled)
        defaultValue = try container.decodeIfPresent(T.self, forKey: .defaultValue)
        value = try container.decodeIfPresent(T.self, forKey: .value)
        onChange = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(placeholder, forKey: .placeholder)
        try container.encode(disabled, forKey: .disabled)
        try container.encodeIfPresent(defaultValue, forKey: .defaultValue)
        try container.encodeIfPresent(value, forKey: .value)
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
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
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
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
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
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
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
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
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
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

struct FieldError: Identifiable {
	let id: String
	let message: String
}

// 配置项定义
class FormField: Identifiable {
    let id: String           // 配置项唯一标识
    let key: String         // 配置项键名
    let label: String       // 显示标签
    let required: Bool      // 是否必填
    let input: FormInputType  // 值类型
    let errors: [FieldError] = [] // 错误信息

    init(id: String, key: String, label: String, required: Bool, input: FormInputType) {
        self.id = id
        self.key = key
        self.label = label
        self.required = required
        self.input = input
    }

    var value: Any? {
        switch input {
        case .string(let input): return input.value
        case .number(let input): return input.value
        case .boolean(let input): return input.value
        case .select(let input): return input.value
        case .multiSelect(let input): return input.value
        case .slider(let input): return input.value
        }
    }

    // 添加验证结果类型
    struct ValidationResult {
        let isValid: Bool
        let value: Any?
        let errors: [FieldError]
    }
    
    func validate() -> ValidationResult {
        var errors: [FieldError] = []
        let value = self.value
        
        // 检查必填项
        if required && (value == nil || (value as? String)?.isEmpty == true) {
            errors.append(FieldError(id: id, message: "\(label)不能为空"))
        }
        
        // 根据不同类型进行特定验证
        switch input {
        case .string(let input):
            if let maxLength = input.maxLength,
               let strValue = value as? String,
               strValue.count > maxLength {
                errors.append(FieldError(id: id, message: "\(label)长度不能超过\(maxLength)"))
            }
        case .number(let input):
            if let numValue = value as? Double {
                if let min = input.min, numValue < min {
                    errors.append(FieldError(id: id, message: "\(label)不能小于\(min)"))
                }
                if let max = input.max, numValue > max {
                    errors.append(FieldError(id: id, message: "\(label)不能大于\(max)"))
                }
            }
        default:
            break
        }
        
        return ValidationResult(isValid: errors.isEmpty, value: value, errors: errors)
    }
}

// 然后修改 FormObjectField 的定义
class FormObjectField: Identifiable {
    let id: String
    let key: String
    let label: String
    let required: Bool
    let fields: [String:AnyFormField]
    let errors: [FieldError] = []

    init(id: String, key: String, label: String, required: Bool, fields: [String:AnyFormField]) {
        self.id = id
        self.key = key
        self.label = label
        self.required = required
        self.fields = fields
    }

    var values: [String: Any] {
        var result: [String: Any] = [:]
        
        for (key, field) in fields {
            switch field {
            case .single(let formField):
                if let value = formField.value {
                    result[key] = value
                }
            case .array(let arrayField):
                result[key] = arrayField.values
            case .object(let objectField):
                result[key] = objectField.values
            }
        }
        
        return result
    }

    // 在 FormObjectField 中添加验证方法
    struct ValidationResult {
        let isValid: Bool
        let values: [String: Any]
        let errors: [String: [FieldError]]
    }
    
    func validateValues() -> ValidationResult {
        var allValues: [String: Any] = [:]
        var allErrors: [String: [FieldError]] = [:]
        var isValid = true
        
        for (key, field) in fields {
            switch field {
            case .single(let formField):
                let result = formField.validate()
                if !result.isValid {
                    isValid = false
                    allErrors[key] = result.errors
                }
                if let value = result.value {
                    allValues[key] = value
                }
                
            case .array(let arrayField):
                let result = arrayField.validateValues()
                if !result.isValid {
                    isValid = false
                    allErrors[key] = result.errors
                }
                allValues[key] = result.values
                
            case .object(let objectField):
                let result = objectField.validateValues()
                if !result.isValid {
                    isValid = false
                    allErrors[key] = result.errors.flatMap { $0.value }
                }
                allValues[key] = result.values
            }
        }
        
        return ValidationResult(isValid: isValid, values: allValues, errors: allErrors)
    }
}

class FormArrayField: Identifiable {
    let id: String
    let key: String
    let label: String
    let required: Bool
    let errors: [FieldError] = []
    let field: (_ index: Int) -> AnyFormField

    var fields: [AnyFormField] = []

    init(id: String, key: String, label: String, required: Bool, field: @escaping (_ index: Int) -> AnyFormField) {
        self.id = id
        self.key = key
        self.label = label
        self.required = required
        self.field = field
    }

    func append() -> AnyFormField {
        let newField = field(fields.count)
        self.fields.append(newField)
        return newField
    }
    func remove(at index: Int) {
        self.fields.remove(at: index)
    }

    var values: [Any] {
        return fields.map { field in
            switch field {
            case .single(let formField):
                return formField.value ?? NSNull()
            case .array(let arrayField):
                return arrayField.values
            case .object(let objectField):
                return objectField.values
            }
        }
    }

    // 在 FormArrayField 中添加验证方法
    struct ValidationResult {
        let isValid: Bool
        let values: [Any]
        let errors: [FieldError]
    }
    
    func validateValues() -> ValidationResult {
        var allValues: [Any] = []
        var allErrors: [FieldError] = []
        var isValid = true
        
        for (index, field) in fields.enumerated() {
            switch field {
            case .single(let formField):
                let result = formField.validate()
                if !result.isValid {
                    isValid = false
                    allErrors.append(contentsOf: result.errors)
                }
                allValues.append(result.value ?? NSNull())
                
            case .array(let arrayField):
                let result = arrayField.validateValues()
                if !result.isValid {
                    isValid = false
                    allErrors.append(contentsOf: result.errors)
                }
                allValues.append(result.values)
                
            case .object(let objectField):
                let result = objectField.validateValues()
                if !result.isValid {
                    isValid = false
                    allErrors.append(contentsOf: result.errors.flatMap { $0.value })
                }
                allValues.append(result.values)
            }
        }
        
        return ValidationResult(isValid: isValid, values: allValues, errors: allErrors)
    }
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

    var values: Any {
        switch self {
        case .single(let field):
            return field.value ?? NSNull()
        case .array(let field):
            return field.values
        case .object(let field):
            return field.values
        }
    }
}
