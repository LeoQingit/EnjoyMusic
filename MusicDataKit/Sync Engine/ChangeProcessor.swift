//
//  ChangeProcessor.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/4/28.
//

import CoreData

/// 更改处理器上下文协议
protocol ChangeProcessorContext: class {
    /// 更改处理器操作上下文：同步上下文
    var context: NSManagedObjectContext { get }
    
    var remote: DataRemote { get }
    
    /// 在同步上下文队列执行操作
    func perform (_ block: @escaping () ->())
    func perform<A, B>(_ block: @escaping (A, B) -> ()) -> (A, B) -> ()
    func perform<A, B, C>(_ block: @escaping (A, B, C) -> ()) -> (A, B, C) -> ()
    func delayedSaveOrRollback()
}

/// 更改处理器
protocol ChangeProcessor {
    /// 设置更改处理器上下文
    func setup(for context: ChangeProcessorContext)
    /// 获取更改处理器中本地跟踪的EntityAndPredicate对象-----APP启动时等待发送到远端的对象（对数据库中与更改处理器相关的对象执行获取请求，传递给processChangedLocalObjects方法处理）
    func entityAndPredicateForLocallyTrackedObject(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>?
    /// 处理本地更改对象
    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext)
    /// 处理远端过来的对象
    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> ())
    /// 获取远端离线对象
    func fetchLatestRemoteRecords(in context: ChangeProcessorContext)

}

/// 元件变更处理器
protocol ElementChangeProcessor: ChangeProcessor {
    /// 元件类型
    associatedtype Element: NSManagedObject, Managed
    /// 处理中元件跟踪器
    var elementsInProgress: InProgressTracker<Element> { get }
    /// 本地跟踪元件谓语
    var predicateForLocallyTrackedElements: NSPredicate { get }
    /// 处理本地变更元件
    func processChangedLocalElement(_ elements: [Element], in context: ChangeProcessorContext)
}

extension ElementChangeProcessor {
    /// 元件变更处理器感兴趣的EntityAndPredicate
    func entityAndPredicateForLocallyTrackedObject(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>? {
        let predicate = predicateForLocallyTrackedElements
        if #available(iOS 10.0, *) {
            print(Element.entityName)
            return EntityAndPredicate(entity: Element.entity(), predicate: predicate)
        } else {
            let entity = NSEntityDescription.entity(forEntityName: Element.entityName, in: context.context)
            return EntityAndPredicate(entity: entity!, predicate: predicate)
        }
    }
    /// 处理本地变更对象
    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext) {
        /// 获取更改处理器上下文中本地跟踪的EntityAndPredicate对象
        guard let trackedObjectAndPredicate = entityAndPredicateForLocallyTrackedObject(in: context) else { return }
        /// 筛选出更改处理器上下文中的符合谓语及类型的被跟踪的变更托管对象
        let matching = objects.filter(trackedObjectAndPredicate)
        if let elements = matching as? [Element] {
            /// 跟踪处理器添加待处理对象
            let newElements = elementsInProgress.objectsToProgress(from: elements)
            /// 处理这些对象
            processChangedLocalElement(newElements, in: context)
        }
    }
    
    func didComplete(_ elements: [Element], in context: ChangeProcessorContext) {
        /// 跟踪器移除处理完毕的被跟踪对象
        elementsInProgress.markObjectsAsComplete(elements)
        
        /// 根据本地跟踪对象谓词处理元件
        let p = predicateForLocallyTrackedElements
        let matching = elements.filter(p.evaluate(with:))
        let newElements = elementsInProgress.objectsToProgress(from: matching)
        if newElements.count > 0 {
            processChangedLocalElement(newElements, in: context)
        }
    }
}


