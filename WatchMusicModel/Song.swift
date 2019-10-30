//
//  Model.swift
//  Music
//

import UIKit
import CoreLocation
import CoreData
import WatchCoreDataHelpers
import AVFoundation

public class Song: NSManagedObject {

    @NSManaged public fileprivate(set) var date: Date

    @NSManaged public var name: String?
    @NSManaged public var creatorID: String?
    @NSManaged public var remoteIdentifier: RemoteRecordID?

    @NSManaged public fileprivate(set) var album___: Album
    @NSManaged public fileprivate(set) var album: Album?
    @NSManaged public fileprivate(set) var artlist___: Artlist
    @NSManaged public fileprivate(set) var artlist: Artlist?
    @NSManaged public fileprivate(set) var artworkURL: String?
    @NSManaged public fileprivate(set) var duration: Double
    @NSManaged public fileprivate(set) var favorite: Int16
    
    @NSManaged public var songURL: String?
    
    public var progress: Progress?


    public override func awakeFromInsert() {
        super.awakeFromInsert()
        primitiveDate = Date()
    }
    
    public static func insert(into moc: NSManagedObjectContext, songURL: String?, infoMap: [AVMetadataKey: Any]) -> Song {
        let song: Song = moc.insertObject()

        if let name = infoMap[.commonKeyTitle] as? String {
            song.name = name
        } else if let nameSub = songURL?.split(separator: ".").first {
            song.name = String(nameSub)
        } else {
            song.name = "unKnown"
        }
        
        if let artworkData = infoMap[.commonKeyArtwork] as? Data {
            do {
                if !FileManager.default.fileExists(atPath: URL.library.appendingPathComponent("ArtWorks").path) {
                    try FileManager.default.createDirectory(at: URL.library.appendingPathComponent("ArtWorks", isDirectory: true), withIntermediateDirectories: true, attributes: nil)
                }
                
                let path = URL.library.appendingPathComponent("ArtWorks").appendingPathComponent(String.uuid)
                try artworkData.write(to: path, options: [])
                song.artworkURL = path.lastPathComponent
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        song.date = Date()
        song.songURL = songURL
        song.favorite = 0
        song.album = Album.findOrCreate(with: infoMap, in: moc)
        song.artlist = Artlist.findOrCreate(with: infoMap, in: moc)
        
        return song
    }

    public static func insert(into moc: NSManagedObjectContext, songURL: String?, remoteIdentifier: RemoteRecordID? = nil, date: Date? = nil, creatorID: String? = nil) -> Song {
        let song: Song = moc.insertObject()
        song.songURL = songURL
        song.album = Album.findOrCreate(with: [:], in: moc)
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

