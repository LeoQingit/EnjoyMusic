//
//  SongDownloader.swift
//  Music
//
//  Created by Daniel Eggert on 22/05/2015.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import CoreData
import WatchMusicModel


final class SongDownloader: ChangeProcessor {
    func setup(for context: ChangeProcessorContext) {
        context.remote.setupSongSubscription()
    }

    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext) {
        // no-op
    }

    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> ()) {
        var creates: [RemoteSong] = []
        var deletionIDs: [RemoteRecordID] = []
        for change in changes {
            switch change {
            case .insert(let r) where r is RemoteSong: creates.append(r as! RemoteSong)
            case .delete(let id): deletionIDs.append(id)
            default: fatalError("change reason not implemented")
            }
        }

        insert(creates, into: context.context)
        deleteSongs(with: deletionIDs, in: context.context)
        context.delayedSaveOrRollback()
        completion()
    }

    func fetchLatestRemoteRecords(in context: ChangeProcessorContext) {
        context.remote.fetchLatestSongs { remoteSongs in
            context.perform {
                self.insert(remoteSongs, into: context.context)
                context.delayedSaveOrRollback()
            }
        }
    }

    func entityAndPredicateForLocallyTrackedObjects(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>? {
        return nil
    }

}


extension SongDownloader {

    fileprivate func deleteSongs(with ids: [RemoteRecordID], in context: NSManagedObjectContext) {
        guard !ids.isEmpty else { return }
        let songs = Song.fetch(in: context) { (request) -> () in
            request.predicate = Song.predicateForRemoteIdentifiers(ids)
            request.returnsObjectsAsFaults = false
        }
        songs.forEach { $0.markForLocalDeletion() }
    }

    fileprivate func insert(_ remoteSongs: [RemoteSong], into context: NSManagedObjectContext) {
        let existingSongs = { () -> [RemoteRecordID: Song] in
            let ids = remoteSongs.map { $0.id }.compactMap { $0 }
            let songs = Song.fetch(in: context) { request in
                request.predicate = Song.predicateForRemoteIdentifiers(ids)
                request.returnsObjectsAsFaults = false
            }
            var result: [RemoteRecordID: Song] = [:]
            for song in songs {
                result[song.remoteIdentifier!] = song
            }
            return result
        }()

        for remoteSong in remoteSongs {
            guard let id = remoteSong.id else { continue }
            guard existingSongs[id] == nil else { continue }
            let _ = remoteSong.insert(into: context)
        }
    }

}

