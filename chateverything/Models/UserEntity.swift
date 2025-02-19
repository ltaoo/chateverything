import Foundation
import CoreData

// @objc(UserEntity)
public class UserEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var avatar: String?
    @NSManaged public var created_at: Date?
}

extension UserEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "User")
    }
} 