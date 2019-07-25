//
//  DeleyedDeletable.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/5/8.
//

import Foundation
import CoreData

private let MarkedForDeletionDateKey = "markedForDeletionDate"

public protocol DelayedDeletable: class {
    var changedForDelayedDeletion: Bool { get }
    var markedForDeletionDate: Date? { get set}
    func markForLocalDeletion()
}

extension DelayedDeletable {
    public static var notMarkedForLocalDeletionPredicate: NSPredicate {
        return NSPredicate.init(format: "%K == NULL", MarkedForDeletionDateKey)
    }
}

extension DelayedDeletable where Self: NSManagedObject {
    public var changedForDelayedDeletion: Bool {
        return changedValue(forKey: MarkedForDeletionDateKey) as? Date != nil
    }
    
    public func markForLocalDeletion() {
        guard isFault || markedForDeletionDate == nil else { return }
        markedForDeletionDate = Date()
    }
}


extension NSManagedObjectContext {
    public func batchDeleteObjectsMarkedForLocalDeletion() {

    }
}

private let DeletionAgeBeforePermanentlyDeletingObjects = TimeInterval(2 * 60)

extension DelayedDeletable where Self: NSManagedObject, Self: Managed {
    fileprivate static func batchDeleteObjectsMarkedForLocalDeletionInContext(_ managedObjectContext: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        let cutoff = Date(timeIntervalSinceNow: -DeletionAgeBeforePermanentlyDeletingObjects)
        fetchRequest.predicate = NSPredicate(format: "%K < %@", MarkedForDeletionDateKey, cutoff as NSDate)
        if #available(iOS 9.0, *) {
            let batchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchRequest.resultType = .resultTypeStatusOnly
            do {
                try managedObjectContext.execute(batchRequest)
            } catch { }
        } else {
            do {
                if let items = try managedObjectContext.fetch(fetchRequest) as? [NSManagedObject] {
                    for item in items {
                        managedObjectContext.delete(item)
                    }
                }
            } catch { }
        }
    }
}
