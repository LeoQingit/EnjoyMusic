//
//  ApplicationActiveStateObserver.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/5/6.
//

import Foundation

/// 监听Token
protocol ObserverTokenStore : class {
    func addObserverToken(_ token: NSObjectProtocol)
}


/// 应用进入前后台状态监听
protocol ApplicationActiveStateObserving :ObserverTokenStore {
    
    func perform(_ block: @escaping () -> ())
    /// 应用进入前台状态
    func applicationDidBecomeActive()
    /// 应用进入后台状态
    func applicationDidEnterBackground()
}

extension ApplicationActiveStateObserving {
    func setupApplicationActiveNotifications() {
        
        addObserverToken(NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] note in
            guard let observer = self else { return }
            observer.perform {
                observer.applicationDidEnterBackground()
            }
        })
        
        addObserverToken(NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] note in
            guard let observer = self else { return }
            observer.perform {
                observer.applicationDidBecomeActive()
            }
        })
        
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .active {
                self.applicationDidBecomeActive()
            }
        }
    }
}
