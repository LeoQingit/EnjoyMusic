//
//  SyncCoordinator.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/4/28.
//

import Foundation
import CoreData

public protocol MessageNotificationDrain {
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any])
    
}

public final class SyncCoordinator {
    internal typealias ApplicationDidBecomeActive = () -> ()
    /// 主上下文
    let viewContext: NSManagedObjectContext
    /// 同步队列私用上下文
    let syncContext: NSManagedObjectContext
    /// 同步队列
    let syncGroup: DispatchGroup = DispatchGroup()
    /// 远端定义接口
    let remote: MessageRemote
    
    fileprivate var observerTokens: [NSObjectProtocol] = []
    
    let changeProcessors: [ChangeProcessor]
    
    let imProcessor: IMProcessor
    
    var teardownFlag = atomic_flag()
    
    init(viewContext: NSManagedObjectContext, syncContext: NSManagedObjectContext, launchOptions: LaunchOptions) {
        
        imProcessor = JMessageProcessor(launchOptions: launchOptions)
        changeProcessors = [MessageUploader(), MessageDownloader(), MessageRemover()]
        remote = CloudRemote(imProcessor: imProcessor)
        self.viewContext = viewContext
        self.syncContext = syncContext
        setup()
    }
    
//    @available(iOS 10.0, *)
//    init(container: NSPersistentContainer, launchOptions: LaunchOptions) {
//        
//        imProcessor = JMessageProcessor(launchOptions: launchOptions)
//        changeProcessors = [MessageUploader(), MessageDownloader(), MessageRemover()]
//        remote = CloudRemote(imProcessor: imProcessor)
//        viewContext = container.viewContext
//        syncContext = container.newBackgroundContext()
//        syncContext.name = "SyncCoordinator"
////        syncContext.mergePolicy = MoodyMergePolicy(mode: .remote)
//        setup()
//    }
    
    /// 停止同步协调器必须调用该方法在正确的线程里结束监听任务
    public func tearDown() {
        guard !atomic_flag_test_and_set(&teardownFlag) else { return }
        perform {
            self.removeAllObserverTokens()
            
        }
    }
    
    deinit {
        guard atomic_flag_test_and_set(&teardownFlag) else { fatalError("deinit called without tearDown() being called.") }
    }
    
    fileprivate func setup() {
        perform {
            self.setupProcessorDelegate()
            self.setupViewContext()
            self.setupContexts()
            self.setupChangeProcessors()
            self.setupApplicationActiveNotifications()
        }
    }
    
    fileprivate func setupViewContext(with userId: String? = UserManager.shared.getUserInfo()?.userId) {
        viewContext.userID = userId
    }
    
    fileprivate func setupProcessorDelegate() {
        imProcessor.setupDelegate(with: imProcessor)
        imProcessor.setupMessageHandler(with: self)
    }
    
    fileprivate func removeProcessorDelegate() {
        imProcessor.removeDelegate(with: imProcessor)
    }
    
}

extension SyncCoordinator: IMMessageHandler {
    func handle<T>(_ delegate: IMDelegate, with changes: [RemoteRecordChange<T>]) where T : RemoteRecord {
        processRemoteChanges(changes: changes) {
            self.perform {
                self.context.delayedSaveOrRollback(group: self.syncGroup, completion: { (success) in
                    //
                })
            }
        }
    }
}

extension SyncCoordinator: MessageNotificationDrain {
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        perform {
            
        }
    }
}

extension SyncCoordinator {
    fileprivate func setupChangeProcessors() {
        for cp in self.changeProcessors {
            cp.setup(for: self)
        }
    }
}

extension SyncCoordinator {
    fileprivate func fetchRemoteDataForApplicationDidBecomeActive() {
        
        /// 拉离线+邮件+...
    }
}

extension SyncCoordinator: ApplicationActiveStateObserving {
    func applicationDidBecomeActive() {
        fetchLocallytrackedObjects()
        // 拉取后台的数据
        fetchRemoteDataForApplicationDidBecomeActive()
    }
    
    func applicationDidEnterBackground() {
        if #available(iOS 8.3, *) {
            syncContext.refreshAllObjects()
        } else {
            for registeredObject in syncContext.registeredObjects {
                syncContext.refresh(registeredObject, mergeChanges: true)
            }
        }
    }
    
    fileprivate func fetchLocallytrackedObjects() {
        self.perform {
            var objects: Set<NSManagedObject> = []
            for cp in self.changeProcessors {
                guard let entityAndPredicate = cp.entityAndPredicateForLocallyTrackedObject(in: self) else { continue }
                let request = entityAndPredicate.fetchRequest
                request.returnsObjectsAsFaults = false
                do {
                    let result = try self.syncContext.fetch(request)
                    objects.formUnion(result)
                } catch {
                    // error handle
                }
                self.processChangedLocalObject(Array(objects))
            }
        }
    }
    
    fileprivate func processRemoteChanges<T>(changes: [RemoteRecordChange<T>], completion: @escaping () -> ()) {
        self.changeProcessors.asyncForEach(completion: completion) { (changeProcessor, innerCompletion) in
            perform {
                changeProcessor.processRemoteChanges(changes, in: self, completion: innerCompletion)
            }
        }
    }

}

extension SyncCoordinator: ContextOwner {
    func removeAllObserverTokens() {
        observerTokens.removeAll()
    }
    
    func addObserverToken(_ token: NSObjectProtocol) {
        observerTokens.append(token)
    }
    
    func processChangedLocalObject(_ objects: [NSManagedObject]) {
        for cp in changeProcessors {
            cp.processChangedLocalObjects(objects, in: self)
        }
    }
}


extension SyncCoordinator: ChangeProcessorContext {
    var context: NSManagedObjectContext {
        return syncContext
    }
    
    func perform(_ block: @escaping () -> ()) {
        syncContext.perform(group: syncGroup, block: block)
    }
    
    func perform<A, B>(_ block: @escaping (A, B) -> ()) -> (A, B) -> () {
        return { (a: A, b: B) -> () in
            self.perform {
                block(a, b)
            }
        }
    }
    
    func perform<A, B, C>(_ block: @escaping (A, B, C) -> ()) -> (A, B, C) -> () {
        return { (a: A, b: B, c: C) -> () in
            self.perform {
                block(a, b, c)
            }
        }
    }
    
    func delayedSaveOrRollback() {
        context.delayedSaveOrRollback(group: syncGroup)
    }
    
}
