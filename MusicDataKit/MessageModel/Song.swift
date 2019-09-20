//
//  Song.swift
//  MusicDataKit
//
//  Created by Leo Qin on 2019/7/26.
//  Copyright © 2019 Leo Qin. All rights reserved.
//

import CoreData

struct SongStatus: OptionSet {
    let rawValue: Int32
    
    static let common           = SongStatus(rawValue: 1 << 0)
    static let draft            = SongStatus(rawValue: 1 << 1)
    static let successed        = SongStatus(rawValue: 1 << 2)
    static let failed           = SongStatus(rawValue: 1 << 3)
    static let deleted          = SongStatus(rawValue: 1 << 4)
    
    static let voiceNormal      = SongStatus(rawValue: 1 << 5)
    static let voiceRecording   = SongStatus(rawValue: 1 << 6)
    static let voicePlaying     = SongStatus(rawValue: 1 << 7)
    
}

public class Song: NSManagedObject {
    
    public static var entity = setupEntityDescription()
    
    @NSManaged public var remoteId: String?
    @NSManaged public var alblumld: String?
    @NSManaged public var artlist: String?
    @NSManaged public var coverUrl: String?
    @NSManaged public var createTime: NSDate?
    @NSManaged public var duration: String?
    @NSManaged public var favorite: Int16
    @NSManaged public var name: String?
    @NSManaged public var songId: String?
    @NSManaged public var sourceUrl: String?
    
    /// 插入时调用一次
    public override func awakeFromInsert() {
        super.awakeFromInsert()
    }
    
    public static func insert(into moc: NSManagedObjectContext, alblumld: String?, artlist: String?, coverUrl: String?, createTime: NSDate?, duration: String?, favorite: Int16, name: String?, songId: String?, sourceUrl: String?) -> Song {
        
        let song: Song = moc.insertObject()
        song.alblumld = alblumld
        song.artlist = artlist
        song.coverUrl = coverUrl
        song.createTime = createTime
        song.duration = duration
        song.favorite = favorite
        song.name = name
        song.songId = songId
        song.sourceUrl = sourceUrl
        return song
    }
    
    public override func willSave() {
        super.willSave()
    }
}


extension Song: Managed {
    
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: #keyPath(name), ascending: true)]
    }
    
    public static var defaultPredicate: NSPredicate {
        return notMarkedForDeletionPredicate
    }
    
}

extension Song: DelayedDeletable {
    @NSManaged public var markedForDeletionDate: Date?
}

extension Song: RemoteDeletable {
    public var markedForRemoteDeletion: Bool {
        get {
            return false
        }
        set {
            
        }
    }
}


extension RemoteSong {
    func insert(into context: NSManagedObjectContext) -> Song? {
        return Song.insert(into: context, alblumld: alblumld, artlist: artlist, coverUrl: coverUrl, createTime: createTime, duration: duration, favorite: favorite, name: name, songId: songId, sourceUrl: sourceUrl)
    }
    func update(into context: NSManagedObjectContext) -> Song? {
        
        return nil
    }
}

extension Song: RemoteObject {}
