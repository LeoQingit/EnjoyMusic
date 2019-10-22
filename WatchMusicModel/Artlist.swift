//
//  Model.swift
//  Music
//

import UIKit
import CoreLocation
import CoreData
import WatchCoreDataHelpers


public class Artlist: NSManagedObject {

    @NSManaged public internal(set) var numberOfAlbums: Int64
    @NSManaged public internal(set) var numberOfSongs: Int64
    @NSManaged public fileprivate(set) var albums: Set<Album>
    @NSManaged internal var updatedAt: Date

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        primitiveUpdatedAt = Date()
    }

    static func findOrCreateArtlist(for unique: String, in context: NSManagedObjectContext) -> Artlist? {
        let predicate = Artlist.predicate(format: "%K == %@", #keyPath(uniqueId), unique)
        let artlist = findOrCreate(in: context, matching: predicate) { $0.uniqueId = unique }
        return artlist
    }

    public override func willSave() {
        super.willSave()
        if hasChangedAlbums {
            updateAlbumCount()
            if albums.count == 0 {
                markForLocalDeletion()
            }
        }
        updateSongCount()
    }

    func refreshUpdateDate() {
        guard changedValue(forKey: UpdateTimestampKey) == nil else { return }
        updatedAt = Date()
    }

    func updateSongCount() {
        let currentAndDeletedAlbums = albums.union(committedAlbums)
        let deltaInAlbums: Int64 = currentAndDeletedAlbums.reduce(0) { $0 + $1.changedSongCountDelta }
        let pendingDelta = numberOfSongs - committedNumberOfSongs
        guard pendingDelta != deltaInAlbums else { return }
        numberOfSongs = committedNumberOfSongs + deltaInAlbums
    }


    // MARK: Private

    @NSManaged fileprivate var uniqueId: String
    @NSManaged fileprivate var primitiveUpdatedAt: Date

    fileprivate var hasChangedAlbums: Bool {
        return changedValue(forKey: #keyPath(Artlist.albums)) != nil
    }

    fileprivate func updateAlbumCount() {
        guard numberOfAlbums != Int64(albums.count) else { return }
        numberOfAlbums = Int64(albums.count)
    }

    fileprivate var committedAlbums: Set<Album> {
        return committedValue(forKey: #keyPath(Artlist.albums)) as? Set<Album> ?? Set()
    }

    fileprivate var committedNumberOfSongs: Int64 {
        let n = committedValue(forKey: #keyPath(Artlist.numberOfSongs)) as? Int ?? 0
        return Int64(n)
    }

    fileprivate var hasChangedNumberOfSongs: Bool {
        return changedValue(forKey: #keyPath(Artlist.numberOfSongs)) != nil
    }

}


extension Artlist: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: UpdateTimestampKey, ascending: false)]
    }

    public static var defaultPredicate: NSPredicate {
        return notMarkedForLocalDeletionPredicate
    }
}


extension Artlist: DelayedDeletable {
    @NSManaged public var markedForDeletionDate: Date?
}


extension Artlist: UpdateTimestampable {}

