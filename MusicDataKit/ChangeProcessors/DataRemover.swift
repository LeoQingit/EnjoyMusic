//
//  DataRemover.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/5/15.
//

import Foundation

final class DataRemover: ElementChangeProcessor {
    
    var elementsInProgress = InProgressTracker<Song>()
    
    var predicateForLocallyTrackedElements: NSPredicate {
        let marked = Song.markedForRemoteDeletionPredicate
        let notDeleted = Song.notMarkedForLocalDeletionPredicate
        return NSCompoundPredicate(andPredicateWithSubpredicates: [marked, notDeleted])
    }
    
    func processChangedLocalElement(_ elements: [Song], in context: ChangeProcessorContext) {
        processDeletedMessage(elements, in: context)
    }
    
    
    func setup(for context: ChangeProcessorContext) {
        //
    }
    
    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> ()) {
        completion()
    }
    
    func fetchLatestRemoteRecords(in context: ChangeProcessorContext) {
        //
    }
    
}

extension DataRemover {
    fileprivate func processDeletedMessage(_ deletions: [Song], in context: ChangeProcessorContext) {
        let allObjects = Set(deletions)
        let localOnly = allObjects.filter { $0.remoteId == nil }
        let objectsToDeleteRemotely = allObjects.subtracting(localOnly)
        deleteLocally(localOnly, context: context)
        deleteRemotely(objectsToDeleteRemotely, context: context)
    }
    
    fileprivate func deleteLocally(_ deletions: Set<Song>, context: ChangeProcessorContext) {
        deletions.forEach { $0.markForLocalDeletion() }
    }
    
    fileprivate func deleteRemotely(_ deletions: Set<Song>, context: ChangeProcessorContext) {
        context.remote.removeMessage(Array(deletions), completion: context.perform { deletedRecordIds, error in
            let deletedIDs = Set(deletedRecordIds)
            guard error == nil else { return }
            let toBeDeleted = deletions.filter { deletedIDs.contains($0.remoteId ?? "") }
            self.deleteLocally(toBeDeleted, context: context)
            
            self.didComplete(Array(deletions), in: context)
            context.delayedSaveOrRollback()
        })
    }
}
