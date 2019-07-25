//
//  MessageDownloader.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/5/14.
//

import Foundation

final class MessageDownloader: ChangeProcessor {
    
    func setup(for context: ChangeProcessorContext) {
        context.remote.setupMessageSubscription {
            context.context.userID = UserManager.shared.getUserInfo()?.userId
        }
    }
    
    func entityAndPredicateForLocallyTrackedObject(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>? {
        return nil
    }
    
    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext) {
        // no-op
    }
    
    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> ()) {
        
        
        var createMessages: [T] = []
        var deletionIDs: [RemoteRecordID] = []
        var updateMessages: [T] = []
        
        var createRemoteMessages: [RemoteMessage] = []
        var deletionRemoteMessageIDs: [RemoteRecordID] = []
        var updateRemoteMessages: [RemoteMessage] = []
        
        var createRemoteReadMessages: [RemoteReadMessage] = []
        var deletionRemoteReadMessageIDs: [RemoteRecordID] = []
        var updateRemoteReadMessages: [RemoteReadMessage] = []
        
        var createRemoteApprovalMessages: [RemoteApprovalMessage] = []
        var deletionRemoteApprovalMessageIDs: [RemoteRecordID] = []
        var updateRemoteApprovalMessages: [RemoteApprovalMessage] = []
        
        var createRemoteNoticeMindMessages: [RemoteNoticeMindMessage] = []
        var deletionRemoteNoticeMindMessageIDs: [RemoteRecordID] = []
        var updateRemoteNoticeMindMessages: [RemoteNoticeMindMessage] = []
        
        for change in changes {
            switch change {
            case .insert(let r):
                switch r {
                case let message as RemoteMessage:
                    createRemoteMessages.append(message)
                case let message as RemoteReadMessage:
                    createRemoteReadMessages.append(message)
                case let message as RemoteApprovalMessage:
                    createRemoteApprovalMessages.append(message)
                case let message as RemoteNoticeMindMessage:
                    createRemoteNoticeMindMessages.append(message)
                default:
                    break
                }
            case .update(let r):
                switch r {
                case let message as RemoteMessage:
                    updateRemoteMessages.append(message)
                case let message as RemoteReadMessage:
                    updateRemoteReadMessages.append(message)
                case let message as RemoteApprovalMessage:
                    updateRemoteApprovalMessages.append(message)
                case let message as RemoteNoticeMindMessage:
                    updateRemoteNoticeMindMessages.append(message)
                default:
                    break
                }
            case .delete(let type, let id):
                switch type {
                case _ as RemoteMessage.Type:
                    deletionRemoteMessageIDs.append(id)
                case _ as RemoteReadMessage.Type:
                    deletionRemoteReadMessageIDs.append(id)
                case _ as RemoteApprovalMessage.Type:
                    deletionRemoteApprovalMessageIDs.append(id)
                case _ as RemoteNoticeMindMessage.Type:
                    deletionRemoteNoticeMindMessageIDs.append(id)
                default:
                    break
                }
            }
        }
        
        insert(createRemoteMessages, into: context.context)
        update(updateRemoteMessages, into: context.context)
        deleteMessages(with: deletionRemoteMessageIDs, in: context.context)
        
        context.delayedSaveOrRollback()
        completion()
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

extension MessageDownloader {
    fileprivate func deleteMessages(with ids: [RemoteRecordID], in context: NSManagedObjectContext) {
        guard !ids.isEmpty else { return }
        let messages = Message.fetch(in: context) { request in
            request.predicate = Message.predicateForRemoteIdentifiers(ids)
            request.returnsObjectsAsFaults = false
        }
        messages.forEach{ $0.markForLocalDeletion() }
    }
    
    fileprivate func deleteMessages<T>(with ids: [RemoteRecordID], type: T.Type, in context: NSManagedObjectContext) {
        guard !ids.isEmpty else { return }
        let messages = Message.fetch(in: context) { request in
            request.predicate = Message.predicateForRemoteIdentifiers(ids)
            request.returnsObjectsAsFaults = false
        }
        messages.forEach{ $0.markForLocalDeletion() }
    }
    
    fileprivate func insert(_ remoteMessages: [RemoteMessage], into context: NSManagedObjectContext) {
        
        let existingMessage = { ()-> [RemoteRecordID: Message] in
            let ids = remoteMessages.map { $0.msgId }.compactMap { $0 }
            let rids = remoteMessages.map { $0.remoteId }.compactMap { $0 }
            let messages = Message.fetch(in: context) { request in
                request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [Message.predicateForLocalIdentifiers(ids), Message.predicateForRemoteIdentifiers(rids)])
                request.returnsObjectsAsFaults = false
            }
            
            var result: [RemoteRecordID: Message] = [:]
            for message in messages {
                if let remoteId = message.remoteId {
                    result[remoteId] = message
                } else if let msgId = message.msgId {
                    result[msgId] = message
                }
            }
            return result
        }()
        
        for remoteMessage in remoteMessages {
            guard let id = remoteMessage.msgId ?? remoteMessage.remoteId else { continue }
            guard existingMessage[id] == nil else {
                existingMessage[id]?.updateRemoteId(id)
                continue
            }
            let _ = remoteMessage.insert(into: context)
        }

    }
    
    fileprivate func update(_ remoteMessages: [RemoteMessage], into context: NSManagedObjectContext) {

    }
}
