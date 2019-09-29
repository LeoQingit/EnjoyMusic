//
//  Song+Remote.swift
//  Music
//
//  Created by Daniel Eggert on 22/05/2015.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import WatchMusicModel
import CoreData


extension RemoteSong {
    func insert(into context: NSManagedObjectContext) -> Song? {
        let song = Song.insert(into: context, songData: songData, remoteIdentifier: id, date: date, creatorID: creatorID)
        return song
    }
}


extension Song: RemoteObject {}

