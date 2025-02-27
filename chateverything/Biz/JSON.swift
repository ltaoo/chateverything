import Foundation

class JSON {
    
    /// 将对象转换为 JSON 字符串
    /// - Parameter value: 任意符合 Encodable 协议的对象
    /// - Returns: JSON 字符串，如果转换失败则返回 nil
    static func stringify<T: Encodable>(_ value: T) -> String? {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(value)
            return String(data: data, encoding: .utf8)
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
    static func parse<T: Decodable>(_ string: String, as type: T.Type) -> T? {
        guard let data = string.data(using: .utf8) else { return nil }
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("JSON parse error:", error)
            return nil
        }
    }
}
