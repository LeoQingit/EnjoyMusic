//
//  EntityAndPredicate.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/4/28.
//

import CoreData

final class EntityAndPredicate<O: NSManagedObject> {
    let entity: NSEntityDescription
    let predicate: NSPredicate
    
    init(entity: NSEntityDescription, predicate: NSPredicate) {
        self.entity = entity
        self.predicate = predicate
    }
}

extension EntityAndPredicate {
    var fetchRequest: NSFetchRequest<O> {
        let request = NSFetchRequest<O>()
        request.entity = entity
        request.predicate = predicate
        return request
    }
}

extension Sequence where Iterator.Element: NSManagedObject {
    func filter(_ entityAndPredicate: EntityAndPredicate<Iterator.Element>) -> [Iterator.Element] {
        typealias MO = Iterator.Element
        let filtered = filter { (mo: MO) -> Bool in
            guard mo.entity == entityAndPredicate.entity else { return false}
            return entityAndPredicate.predicate.evaluate(with: mo)
        }
        return Array(filtered)
    }
}
