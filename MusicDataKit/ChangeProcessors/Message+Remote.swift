//
//  Message+Remote.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/5/14.
//

import Foundation

extension RemoteMessage {
     func insert(into context: NSManagedObjectContext) -> Message? {
        return Message.insert(into: context, msgId: msgId, remoteId: remoteId, atsUserIds: atsUserIds, chatId: chatId, chatUserName: chatUserName, userId: userId, userName: userName, content: content, headImageUrl: headImageUrl, fileSize: fileSize, groupId: groupId, groupName: groupName, timestamp: timestamp, source: source, fromMac: fromMac, status: status, type: type, messageType: messageType)
    }
    func update(into context: NSManagedObjectContext) -> Message? {
        
        return nil
    }
}

extension Message: RemoteObject {}
