//
//  IMRemote.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/4/28.
//

import Foundation

enum RemoteRecordChange<T: RemoteRecord> {
    case insert(T)
    case update(T)
    case delete(T.Type, RemoteRecordID)
}

protocol MessageRemote {
    /// 登陆
    func setupMessageSubscription(_ handleBlock: (()->())?)
    /// 获取远端的消息
    func fetchLatestMessage(completion: @escaping ([RemoteMessage]) -> ())
    /// 上传数据
    func uploadMessage(_ messages: [Message], completion: @escaping ([RemoteMessage], Error?) -> ())
    /// 删除数据
    func removeMessage(_ messages: [Message], completion: @escaping ([RemoteRecordID], Error?) -> ())
}
