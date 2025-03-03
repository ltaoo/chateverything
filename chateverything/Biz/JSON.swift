import Foundation

class JSON {
    
    /// 将对象转换为 JSON 字符串
    /// - Parameter value: 任意符合 Encodable 协议的对象
    /// - Returns: JSON 字符串，如果转换失败则返回 nil
    static func stringify(_ value: Any) -> String? {
        do {
            let str = try JSONSerialization.data(withJSONObject: value, options: [])
            let str2 = String(data: str, encoding: .utf8)
            return str2
        } catch {
            print("JSON stringify error:", error)
            return nil
        }
    }
    
    /// 将 JSON 字符串解析为指定类型的对象
    /// - Parameters:
    ///   - string: JSON 字符串
    ///   - type: 目标类型
    /// - Returns: 解析后的对象，如果解析失败则返回 nil
    static func parse(_ string: String) -> [String:Any]? {
        guard let data = string.data(using: .utf8) else { return nil }
        do {
            let response = try JSONSerialization.jsonObject(with: data) as? [String:Any]
            return response
        } catch {
            print("JSON parse error:", error)
            return [:]
        }
    }
}
