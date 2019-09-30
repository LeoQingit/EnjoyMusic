//
//  Model.swift
//  Music
//

import UIKit
import CoreLocation
import CoreData
import WatchCoreDataHelpers


public class Song: NSManagedObject {

    @NSManaged public fileprivate(set) var date: Date

    @NSManaged public var creatorID: String?
    @NSManaged public var remoteIdentifier: RemoteRecordID?

    @NSManaged public fileprivate(set) var album___: Album
    @NSManaged public fileprivate(set) var album: Album?
    @NSManaged public fileprivate(set) var coverURL: String?
    @NSManaged public fileprivate(set) var duration: Double
    @NSManaged public fileprivate(set) var favorite: Int16
    @NSManaged public var name: String?
    
    @NSManaged public var songData: Data?


    public override func awakeFromInsert() {
        super.awakeFromInsert()
        primitiveDate = Date()
    }

    public static func insert(into moc: NSManagedObjectContext, songName: String?, songData: Data?) -> Song {
        let song: Song = moc.insertObject()
        song.name = songName
        song.songData = songData
        song.date = Date()
        return song
    }

    public static func insert(into moc: NSManagedObjectContext, songData: Data?, remoteIdentifier: RemoteRecordID? = nil, date: Date? = nil, creatorID: String? = nil) -> Song {
        let song: Song = moc.insertObject()
        song.songData = songData
        song.album = Album.findOrCreate(for: "未知", in: moc)
        song.remoteIdentifier = remoteIdentifier
        if let d = date {
            song.date = d
        }
        song.creatorID = creatorID
        return song
    }

    public override func willSave() {
        super.willSave()
        if changedForDelayedDeletion || changedForRemoteDeletion {
            removeFromAlbum()
        }
    }


    // MARK: Private

    @NSManaged fileprivate var primitiveDate: Date


    fileprivate func removeFromAlbum() {
        guard album != nil else { return }
        album = nil
    }

}


extension Song: Managed {

    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: #keyPath(date), ascending: false)]
    }

    public static var defaultPredicate: NSPredicate {
        return notMarkedForDeletionPredicate
    }

}


extension Song: DelayedDeletable {
    @NSManaged public var markedForDeletionDate: Date?
}


extension Song: RemoteDeletable {
    @NSManaged public var markedForRemoteDeletion: Bool
}

