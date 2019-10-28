//
//  SongMetadata.swift
//  Music
//

import CoreData
import WatchCoreDataHelpers


public class SongMetadata: NSManagedObject {}

extension SongMetadata: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "updatedAt", ascending: false)]
    }

    public static var defaultPredicate: NSPredicate {
        return notMarkedForLocalDeletionPredicate
    }
}


extension SongMetadata: DelayedDeletable {
    @NSManaged public var markedForDeletionDate: Date?
}

