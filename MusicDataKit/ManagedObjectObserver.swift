//
//  ManagedObjectObserver.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/4/25.
//

import Foundation
import CoreData


public final class ManagedObjectObserver {
    public enum ChangeType {
        case delete
        case update
    }
    
    public enum ChangeValueType<T: Managed> {
        case delete([T])
        case deleteAll
        case update([T])
        case insert([T])
    }
    
    public init?(object: Managed, changeHandler: @escaping (ChangeType) -> ()) {
        guard let moc = object.managedObjectContext else { return nil }
        objectHasBeenDeleted = !type(of: object).defaultPredicate.evaluate(with: object)
        token = moc.addObjectsDidChangeNotificationObserver { [unowned self] note in
            guard let changeType = self.changeType(of: object, in: note) else { return }
            self.objectHasBeenDeleted = changeType == .delete
            changeHandler(changeType)
        }
    }
    
    public init?<T: Managed>(moc: NSManagedObjectContext, changeHandler: @escaping ([ChangeValueType<T>]) -> ()) {
        token = moc.addObjectsDidChangeNotificationObserver {[unowned self] (note) in
            changeHandler(self.change(in: note))
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(token as Any)
    }
    
    
    // MARK: Private
    
    fileprivate var token: NSObjectProtocol!
    fileprivate var objectHasBeenDeleted: Bool = false
    
    fileprivate func changeType(of object: Managed, in note: ObjectsDidChangeNotification) -> ChangeType? {
        let deleted = note.deletedObjects.union(note.invalidatedObjects)
        if note.invalidatedAllObjects || deleted.containsObjectIdentical(to: object) {
            return .delete
        }
        let updated = note.updatedObjects.union(note.refreshedObjects)
        if updated.containsObjectIdentical(to: object) {
            let predicate = type(of: object).defaultPredicate
            if predicate.evaluate(with: object) {
                return .update
            } else if !objectHasBeenDeleted {
                return .delete
            }
        }
        return nil
    }
    
    fileprivate func change<T: Managed>(in note: ObjectsDidChangeNotification) -> [ChangeValueType<T>] {
        
        var changeValueTypes: [ChangeValueType<T>] = []
  
        if note.invalidatedAllObjects {
            changeValueTypes.append(.deleteAll)
        } else {
            
            var updated = note.updatedObjects.union(note.refreshedObjects).compactMap({
                return $0 as? T
            })

            var deleted = note.deletedObjects.union(note.invalidatedObjects).compactMap {
                return $0 as? T
            }
            
            let predicate = T.defaultPredicate
            updated.removeAll {
                if predicate.evaluate(with: $0) {
                    return false
                } else {
                    deleted.append($0)
                    return true
                }
            }
            changeValueTypes.append(.update(updated))
            changeValueTypes.append(.delete(deleted))
        }
        return changeValueTypes
    }
}
