//
//  SongUploader.swift
//  Music
//
//  Created by Daniel Eggert on 22/05/2015.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import CoreData
import WatchMusicModel


final class SongUploader: ElementChangeProcessor {
    var elementsInProgress = InProgressTracker<Song>()

    func setup(for context: ChangeProcessorContext) {
        // no-op
    }

    func processChangedLocalElements(_ objects: [Song], in context: ChangeProcessorContext) {
        processInsertedSongs(objects, in: context)
    }

    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> ()) {
        // no-op
        completion()
    }

    func fetchLatestRemoteRecords(in context: ChangeProcessorContext) {
        // no-op
    }

    var predicateForLocallyTrackedElements: NSPredicate {
        return Song.waitingForUploadPredicate
    }
}

extension SongUploader {
    fileprivate func processInsertedSongs(_ insertions: [Song], in context: ChangeProcessorContext) {
        context.remote.upload(insertions,
            completion: context.perform { remoteSongs, error in

            guard !(error?.isPermanent ?? false) else {
                // Since the error was permanent, delete these objects:
                insertions.forEach { $0.markForLocalDeletion() }
                self.elementsInProgress.markObjectsAsComplete(insertions)
                return
            }

            for song in insertions {
                guard let remoteSong = remoteSongs.first(where: { song.date == $0.date }) else { continue }
                song.remoteIdentifier = remoteSong.id
                song.creatorID = remoteSong.creatorID
            }
            context.delayedSaveOrRollback()
            self.elementsInProgress.markObjectsAsComplete(insertions)
        })
    }
}

