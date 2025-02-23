import XCTest
@testable import chateverything

final class FormValueTests: XCTestCase {
    func testStringInput() {
        // 创建一个字符串输入
        let input = StringInput(
            id: "test",
            placeholder: "Enter text",
            defaultValue: "hello",
            maxLength: 10
        )
        
        // 测试初始值
        XCTAssertEqual(input.value, "hello")
        XCTAssertEqual(input.maxLength, 10)
        
        // 测试设置值
        input.setValue(value: "world")
        XCTAssertEqual(input.value, "world")
        
        // 测试清除值
        input.clear()
        XCTAssertNil(input.value)
    }
    
    func testFormField() {
        // 创建一个表单字段
        let field = FormField(
            id: "name",
            key: "name",
            label: "Name",
            required: true,
            input: .string(StringInput(id: "name"))
        )
        
        // 测试必填验证
        let result = field.validate()
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errors.first?.message, "Name不能为空")
        
        // 设置值后再验证
        if case .string(let input) = field.input {
            input.setValue(value: "Test Name")
        }
        let result2 = field.validate()
        XCTAssertTrue(result2.isValid)
        XCTAssertTrue(result2.errors.isEmpty)
    }
    
    func testFormObjectField() {
        // 创建一个对象字段
        let objectField = FormObjectField(
            id: "person",
            key: "person",
            label: "Person",
            required: true,
            fields: [
                "name": .single(FormField(
                    id: "name",
                    key: "name",
                    label: "Name",
                    required: true,
                    input: .string(StringInput(id: "name"))
                )),
                "age": .single(FormField(
                    id: "age",
                    key: "age",
                    label: "Age",
                    required: true,
                    input: .number(NumberInput(id: "age"))
                ))
            ]
        )
        
        // 测试验证
        let result = objectField.validateValues()
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errors.count, 2)
        
        // 设置值后再验证
        if case .single(let nameField) = objectField.fields["name"],
           case .string(let nameInput) = nameField.input {
            nameInput.setValue(value: "John")
        }
        
        if case .single(let ageField) = objectField.fields["age"],
           case .number(let ageInput) = ageField.input {
            ageInput.setValue(value: 25)
        }
        
        let result2 = objectField.validateValues()
        XCTAssertTrue(result2.isValid)
        XCTAssertTrue(result2.errors.isEmpty)
        
        // 测试获取值
        let values = objectField.values
        XCTAssertEqual(values["name"] as? String, "John")
        XCTAssertEqual(values["age"] as? Double, 25)
    }

    func testGoodsInput() {
	let goodsInput  = FormObjectField(
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
			input: .string(StringInput(id: "name", defaultValue: nil, onChange: nil))
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
							input: .string(StringInput(id: "sku-name-\(index)", defaultValue: nil, onChange: nil))
						)),
						"number": .single(FormField(
							id: "sku-number-\(index)",
							key: "sku-number-\(index)",
							label: "数量",
							required: true,
							input: .number(NumberInput(id: "sku-number-\(index)", defaultValue: nil, onChange: nil))
						)),
						"price": .single(FormField(
							id: "sku-price-\(index)",
							key: "sku-price-\(index)",
							label: "价格",
							required: true,
							input: .number(NumberInput(id: "sku-price-\(index)", defaultValue: nil, onChange: nil))
						)),
					]
				))
			}
		))
	]
)

// 使用方法
if case .single(let formField) = goodsInput.fields["name"] {
    formField.input.setValue("iPhone16Pro") // 设置商品名称
}
if case .array(let formArrayField) = goodsInput.fields["skus"] {
    let field = formArrayField.append() // 新增一个sku
    if case .object(let formObjectField) = field {
        if case .single(let formField) = formObjectField.fields["name"] {
            formField.input.setValue("512G") // 设置sku名称
        }
	if case .single(let formField) = formObjectField.fields["number"] {
		formField.input.setValue(10) // 设置sku数量
	}
	if case .single(let formField) = formObjectField.fields["price"] {
		formField.input.setValue(1888) // 设置sku价格
	}
    }
}
// 使用方法示例
let values: [String: Any] = goodsInput.values

// 现在可以这样使用
if let name = values["name"] as? String {
    print("商品名称: \(name)")
}

if let skus = values["skus"] as? [[String: Any]] {
    for sku in skus {
        print("SKU名称: \(sku["name"] ?? "")")
        print("SKU数量: \(sku["number"] ?? 0)")
        print("SKU价格: \(sku["price"] ?? 0)")
    }
}

  let result = goodsInput.validateValues()
  print(result)
  XCTAssertTrue(result.isValid)
    }
} 
