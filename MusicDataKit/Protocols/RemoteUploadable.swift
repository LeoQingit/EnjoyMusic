//
//  RemoteUploadable.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/4/29.
//

import Foundation

public protocol RemoteObject: class { }

public typealias RemoteRecordID = String

public protocol RemoteRecord {
    
}

public struct RemoteMessage: RemoteRecord {
    /// MARK: 单聊
    
    /// 接收人的id
    var chatId: String?
    /// 接收方名字
    var chatUserName: String?
    /// 发送方id
    var userId: String?
    /// 发送方名字
    var userName: String?
    /// 头像
    var headImageUrl: String?
    /// 消息Id
    var msgId: String?
    /// 远端消息Id
    var remoteId: String?
    /// 发送人Id（群消息中发送人）
    var source: String?
    /// 聊天类型: 1单聊、2群聊
    var type: Int32?
    /// 消息内容
    var content: String?
    /// 1表示文本，2表示图片，3表示语音，4表示文件，（本地：100表示时间提示,101文本提示）
    var messageType: Int32?
    /// 文件大小(图片的宽和高 宽x1000+高)
    var fileSize: Int64?
    /// 发送方Mac
    var fromMac: String?
    /// 聊天头像
    var chatHeadImageUrl: String?
    /// ???
    var timeFlag: Int?
    /// 消息生成时间戳
    var timestamp: TimeInterval?
    
    /// MARK: 群聊
    
    /// 群组id
    var groupId: String?
    /// 群组名称
    var groupName: String?
    /// @用户Id列表
    var atsUserIds: String?
    
    /// MARK: 本地备用
    var status: Int32?
    
    init(with dictionary: [String: Any]) {
        if let chatId = dictionary["chatId"] as? String {
            self.chatId = chatId
        }
        if let chatUserName = dictionary["chatUserName"] as? String {
            self.chatUserName = chatUserName
        }
        if let userId = dictionary["userId"] as? String {
            self.userId = userId
        }
        if let userName = dictionary["userName"] as? String {
            self.userName = userName
        }
        if let headImageUrl = dictionary["headImageUrl"] as? String {
            self.headImageUrl = headImageUrl
        }
        if let msgId = dictionary["msgId"] as? String {
            self.msgId = msgId
        }
        if let remoteId = dictionary["remoteId"] as? String {
            self.remoteId = remoteId
        }
        if let source = dictionary["source"] as? String {
            self.source = source
        }
        if let type = dictionary["type"] as? Int32 {
            self.type = type
        }
        if let content = dictionary["content"] as? String {
            self.content = content
        }
        if let messageType = dictionary["messageType"] as? Int32 {
            self.messageType = messageType
        }
        if let fileSize = dictionary["fileSize"] as? String {
            self.fileSize = Int64(fileSize) ?? 0
        }
        if let fromMac = dictionary["fromMac"] as? String {
            self.fromMac = fromMac
        }
        if let chatHeadImageUrl = dictionary["chatHeadImageUrl"] as? String {
            self.chatHeadImageUrl = chatHeadImageUrl
        }
        if let timeFlag = dictionary["timeFlag"] as? Int {
            self.timeFlag = timeFlag
        }
        if let timestamp = dictionary["timestamp"] as? TimeInterval {
            self.timestamp = timestamp
        }
        if let groupId = dictionary["groupId"] as? String {
            self.groupId = groupId
        }
        if let groupName = dictionary["groupName"] as? String {
            self.groupName = groupName
        }
        if let atsUserIds = dictionary["atsUserIds"] as? String {
            self.atsUserIds = atsUserIds
        }
        if let status = dictionary["status"] as? Int32 {
            self.status = status
        }
    }
}

public struct RemoteReadMessage: RemoteRecord {
    var msgId: String
    var userId: String
    var chatId: String
}

public struct RemoteNoticeMindMessage: RemoteRecord {
    var timeFlag: Int?
    var content: String?
    var timestamp: Int64?
    var type: Int32?
    var msgId: String?
    var userId: String?
    var chatId: String?
    init(with dictionary: [String: Any]) {
        if let chatId = dictionary["chatId"] as? String {
            self.chatId = chatId
        }

        if let userId = dictionary["userId"] as? String {
            self.userId = userId
        }

        if let msgId = dictionary["msgId"] as? String {
            self.msgId = msgId
        }

        if let type = dictionary["type"] as? Int32 {
            self.type = type
        }
        if let content = dictionary["content"] as? String {
            self.content = content
        }

        if let timeFlag = dictionary["timeFlag"] as? Int {
            self.timeFlag = timeFlag
        }
        if let timestamp = dictionary["timestamp"] as? Int64 {
            self.timestamp = timestamp
        }

        
    }
}

public struct RemoteApprovalMessage: RemoteRecord {
    
    var chatId: String?
    var headImageUrl: String?
    var subject: String?
    var billType: String?
    
    var type: Int32?
    var userName: String?
    var userId: String?
    var content: String?
    
    var applyId: String?
    var messageType: Int32?
    var applyResult: String?
    var timestamp: Int64?
    var timeFlag: Int?
    
    init(with dictionary: [String: Any]) {
        if let chatId = dictionary["chatId"] as? String {
            self.chatId = chatId
        }
        if let headImageUrl = dictionary["headImageUrl"] as? String {
            self.headImageUrl = headImageUrl
        }
        if let subject = dictionary["subject"] as? String {
            self.subject = subject
        }
        if let billType = dictionary["billType"] as? String {
            self.billType = billType
        }
        if let userName = dictionary["userName"] as? String {
            self.userName = userName
        }
        if let userId = dictionary["userId"] as? String {
            self.userId = userId
        }
        if let type = dictionary["type"] as? Int32 {
            self.type = type
        }
        if let content = dictionary["content"] as? String {
            self.content = content
        }
        if let messageType = dictionary["messageType"] as? Int32 {
            self.messageType = messageType
        }
        if let applyId = dictionary["applyId"] as? String {
            self.applyId = applyId
        }
        if let applyResult = dictionary["applyResult"] as? String {
            self.applyResult = applyResult
        }
        if let timeFlag = dictionary["timeFlag"] as? Int {
            self.timeFlag = timeFlag
        }
        if let timestamp = dictionary["timestamp"] as? Int64 {
            self.timestamp = timestamp
        }
    }
    
}

internal let RemoteIdentifier = "remoteId"
internal let LocalIdentifier = "msgId"

extension RemoteObject {
    public static func predicateForLocalIdentifiers(_ ids: [RemoteRecordID]) -> NSPredicate {
        return NSPredicate(format: "%K in %@", LocalIdentifier, ids)
    }
    public static func predicateForRemoteIdentifiers(_ ids: [RemoteRecordID]) -> NSPredicate {
        return NSPredicate(format: "%K in %@", RemoteIdentifier, ids)
    }
}

extension RemoteObject where Self: RemoteDeletable & DelayedDeletable {
    public static var waitingForUploadPredicate: NSPredicate {
        let notUploaded = NSPredicate(format: "%K == NULL", RemoteIdentifier)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [notUploaded, notMarkedForDeletionPredicate])
    }
}
