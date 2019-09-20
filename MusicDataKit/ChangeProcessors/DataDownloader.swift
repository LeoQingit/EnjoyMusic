//
//  DataDownloader.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/5/14.
//

import CoreData

final class DataDownloader: ChangeProcessor {
    
    func setup(for context: ChangeProcessorContext) {

    }
    
    func entityAndPredicateForLocallyTrackedObject(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>? {
        return nil
    }
    
    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext) {
        // no-op
    }
    
    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> ()) {
        
    }
    
    func fetchLatestRemoteRecords(in context: ChangeProcessorContext) {
        context.remote.fetchLatestMessage { (remoteMessages) in
            context.perform {
                self.insert(remoteMessages, into: context.context)
                context.delayedSaveOrRollback()
            }
        }
    }
}

extension DataDownloader {
    fileprivate func deleteMessages(with ids: [RemoteRecordID], in context: NSManagedObjectContext) {
        guard !ids.isEmpty else { return }
        let songs = Song.fetch(in: context) { request in
            request.predicate = Song.predicateForRemoteIdentifiers(ids)
            request.returnsObjectsAsFaults = false
        }
        songs.forEach{ $0.markForLocalDeletion() }
    }
    
    fileprivate func deleteMessages<T>(with ids: [RemoteRecordID], type: T.Type, in context: NSManagedObjectContext) {
        guard !ids.isEmpty else { return }
        let songs = Song.fetch(in: context) { request in
            request.predicate = Song.predicateForRemoteIdentifiers(ids)
            request.returnsObjectsAsFaults = false
        }
        songs.forEach{ $0.markForLocalDeletion() }
    }
    
    fileprivate func insert(_ remoteMessages: [RemoteSong], into context: NSManagedObjectContext) {
        
        let existingMessage = { ()-> [RemoteRecordID: Song] in
            let ids = remoteMessages.map { $0.songId }.compactMap { $0 }
            let rids = remoteMessages.map { $0.remoteId }.compactMap { $0 }
            let songs = Song.fetch(in: context) { request in
                request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [Song.predicateForLocalIdentifiers(ids), Song.predicateForRemoteIdentifiers(rids)])
                request.returnsObjectsAsFaults = false
            }
            
            var result: [RemoteRecordID: Song] = [:]
            for song in songs {
                if let remoteId = song.remoteId {
                    result[remoteId] = song
                } else if let songId = song.songId {
                    result[songId] = song
                }
            }
            return result
        }()
        
        for remoteMessage in remoteMessages {
            guard let id = remoteMessage.songId ?? remoteMessage.remoteId else { continue }
            guard existingMessage[id] == nil else {
//                existingMessage[id]?.updateRemoteId(id)
                continue
            }
            let _ = remoteMessage.insert(into: context)
        }

    }
    
    fileprivate func update(_ remoteMessages: [RemoteSong], into context: NSManagedObjectContext) {

    }
}
