//
//  UserOwnable.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/5/16.
//

import CoreData

public protocol UserOwnable: class {
    var creatorID: String? { get }
    var belongsToCurrentUser: Bool { get }
    static func predicateForOwnedByUser(withIdentifier identifier: String?) -> NSPredicate
}

private let CreatorIDKey = "creatorID"

extension UserOwnable {
    public static func predicateForOwnedByUser(withIdentifier identifier: String?) -> NSPredicate {
        let noIDPredicate = NSPredicate(format: "%K = NULL", CreatorIDKey)
        guard let id = identifier else { return noIDPredicate }
        
        let idPredicate = NSPredicate(format: "%K = %@", CreatorIDKey, id)
        return NSCompoundPredicate(orPredicateWithSubpredicates: [noIDPredicate, idPredicate])
    }
}

extension UserOwnable where Self: NSManagedObject {
    public var belongsToCurrentUser: Bool {
        return type(of: self).predicateForOwnedByUser(withIdentifier: managedObjectContext?.userID).evaluate(with: self)
    }
}

private let UserIDKey = "io.Message.UserID"

extension NSManagedObjectContext {
    public var userID: RemoteRecordID? {
        get {
            return metaData[UserIDKey] as? RemoteRecordID
        }
        set {
            guard newValue != userID else { return }
            setMetaData(object: newValue.map { $0 as NSString }, forKey: UserIDKey)
        }
    }
}
