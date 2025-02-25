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
}
