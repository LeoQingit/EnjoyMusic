//
//  Group.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/6/4.
//

import CoreData

struct GroupStatus: OptionSet {
    let rawValue: Int32
    
    static let common       = GroupStatus(rawValue: 1 << 0)
    static let deleted      = GroupStatus(rawValue: 1 << 1)
}

public class Group: NSManagedObject {
    
    public static var entity = setupEntityDescription()
    
    @NSManaged public var mac: String?
    /// 群组id
    @NSManaged public var groupId: String?
    /// 群组名
    @NSManaged public var groupName: String?
    /// 群主userId
    @NSManaged public var groupOwnerId: String?
    /// 群头像
    @NSManaged public var groupFaceUrl: String?
    /// 群简介
    @NSManaged public var groupIntroduction: String?
    /// 申请加群处理方式（1需要验证/2自由加入/3禁止加群）
    @NSManaged public var groupApplyJoinOptionType: Int32
    /// 群公告
    @NSManaged public var groupNotification: String?
    /// 群组类别（1Private私密群/2Public公开群/3ChatRoom聊天室/4AVChatRoom互动直播聊天室/5BChatRoom在线成员广播大群）
    @NSManaged public var groupType: Int32
    /// 设置全员禁言（0关闭全员禁言/1打开全员禁言）
    @NSManaged public var shutUpAllMember: Int32
    /// 群最大成员数
    @NSManaged public var groupMaxMemberCount: Int32
    /// 更新时间戳
    @NSManaged public var updateTime: String?
    /// 创建时间戳
    @NSManaged public var createTime: String?

    @NSManaged fileprivate(set) var conversation: Conversation?
    
    @NSManaged fileprivate(set) var status: Int32
    
    var groupStatus: GroupStatus {
        get {
            return GroupStatus(rawValue: status)
        }
        set {
            status = groupStatus.rawValue
        }
    }
}

extension Group: Managed {
    public static var defaultPredicate: NSPredicate { return notMarkedForLocalDeletionPredicate }
}

extension Group: DelayedDeletable {
    @NSManaged public var markedForDeletionDate: Date?
}

extension Group: RemoteDeletable {
    public var markedForRemoteDeletion: Bool {
        get {
            return status == GroupStatus.deleted.rawValue
        }
        set {
            if newValue {
                status = GroupStatus.deleted.rawValue
            }
        }
    }
}
