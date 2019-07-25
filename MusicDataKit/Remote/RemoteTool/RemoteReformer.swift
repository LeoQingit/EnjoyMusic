//
//  RemoteReformer.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/4/30.
//

import Foundation
import JMessage

protocol RemoteReformer {
    func reformData<T, O: RemoteRecord>(_ data: T, type: O.Type) -> [RemoteRecordChange<O>]
}

protocol JRemoteReformer: RemoteReformer {
    associatedtype Element: JMSGMessage
    func reformData<O>(_ data: Element, type: O.Type) -> [RemoteRecordChange<O>] where O : RemoteRecord
}

extension JRemoteReformer {
    func reformData<T, O: RemoteRecord>(_ data: T, type: O.Type) -> [RemoteRecordChange<O>] {
        guard let message = data as? Element else {
            return []
        }
        return reformData(message, type: type)
    }
    
    func reformData<O>(_ data: Element, type: O.Type) -> [RemoteRecordChange<O>] where O : RemoteRecord {
        guard let extraMessage = data.content?.extras as? [String: Any] else { return [] }
        guard let serverMessageId = data.serverMessageId else { return [] }
        
        switch type {
        case _ as RemoteReadMessage.Type:
            if let action = extraMessage["action"] as? Int, action == 5 {
                if let localMsgIds = extraMessage["msgIds"] as? [String],
                    let userId = extraMessage["userId"] as? String,
                    let chatId = extraMessage["chatId"] as? String {
                    
                    var remoteReadMessages = [RemoteRecordChange<O>]()
                    for msgId in localMsgIds  {
                        if let item = RemoteRecordChange.insert(RemoteReadMessage(msgId: msgId, userId: userId, chatId: chatId)) as? RemoteRecordChange<O> {
                            remoteReadMessages.append(item)
                        }
                    }
                    return remoteReadMessages
                }
            }
        case _ as RemoteMessage.Type:
            // 解析Message
            if let action = extraMessage["action"] as? Int, action == 0 {
                var remoteMessages = [RemoteRecordChange<O>]()
                var transExtraMessage = extraMessage
                transExtraMessage["remoteId"] = serverMessageId
                if let item = RemoteRecordChange.insert(RemoteMessage(with: transExtraMessage)) as? RemoteRecordChange<O> {
                    remoteMessages.append(item)
                }
                return remoteMessages
            }
        case _ as RemoteNoticeMindMessage.Type:
            // 解析公告消息
            if let action = extraMessage["action"] as? Int, action == 4 {
                var remoteMessages = [RemoteRecordChange<O>]()
                if let item = RemoteRecordChange.insert(RemoteNoticeMindMessage(with: extraMessage)) as? RemoteRecordChange<O> {
                    remoteMessages.append(item)
                }
                return remoteMessages
            }
        case _ as RemoteApprovalMessage.Type:
            // 解析审批消息
            if let action = extraMessage["action"] as? Int, action == 3 {
                var remoteMessages = [RemoteRecordChange<O>]()
                if let item = RemoteRecordChange.insert(RemoteApprovalMessage(with: extraMessage)) as? RemoteRecordChange<O> {
                    remoteMessages.append(item)
                }
                return remoteMessages
            }
        default:
            break
        }
        
        
        return []
    }
}
class JMessageReformer: JRemoteReformer {
    typealias Element = JMSGMessage
    
    
}
