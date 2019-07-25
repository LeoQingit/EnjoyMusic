//
//  InProgressTracker.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/4/29.
//

import Foundation

final class InProgressTracker<O: NSManagedObject> where O: Managed {
    fileprivate var objectsInProgress = Set<O>()
    
    init() { }
    
    /// 获取新增的处理中Managed对象
    func objectsToProgress(from objects: [O]) -> [O] {
        // 新增
        let added = objects.filter{ !objectsInProgress.contains($0)}
        objectsInProgress.formUnion(added)
        return added
    }
    
    /// 移除已处理完的对象
    func markObjectsAsComplete(_ objects: [O]) {
        objectsInProgress.subtract(objects)
    }
}
