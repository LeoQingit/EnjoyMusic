//
//  Album.swift
//  Music
//

import UIKit
import CoreLocation
import CoreData
import CoreDataHelpers


public class Album: NSManagedObject {

    @NSManaged public var name: String
    @NSManaged fileprivate(set) var songs: Set<Song>
    @NSManaged fileprivate(set) var artlist: Artlist?
    @NSManaged public internal(set) var numberOfSongs: Int64
    @NSManaged internal var updatedAt: Date

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        primitiveUpdatedAt = Date()
    }

    static func findOrCreate(for unique: String, in context: NSManagedObjectContext) -> Album {
        let predicate = Album.predicate(format: "%K == %@", #keyPath(uniqueId), unique)
        let album = findOrCreate(in: context, matching: predicate) {
            $0.uniqueId = unique
            $0.artlist = Artlist.findOrCreateArtlist(for: "未知", in: context)
        }
        return album
    }

    public override func prepareForDeletion() {
        guard let c = artlist else { return }
        if c.albums.filter({ !$0.isDeleted }).isEmpty {
            managedObjectContext?.delete(c)
        }
    }

    public override func willSave() {
        super.willSave()
        if hasChangedSongs {
            updateSongCount()
            if songs.count == 0 {
                markForLocalDeletion()
            }
        }
        if hasInsertedSongs {
            refreshUpdateDate()
        }
        if changedForDelayedDeletion {
            removeFromArtlist()
        }
    }

    var changedSongCountDelta: Int64 {
        guard hasChangedSongs else { return 0 }
        return numberOfSongs - committedNumberOfSongs
    }


    // MARK: Private
    @NSManaged fileprivate var uniqueId: String
    @NSManaged fileprivate var primitiveUpdatedAt: Date


    fileprivate var hasChangedSongs: Bool {
        return changedValue(forKey: #keyPath(songs)) != nil
    }

    fileprivate var hasInsertedSongs: Bool {
        guard hasChangedSongs else { return false }
        return songs.filter { $0.isInserted }.count > 0
    }

    fileprivate var committedNumberOfSongs: Int64 {
        let n = committedValue(forKey: #keyPath(numberOfSongs)) as? Int ?? 0
        return Int64(n)
    }

    fileprivate func refreshUpdateDate() {
        guard changedValue(forKey: UpdateTimestampKey) == nil else { return }
        updatedAt = Date()
        artlist?.refreshUpdateDate()
    }

    fileprivate func updateSongCount() {
        guard Int64(songs.count) != numberOfSongs else { return }
        numberOfSongs = Int64(songs.count)
        artlist?.updateSongCount()
    }

    fileprivate func removeFromArtlist() {
        guard artlist != nil else { return }
        artlist = nil
    }


}


extension Album: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: UpdateTimestampKey, ascending: false)]
    }

    public static var defaultPredicate: NSPredicate {
        return notMarkedForLocalDeletionPredicate
    }
}

extension Album: DelayedDeletable {
    @NSManaged public var markedForDeletionDate: Date?
}

extension Album: UpdateTimestampable {}

