//
//  SongRemover.swift
//  Music
//
//  Created by Daniel Eggert on 23/08/2015.
//  Copyright © 2015 objc.io. All rights reserved.
//

import CoreData
import WatchMusicModel


final class SongRemover: ElementChangeProcessor {

    var elementsInProgress = InProgressTracker<Song>()

    func setup(for context: ChangeProcessorContext) {
        // no-op
    }

    func processChangedLocalElements(_ objects: [Song], in context: ChangeProcessorContext) {
        processDeletedSongs(objects, in: context)
    }

    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> ()) {
        // no-op
        completion()
    }

    func fetchLatestRemoteRecords(in context: ChangeProcessorContext) {
        // no-op
    }

    var predicateForLocallyTrackedElements: NSPredicate {
        let marked = Song.markedForRemoteDeletionPredicate
        let notDeleted = Song.notMarkedForLocalDeletionPredicate
        return NSCompoundPredicate(andPredicateWithSubpredicates:[marked, notDeleted])
    }
}


extension SongRemover {

    fileprivate func processDeletedSongs(_ deletions: [Song], in context: ChangeProcessorContext) {
        let allObjects = Set(deletions)
        let localOnly = allObjects.filter { $0.remoteIdentifier == nil }
        let objectsToDeleteRemotely = allObjects.subtracting(localOnly)
        deleteLocally(localOnly, context: context)
        deleteRemotely(objectsToDeleteRemotely, context: context)
    }

    fileprivate func deleteLocally(_ deletions: Set<Song>, context: ChangeProcessorContext) {
        deletions.forEach { $0.markForLocalDeletion() }
    }

    fileprivate func deleteRemotely(_ deletions: Set<Song>, context: ChangeProcessorContext) {
        context.remote.remove(Array(deletions), completion: context.perform { deletedRecordIDs, error in
            var deletedIDs = Set(deletedRecordIDs)
            if case .permanent(let ids)? = error {
                deletedIDs.formUnion(ids)
            }

            let toBeDeleted = deletions.filter { deletedIDs.contains($0.remoteIdentifier ?? "") }
            self.deleteLocally(toBeDeleted, context: context)
            // This will retry failures with non-permanent failures:
            self.didComplete(Array(deletions), in: context)
            context.delayedSaveOrRollback()
        })
    }

}

