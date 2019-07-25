//
//  MessageRemover.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/5/15.
//

import Foundation

final class MessageRemover: ElementChangeProcessor {
    
    var elementsInProgress = InProgressTracker<Message>()
    
    var predicateForLocallyTrackedElements: NSPredicate {
        let marked = Message.markedForRemoteDeletionPredicate
        let notDeleted = Message.notMarkedForLocalDeletionPredicate
        return NSCompoundPredicate(andPredicateWithSubpredicates: [marked, notDeleted])
    }
    
    func processChangedLocalElement(_ elements: [Message], in context: ChangeProcessorContext) {
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

extension MessageRemover {
    fileprivate func processDeletedMessage(_ deletions: [Message], in context: ChangeProcessorContext) {
        let allObjects = Set(deletions)
        let localOnly = allObjects.filter { $0.remoteId == nil }
        let objectsToDeleteRemotely = allObjects.subtracting(localOnly)
        deleteLocally(localOnly, context: context)
        deleteRemotely(objectsToDeleteRemotely, context: context)
    }
    
    fileprivate func deleteLocally(_ deletions: Set<Message>, context: ChangeProcessorContext) {
        deletions.forEach { $0.markForLocalDeletion() }
    }
    
    fileprivate func deleteRemotely(_ deletions: Set<Message>, context: ChangeProcessorContext) {
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
