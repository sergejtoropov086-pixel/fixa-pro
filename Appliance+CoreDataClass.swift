import Foundation
import CoreData

@objc(Appliance)
public class Appliance: NSManagedObject {
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        dateAdded = Date()
    }
}
