
public struct DefaultChatResponse: Codable {
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let choices: [Choice]
    public let usage: Usage
    
    enum CodingKeys: String, CodingKey {
        case id, object, created, model, choices, usage
    }
    
    public struct Choice: Codable {
        public let index: Int
        public let message: Message
        public let logprobs: String?
        public let finishReason: String
        
        enum CodingKeys: String, CodingKey {
            case index, message, logprobs
            case finishReason = "finish_reason"
        }
    }
    
    public struct Message: Codable {
        public let role: String
        public let content: String
    }
    
    public struct Usage: Codable {
        public let promptTokens: Int
        public let completionTokens: Int
        public let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
    
    public struct PromptTokensDetails: Codable {
        public let cachedTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case cachedTokens = "cached_tokens"
        }
    }
}

public struct DeepseekChatResponse: Codable {
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let choices: [Choice]
    public let usage: Usage
    
    enum CodingKeys: String, CodingKey {
        case id, object, created, model, choices, usage
    }
    
    public struct Choice: Codable {
        public let index: Int
        public let message: Message
        public let logprobs: String?
        public let finishReason: String
        
        enum CodingKeys: String, CodingKey {
            case index, message, logprobs
            case finishReason = "finish_reason"
        }
    }
    
    public struct Message: Codable {
        public let role: String
        public let content: String
    }
    
    public struct Usage: Codable {
        public let promptTokens: Int
        public let completionTokens: Int
        public let totalTokens: Int
        public let promptTokensDetails: PromptTokensDetails
        public let promptCacheHitTokens: Int
        public let promptCacheMissTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
            case promptTokensDetails = "prompt_tokens_details"
            case promptCacheHitTokens = "prompt_cache_hit_tokens"
            case promptCacheMissTokens = "prompt_cache_miss_tokens"
        }
    }
    
    public struct PromptTokensDetails: Codable {
        public let cachedTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case cachedTokens = "cached_tokens"
        }
    }
}

public struct DoubaoChatResponse: Codable {
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let choices: [Choice]
    public let usage: Usage
    
    public struct Choice: Codable {
        public let finishReason: String
        public let index: Int
        public let logprobs: String?
        public let message: Message
        
        enum CodingKeys: String, CodingKey {
            case finishReason = "finish_reason"
            case index, logprobs, message
        }
    }
    
    public struct Message: Codable {
        public let content: String
        public let role: String
    }
    
    public struct Usage: Codable {
        public let completionTokens: Int
        public let promptTokens: Int
        public let totalTokens: Int
        public let promptTokensDetails: PromptTokensDetails
        public let completionTokensDetails: CompletionTokensDetails
        
        enum CodingKeys: String, CodingKey {
            case completionTokens = "completion_tokens"
            case promptTokens = "prompt_tokens"
            case totalTokens = "total_tokens"
            case promptTokensDetails = "prompt_tokens_details"
            case completionTokensDetails = "completion_tokens_details"
        }
    }
    
    public struct PromptTokensDetails: Codable {
        public let cachedTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case cachedTokens = "cached_tokens"
        }
    }
    
    public struct CompletionTokensDetails: Codable {
        public let reasoningTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case reasoningTokens = "reasoning_tokens"
        }
    }
}

public struct ChatResponse: Codable {
    public let reply: String
    
    public init(reply: String) {
        self.reply = reply
    }
}
