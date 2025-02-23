//
//  chateverythingTests.swift
//  chateverythingTests
//
//  Created by litao on 2025/2/5.
//

import Testing
@testable import chateverything

struct chateverythingTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func t1() async throws {
        // 创建一个字符串输入
        let input = StringInput(
            id: "test",
            placeholder: "Enter text",
            defaultValue: "hello",
            maxLength: 10
        )
        #expect(input.value == "hello")
        #expect(input.maxLength == 10)
        
        // 测试设置值
        input.setValue(value: "world")
        #expect(input.value == "world")
        
        // 测试清除值
        input.clear()
        #expect(input.value == nil)
    }

    @Test func t2() async throws {
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
            formField.input.setValue("iPhone16Pro") // 现在可以直接使用 setValue
        }
        if case .array(let formArrayField) = goodsInput.fields["skus"] {
            let field = formArrayField.append() // 新增一个sku
            if case .object(let sku) = field {
                if case .single(let formField) = sku.fields["name"] {
                    formField.input.setValue("512G") // 设置sku名称
                }
                if case .single(let formField) = sku.fields["number"] {
                    formField.input.setValue(10.0) // 设置sku数量
                }
                if case .single(let formField) = sku.fields["price"] {
                    formField.input.setValue(1888.0) // 设置sku价格
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
        #expect(result.isValid)
    }
}
