import Foundation
import AVFoundation
import Speech
import QCloudRealTTS

// 修改 TTSProvider 结构
public struct TTSProvider: Identifiable {
    public let id: String
    public let name: String
    public let logo_uri: String
    public let credential: FormObjectField?
    public let schema: FormObjectField
}


public class TTSCredential: ObservableObject {
    let appId: String?
    let secretId: String?
    let secretKey: String?

    init(appId: String?, secretId: String?, secretKey: String?) {
        self.appId = appId
        self.secretId = secretId
        self.secretKey = secretKey
    }
}

public class TTSProviderValue: ObservableObject {
	public var id: String
	@Published public var enabled: Bool
    @Published public var credential: [String:String]

    init(id: String, enabled: Bool, credential: [String:String]) {
        self.id = id
        self.enabled = enabled
        self.credential = credential
    }

    public func update(enabled: Bool) {
        self.enabled = enabled
    }
}
