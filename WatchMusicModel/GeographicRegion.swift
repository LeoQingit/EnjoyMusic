//
//  Region.swift
//  Music
//

import CoreData
import WatchCoreDataHelpers


public class Region: NSManagedObject {}

extension Region: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "updatedAt", ascending: false)]
    }

    public static var defaultPredicate: NSPredicate {
        return notMarkedForLocalDeletionPredicate
    }
}


extension Region: DelayedDeletable {
    @NSManaged public var markedForDeletionDate: Date?
}

