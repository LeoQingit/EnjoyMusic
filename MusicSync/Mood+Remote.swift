//
//  Song+Remote.swift
//  Music
//
//  Created by Daniel Eggert on 22/05/2015.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import MusicModel
import CoreData


extension RemoteSong {
    func insert(into context: NSManagedObjectContext) -> Song? {
        let song = Song.insert(into: context, colors: colors, location: location, isoAlbum: isoAlbum, remoteIdentifier: id, date: date, creatorID: creatorID)
        return song
    }
}


extension Song: RemoteObject {}

