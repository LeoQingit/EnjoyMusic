//
//  SyncContextOwner.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/5/6.
//

import Foundation

/// 上下文属主协议：处理同步上下文、主上下文同步问题
protocol ContextOwner: ObserverTokenStore {
    var viewContext: NSManagedObjectContext { get }
    var syncContext: NSManagedObjectContext { get }
    var syncGroup: DispatchGroup { get }
    /// syncContext中的对象发生更改时调用
    func processChangedLocalObject(_ objects: [NSManagedObject])
}

extension ContextOwner {
    func setupContexts() {
        // 查询世代
        setupQueryGenerations()
        //设置监听
        setupContextNotificationObserving()
    }
    
    fileprivate func setupQueryGenerations() {
//        if #available(iOS 10.0, *) {
//            let token = NSQueryGenerationToken.current
//            viewContext.perform {
//                do {
//                    try? self.viewContext.setQueryGenerationFrom(token)
//                } catch {
//                    
//                }
//            }
//            syncContext.perform {
//                do {
//                    try? self.syncContext.setQueryGenerationFrom(token)
//                } catch {
//
//                }
//            }
//        } else {
//            // Fallback on earlier versions
//            // TODO: iOS8 - iOS10
//        }

    }
    
    /// 设置viewContext保存通知监听
    fileprivate func setupContextNotificationObserving() {
        addObserverToken(
            viewContext.addContextDidSaveNotificationObserver { [weak self] note in
                self?.viewContextDidSave(note)
            }
        )
        addObserverToken(
            syncContext.addContextDidSaveNotificationObserver { [weak self] note in
                self?.synContextDidSave(note)
            }
        )
        addObserverToken(
            syncContext.addObjectsDidChangeNotificationObserver { [weak self] note in
                self?.objectsInSyncContextDidChange(note)
            }
        )
    }
    
    // 合并上下文
    fileprivate func viewContextDidSave(_ note: ContextDidSaveNotification) {
        syncContext.performMergeChanges(from: note)
        notifyAboutChangedObjects(from: note)
        
    }
    fileprivate func synContextDidSave(_ note: ContextDidSaveNotification) {
        viewContext.performMergeChanges(from: note)
        notifyAboutChangedObjects(from: note)
    }
    
    // 接收同步上下文对象发生改变通知
    fileprivate func objectsInSyncContextDidChange(_ note: ObjectsDidChangeNotification) {
        // no-op
    }
    
    // 同步上下文处理更改托管对象
    fileprivate func notifyAboutChangedObjects(from notification: ContextDidSaveNotification) {
        syncContext.perform(group: syncGroup) {
            /// syncContext中notification包含的更新与插入对象
            let updates = notification.updatedObjects.remap(to: self.syncContext)
            let inserts = notification.insertedObjects.remap(to: self.syncContext)
            self.processChangedLocalObject(updates + inserts)
        }
    }
}
