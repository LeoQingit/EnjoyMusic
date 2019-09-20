//
//  NSManagedObject+Extensions.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/4/25.
//

import CoreData


extension NSManagedObject {
    public func refresh(_ mergeChanges: Bool = true) {
        managedObjectContext?.refresh(self, mergeChanges: mergeChanges)
    }
}


extension NSManagedObject {
    public func changedValue(forKey key: String) -> Any? {
        return changedValues()[key]
    }
    public func committedValue(forKey key: String) -> Any? {
        return committedValues(forKeys: [key])[key]
    }
    
}

