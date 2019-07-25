//
//  RemoteDeletable.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/5/8.
//

import Foundation

fileprivate let StatusKey = "status"

/// 删除采用二步删除法
public protocol RemoteDeletable: class {
    var changedForRemoteDeletion: Bool { get }
    var markedForRemoteDeletion: Bool { get set }
    func markForRemoteDeletion()
}

extension RemoteDeletable {
    /// 未被标记为删除Predicate
    public static var notMarkedForRemoteDeletionPredicate: NSPredicate {
        return NSPredicate(format: "%K <> \(MessageStatus.deleted.rawValue)", StatusKey)
    }
    
    /// 被标记为删除Predicate
    public static var markedForRemoteDeletionPredicate: NSPredicate {
        return NSCompoundPredicate(notPredicateWithSubpredicate: notMarkedForRemoteDeletionPredicate)
    }
    
    
    public func markForRemoteDeletion() {
        markedForRemoteDeletion = true
    }
}

extension RemoteDeletable where Self: NSManagedObject {
    public var changedForRemoteDeletion: Bool {
        return changedValue(forKey: StatusKey) as? Int32 == MessageStatus.deleted.rawValue
    }
}


extension RemoteDeletable where Self: DelayedDeletable {
    // 根据key值判断未被标记为本地删除或者远端删除
    public static var notMarkedForDeletionPredicate: NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [notMarkedForLocalDeletionPredicate, notMarkedForRemoteDeletionPredicate])
    }
}
