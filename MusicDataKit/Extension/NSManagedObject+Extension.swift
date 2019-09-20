//
//  NSManagedObject+Extension.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/6/10.
//

import CoreData

public extension NSManagedObject {
    
    convenience init?(usedContext: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: usedContext)!
        self.init(entity: entity, insertInto: usedContext)
    }
    
}
