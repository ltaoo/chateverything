import Foundation
import CoreData

@objc(RoleEntity)
public class RoleEntity: NSManagedObject {
   
}

extension RoleEntity: Identifiable {
}

// MARK: - 属性扩展
extension RoleEntity {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var avatar: String?
    @NSManaged public var prompt: String?
    @NSManaged public var settings: String?
    @NSManaged public var created_at: Date?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RoleEntity> {
        return NSFetchRequest<RoleEntity>(entityName: "Role")
    }
}

// MARK: - 便利方法
extension RoleEntity {
    // func to() -> Role {
    //     return RoleEntity(id: id, name: name, avatar: avatar, prompt: prompt, settings: settings)
    // }

    static func create(in context: NSManagedObjectContext,
                      name: String,
                      avatar: String,
                      prompt: String,
                      settings: String) -> RoleEntity {
        let role = RoleEntity(context: context)
        role.id = UUID()
        role.name = name
        role.avatar = avatar
        role.prompt = prompt
        role.settings = settings
        role.created_at = Date()
        return role
    }
    
    func update(name: String? = nil,
                avatar: String? = nil,
                prompt: String? = nil,
                settings: String? = nil) {
        if let name = name {
            self.name = name
        }
        if let avatar = avatar {
            self.avatar = avatar
        }
        if let prompt = prompt {
            self.prompt = prompt
        }
        if let settings = settings {
            self.settings = settings
        }
    }
}

// MARK: - 默认角色
extension RoleEntity {
    static let defaultRoles: [(name: String, avatar: String, prompt: String, settings: String)] = [
   	// Role(
        //     id: "ielts_examiner",
        //     name: "IELTS考官",
        //     avatar: "graduation.cap",
        //     prompt: "You are an IELTS speaking examiner. Conduct a simulated IELTS speaking test by asking questions one at a time. After receiving each response with pronunciation scores from speech recognition, evaluate the answer and proceed to the next question. Do not ask multiple questions at once. After all sections are completed, provide a comprehensive evaluation and an estimated IELTS speaking band score.",
        //     description: "模拟IELTS口语考试，提供专业评分和反馈"
        // ),
        // Role(
        //     id: "english_teacher",
        //     name: "英语老师",
        //     avatar: "person.fill.checkmark",
        //     prompt: "You are a professional English teacher. Help students improve their English by engaging in natural conversations, correcting their mistakes, and explaining grammar points when necessary. Be encouraging and supportive.",
        //     description: "帮助提升英语会话能力，纠正错误并解释语法要点"
        // ),
        (
            name: "通用助手",
            avatar: "assistant",
            prompt: "你是一个有帮助的助手，会用简单易懂的方式回答问题。",
            settings: """
            {
                "speaker": {
                    "id": "zh-CN-XiaoxiaoNeural",
                    "engine": "晓晓"
                },
                "model": {
                    "id": "gpt-3.5-turbo"
                },
                "temperature": 0.7
            }
            """
        ),
        (
            name: "程序员",
            avatar: "developer",
            prompt: "你是一个经验丰富的程序员，精通多种编程语言和软件开发最佳实践。请用专业的方式回答编程相关问题。",
            settings: """
            {
                "speaker": {
                    "id": "zh-CN-YunxiNeural",
                    "engine": "云希"
                },
                "model": {
                    "provider": "deepseek",
                    "id": "deepseek-chat"
                },
                "temperature": 0.5
            }
            """
        ),
        (
            name: "英语老师",
            avatar: "teacher",
            prompt: "你是一位专业的英语教师，擅长语法讲解、口语教学和写作指导。请用生动有趣的方式帮助学习者提高英语水平。",
            settings: """
            {
                "speaker": {
                    "id": "en-US-JennyNeural",
                    "engine": "Jenny"
                },
                "model": {
                    "id": "gpt-4"
                },
                "temperature": 0.7
            }
            """
        ),
        (
            name: "写作助手",
            avatar: "writer",
            prompt: "你是一位专业的写作助手，擅长文章润色、创意写作和内容优化。请帮助用户提升文字表达能力。",
            settings: """
            {
                "speaker": {
                    "id": "zh-CN-XiaoyiNeural",
                    "engine": "晓伊"
                },
                "model": {
                    "provider": "openai",
                    "id": "gpt-4"
                },
                "temperature": 0.8
            }
            """
        )
    ]
    
    static func createDefaultRoles(in context: NSManagedObjectContext) {
        // 检查是否已经存在角色
        let fetchRequest: NSFetchRequest<RoleEntity> = RoleEntity.fetchRequest()
        
        do {
            let count = try context.count(for: fetchRequest)
            print("count: \(count)")
            
            // 只在没有任何角色时创建默认角色
            if count == 0 {
                for roleData in defaultRoles {
                guard let entity = NSEntityDescription.entity(forEntityName: "Role", in: context) else {
                    fatalError("Failed to initialize UserEntity")
                }
                let role = RoleEntity(entity: entity, insertInto: context)
                role.id = UUID()
                role.name = roleData.name
                role.avatar = roleData.avatar
                role.prompt = roleData.prompt
                role.settings = roleData.settings
                role.created_at = Date()
                    // _ = RoleEntity.create(
                    //     in: context,
                    //     name: roleData.name,
                    //     avatar: roleData.avatar,
                    //     prompt: roleData.prompt,
                    //     settings: roleData.settings
                    // )
                }
                
                try context.save()
            }
        } catch {
            print("Error creating default roles: \(error)")
        }
    }
}
