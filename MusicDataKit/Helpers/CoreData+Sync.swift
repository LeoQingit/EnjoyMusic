//
//  CoreData+Sync.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/4/28.
//

import CoreData

extension NSManagedObjectContext {
    func perform(group: DispatchGroup, block: @escaping () -> ()) {
        group.enter()
        perform {
            block()
            group.leave()
        }
    }
}

extension Sequence where Iterator.Element: NSManagedObject {
    /// 目标NSManageObjectContext searchMO
    func remap(to targetContext: NSManagedObjectContext) -> [Iterator.Element] {
        return map({ unMappedMO in
            guard unMappedMO.managedObjectContext !== targetContext else { return unMappedMO }
            guard let object = targetContext.object(with: unMappedMO.objectID) as? Iterator.Element else {
                fatalError("IMCoreDataError - Invalid object type")
            }
            return object
        })
    }
}

extension NSManagedObjectContext {
    /// 上下文变更数量
    fileprivate var changedObjectsCount: Int {
        return insertedObjects.count + updatedObjects.count + deletedObjects.count
    }
    
    /// 延迟执行保存操作
    func delayedSaveOrRollback(group: DispatchGroup, completion: @escaping (Bool) -> () = { _ in }) {
        let changeCountLimit = 0
        guard changeCountLimit >= changedObjectsCount else {
            return completion(saveOrRollback())
        }
        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
        group.notify(queue: queue) {
            self.perform(group: group) {
                guard self.hasChanges else { return completion(true) }
                completion(self.saveOrRollback())
            }
        }
    }
}
