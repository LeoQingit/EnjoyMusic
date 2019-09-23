//
//  RemoteObject.swift
//  Music
//

import CoreData
import CoreLocation

public protocol RemoteObject: class {
}

public typealias RemoteRecordID = String

public protocol RemoteRecord {}

public struct RemoteSong: RemoteRecord {
    public var id: RemoteRecordID?
    public var creatorID: RemoteRecordID?
    public var date: Date
    public var songURL: String?

    public init(id: RemoteRecordID?, creatorID: RemoteRecordID?, date: Date, songURL: String?) {
        self.id = id
        self.creatorID = creatorID
        self.date = date
        self.songURL = songURL
    }
}


internal let RemoteIdentifierKey = "remoteIdentifier"

extension RemoteObject {

    public static func predicateForRemoteIdentifiers(_ ids: [RemoteRecordID]) -> NSPredicate {
        return NSPredicate(format: "%K in %@", RemoteIdentifierKey, ids)
    }

}


extension RemoteObject where Self: RemoteDeletable & DelayedDeletable {

    public static var waitingForUploadPredicate: NSPredicate {
        let notUploaded = NSPredicate(format: "%K == NULL", RemoteIdentifierKey)
        return NSCompoundPredicate(andPredicateWithSubpredicates:[notUploaded, notMarkedForDeletionPredicate])
    }

}

