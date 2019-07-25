//
//  IMProcessor.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/5/4.
//

import Foundation
import JMessage

fileprivate let apsForProduction = false
typealias CompletionHandler = (Any?, Error?) -> Void
typealias LaunchOptions = [UIApplication.LaunchOptionsKey: Any]
typealias LoginInfo = (String, String)

protocol IMDelegate: JMessageDelegate { }

protocol IMMessageHandler {
    func handle<T>(_ delegate: IMDelegate, with changes:[RemoteRecordChange<T>])
    
}

protocol IMProcessor: IMDelegate {
    func initialSDK()
    func setupDelegate(with delegate: IMDelegate)
    func setupMessageHandler(with delegate: IMMessageHandler)
    func removeDelegate(with delegate: IMDelegate)
    func loginIM(with info: Any?, _ completion: @escaping CompletionHandler)
    func logoutIM(_ completion: @escaping CompletionHandler)
}

protocol JIMProcessor: IMProcessor {
    var launchOptions: LaunchOptions { get }
    func login(loginInfo: LoginInfo?, completionHandler: @escaping CompletionHandler)
}

extension JIMProcessor {
    
    func loginIM(with info: Any?,_ completion: @escaping CompletionHandler) {
        guard let info = info as? LoginInfo else { return }
        login(loginInfo: info, completionHandler: completion)
    }
    
    func logoutIM(_ completion: @escaping CompletionHandler) {
        JMSGUser.logout(completion)
    }
    
    func initialSDK() {
        JMessage.setupJMessage(launchOptions, appKey: imAppKey, channel: nil, apsForProduction: apsForProduction, category: nil, messageRoaming: false)
    }
}

final class JMessageProcessor: NSObject, JIMProcessor {
    
    var messageHandler: IMMessageHandler?
    var launchOptions: LaunchOptions
    var reformer: RemoteReformer
    
    init(launchOptions: LaunchOptions) {
        self.launchOptions = launchOptions
        self.reformer = JMessageReformer()
    }
    
    func setupMessageHandler(with delegate: IMMessageHandler) {
        messageHandler = delegate
    }
    
    func setupDelegate(with delegate: IMDelegate) {
        JMessage.add(delegate, with: nil)
    }
    
    func removeDelegate(with delegate: IMDelegate) {
        JMessage.remove(delegate, with: nil)
    }
    
    func login(loginInfo: LoginInfo?, completionHandler: @escaping CompletionHandler) {
        
        let tempCompletionHandler = { [weak self] (result: Any?, error: Error?) -> Void in
            completionHandler(result, error)
            guard let _ = error else {
                self?.registAPNs()
                return
            }
        }
        
        guard let loginInfo = loginInfo else { return }
        
        JMSGUser.login(withUsername: loginInfo.0, password: loginInfo.1, completionHandler: tempCompletionHandler)
    }
    
    /// 注册远程推送
    fileprivate func registAPNs() {
        if let version = Double(UIDevice.current.systemVersion), version >= 8.0 {
            JMessage.register(forRemoteNotificationTypes: UIUserNotificationType(rawValue: UIUserNotificationType.badge.rawValue | UIUserNotificationType.sound.rawValue | UIUserNotificationType.alert.rawValue).rawValue, categories: nil)
        }
    }
}

extension JMessageProcessor: IMDelegate {
    
    private func handleMessage(_ message: JMSGMessage) {
        messageHandler?.handle(self, with: reformer.reformData(message, type: RemoteMessage.self))
        messageHandler?.handle(self, with: reformer.reformData(message, type: RemoteReadMessage.self))
        messageHandler?.handle(self, with: reformer.reformData(message, type: RemoteApprovalMessage.self))
        messageHandler?.handle(self, with: reformer.reformData(message, type: RemoteNoticeMindMessage.self))
    }
    
    public func onReceive(_ message: JMSGMessage!, error: Error!) {
        guard let _ = error else {
            handleMessage(message)
            return
        }
    }
    
    public func onSyncOfflineMessageConversation(_ conversation: JMSGConversation!, offlineMessages: [JMSGMessage]!) {
        for message in offlineMessages {
            handleMessage(message)
        }
    }
}

