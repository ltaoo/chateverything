import Foundation
import CoreData

@objc(Settings)
public class SettingsEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var user_id: String?
    @NSManaged public var payload: String?
}

extension SettingsEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SettingsEntity> {
        return NSFetchRequest<SettingsEntity>(entityName: "Settings")
    }
} 