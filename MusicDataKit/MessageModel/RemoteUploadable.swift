//
//  RemoteUploadable.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/4/29.
//

import Foundation

public protocol RemoteObject: class { }

public typealias RemoteRecordID = String

public protocol RemoteRecord {
    
}

public struct RemoteSong: RemoteRecord {
    var songId: String?
    var remoteId: String?
    var alblumld: String?
    var artlist: String?
    var coverUrl: String?
    var createTime: NSDate?
    var duration: String?
    var favorite: Int16
    var name: String?
    var sourceUrl: String?
    
}

internal let RemoteIdentifier = "remoteId"
internal let LocalIdentifier = "localId"

extension RemoteObject {
    public static func predicateForLocalIdentifiers(_ ids: [RemoteRecordID]) -> NSPredicate {
        return NSPredicate(format: "%K in %@", LocalIdentifier, ids)
    }
    public static func predicateForRemoteIdentifiers(_ ids: [RemoteRecordID]) -> NSPredicate {
        return NSPredicate(format: "%K in %@", RemoteIdentifier, ids)
    }
}

extension RemoteObject where Self: RemoteDeletable & DelayedDeletable {
    public static var waitingForUploadPredicate: NSPredicate {
        let notUploaded = NSPredicate(format: "%K == NULL", RemoteIdentifier)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [notUploaded, notMarkedForDeletionPredicate])
    }
}
