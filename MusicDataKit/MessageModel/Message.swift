//
//  Message.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/4/26.
//

import CoreData

struct MessageAction: OptionSet {
    let rawValue: Int32
    static let chat    = MessageAction(rawValue: 1 << 0)
    static let kick     = MessageAction(rawValue: 1 << 1)
    static let approve     = MessageAction(rawValue: 1 << 2)
    static let announcement     = MessageAction(rawValue: 1 << 3)
    static let read     = MessageAction(rawValue: 1 << 4)
}

struct MessageCategory: OptionSet {
    let rawValue: Int32
    static let single    = MessageCategory(rawValue: 1 << 0)
    static let group     = MessageCategory(rawValue: 1 << 1)
}

struct MessageContentType: OptionSet {
    let rawValue: Int32
    static let text    = MessageContentType(rawValue: 1 << 0)
    static let picture     = MessageContentType(rawValue: 1 << 1)
    static let voice     = MessageContentType(rawValue: 1 << 2 - 1)
    static let file     = MessageContentType(rawValue: 1 << 2)
}

fileprivate var maxMessageWidth = UIScreen.main.bounds.size.width * 0.58
fileprivate var fileMessageWidth: CGFloat = UIScreen.main.bounds.size.width * 2 / 3
fileprivate var maxMessageWidth_image = UIScreen.main.bounds.size.width * 0.4
fileprivate var minMessageWidth_image = UIScreen.main.bounds.size.width * 0.25
fileprivate var maxMessageHeight_image = UIScreen.main.bounds.size.height * 0.5
fileprivate var minMessageHeight_image = avatar_length + 5

fileprivate let containerLbl = { () -> UILabel in
    let lbl = UILabel()
    lbl.font = UIFont.systemFont(ofSize: 16)
    lbl.numberOfLines = 0
    return lbl
}()


struct MessageStatus: OptionSet {
    let rawValue: Int32
    
    static let common           = MessageStatus(rawValue: 1 << 0)
    static let draft            = MessageStatus(rawValue: 1 << 1)
    static let successed        = MessageStatus(rawValue: 1 << 2)
    static let failed           = MessageStatus(rawValue: 1 << 3)
    static let deleted          = MessageStatus(rawValue: 1 << 4)
    
    static let voiceNormal      = MessageStatus(rawValue: 1 << 5)
    static let voiceRecording   = MessageStatus(rawValue: 1 << 6)
    static let voicePlaying     = MessageStatus(rawValue: 1 << 7)

}

/// MARK: 消息发送时带上自己头像，
public class Message: NSManagedObject {
    
    public static var entity = setupEntityDescription()
    /// 本地消息id
    @NSManaged public var msgId: String?
    /// 远端消息id
    @NSManaged public var remoteId: RemoteRecordID?
    /// at他人
    @NSManaged public var atsUserIds: String?
    /// 接收人id
    @NSManaged public var chatId: String?
    /// 接收人名字
    @NSManaged public var chatUserName: String?
    /// 发送人id
    @NSManaged public var userId: String?
    /// 发送人名字
    @NSManaged public var userName: String?
    /// 发送的内容(文件是文件的下载地址或者本地路径,图片是图片的下载地址或者图片本地路径)
    @NSManaged public var content: String?
    /// 头像url
    @NSManaged public var headImageUrl: String?
    /// 文件大小(图片的宽和高 宽x1000+高)
    @NSManaged public var fileSize: Int64
    /// 群组id
    @NSManaged public var groupId: String?
    /// 群组名字
    @NSManaged public var groupName: String?
    /// 消息时间戳
    @NSManaged public var timestamp: TimeInterval
    /// 是否显示时间戳
    @NSManaged public var showTime: Bool
    /// 消息来源人id
    @NSManaged public var source: String?
    /// 消息来源 Mac
    @NSManaged public var fromMac: String?
    /// 消息会话
    @NSManaged fileprivate(set) var conversation: Conversation?
    /// 消息发送状态
    @NSManaged fileprivate(set) var status: Int32
    /// 1单聊 2群聊
    @NSManaged fileprivate(set) var type: Int32
    /// 消息类型
    @NSManaged fileprivate(set) var messageType: Int32
    
    
    /// MARK: - 非存储变量
    
    var messageCategory: MessageCategory {
        get {
            return MessageCategory(rawValue: type)
        }
        set {
            type = messageCategory.rawValue
        }
    }
    var messageContentType: MessageContentType {
        get {
            return MessageContentType(rawValue: messageType)
        }
        set {
            messageType = messageContentType.rawValue
        }
    }
    var messageStatus: MessageStatus {
        get {
            return MessageStatus(rawValue: status)
        }
        set {
            status = messageStatus.rawValue
        }
    }
    
    var isSentByUser: Bool {
        return source == self.managedObjectContext?.userID
    }
    
    var showName: Bool {
        return messageCategory == .group
    }
    
    lazy var messageFrame = { () -> MessageFrame in
        var eFrame = MessageFrame(height: 0, contentSize: CGSize.zero)
        switch self.messageContentType {
        case .text:
            eFrame.height = 20 + (self.showTime ? 30 : 0) + (self.showName ? 17 : 0) + 20
            containerLbl.attributedText = self.content?.transToMessageString
            eFrame.contentSize = containerLbl.sizeThatFits(CGSize(width: maxMessageWidth, height: CGFloat(MAXFLOAT)))
            eFrame.height += eFrame.contentSize.height
        case .picture:
            eFrame.height = 20 + (self.showTime ? 30 : 0) + (self.showName ? 17 : 0)
            let imageW = self.fileSize / 10000
            let imageH = self.fileSize - imageW * 10000
            let imageSize = CGSize(width: CGFloat(imageW), height: CGFloat(imageH))
            if imageSize == CGSize.zero {
                eFrame.contentSize = CGSize(width: 100, height: 100)
            } else {
                let maxHeight = maxMessageWidth_image * imageSize.height / imageSize.width

                if maxHeight < minMessageHeight_image {
                    eFrame.contentSize = CGSize(width: maxMessageWidth_image, height: minMessageHeight_image)
                } else if maxHeight > maxMessageHeight_image {
                    eFrame.contentSize = CGSize(width: maxMessageWidth_image, height: maxMessageHeight_image)
                } else {
                    eFrame.contentSize = CGSize(width: maxMessageWidth_image, height: maxHeight)
                }
            }

            eFrame.height += max(41, eFrame.contentSize.height)
        case .voice:
            let width: CGFloat = 60 + 0.5 * (maxMessageWidth - 60)
            let height: CGFloat = 40
            eFrame.contentSize = CGSize(width: width, height: height)
            eFrame.height = height + (self.showTime ? 30 : 0) + (self.showName ? 17 : 0) + 20
        case .file:
            let width: CGFloat = fileMessageWidth
            var fileNameStr = content
            if let content = content, content.contains("/") {
                fileNameStr = content.components(separatedBy: "/").last
            }
            containerLbl.text = fileNameStr
            let height: CGFloat = min(max(containerLbl.sizeThatFits(CGSize(width: fileMessageWidth - 80, height: CGFloat(MAXFLOAT))).height, 24.5), 39.5) + 40
            eFrame.contentSize = CGSize(width: width, height: height)
            eFrame.height = height + (self.showTime ? 30 : 0) + (self.showName ? 17 : 0) + 20
        default: break
        }
        return eFrame
    }()
    
    func setVoiceStatus(_ newMember: MessageStatus) {
        guard (newMember == .voiceNormal || newMember == .voicePlaying || newMember == .voiceRecording) && !messageStatus.contains(newMember) else { return }
        let unionStatus = MessageStatus(arrayLiteral: .voiceNormal, .voicePlaying, .voiceRecording)
        var remainStatus = unionStatus
        remainStatus.remove(newMember)
        var msgStatus = messageStatus
        msgStatus.remove(remainStatus)
        messageStatus = msgStatus.union(newMember)
    }

    /// 插入时调用一次
    public override func awakeFromInsert() {
        super.awakeFromInsert()
    }
    
    public static func insert(into moc: NSManagedObjectContext, msgId: String?, remoteId: String?, atsUserIds: String?, chatId: String?, chatUserName: String?, userId: String?, userName: String?, content: String?, headImageUrl: String?, fileSize: Int64?, groupId: String?, groupName: String?, timestamp: TimeInterval?, source: String?, fromMac: String?, status: Int32?, type: Int32?, messageType: Int32?) -> Message {
        
        let message: Message = moc.insertObject()
        message.msgId = msgId
        message.remoteId = remoteId
        message.atsUserIds = atsUserIds
        message.chatId = chatId
        message.chatUserName = chatUserName
        message.userId = userId
        message.userName = userName
        message.content = content
        message.headImageUrl = headImageUrl
        message.fileSize = fileSize ?? 0
        message.groupId = groupId
        message.groupName = groupName
        message.timestamp = timestamp ?? 0
        message.source = source
        message.fromMac = fromMac
        message.status = status ?? 0
        message.type = type ?? 0
        message.messageType = messageType ?? 0
        message.conversation = Conversation.findOrCreate(with: message, in: moc)
        return message
    }
    
    public override func willSave() {
        super.willSave()
    }
}

extension Message {
    public func replace(with remoteMessage: RemoteMessage) {

        msgId = remoteMessage.msgId
        /// at他人
        atsUserIds = remoteMessage.atsUserIds
        /// 接收人id
        chatId = remoteMessage.chatId
        /// 发送人id
        userId = remoteMessage.userId
        /// 发送人名字
        userName = remoteMessage.userName
        /// 发送的内容(文件是文件的下载地址或者本地路径,图片是图片的下载地址或者图片本地路径)
        content = remoteMessage.content
        /// 发送人头像url
        headImageUrl = remoteMessage.headImageUrl
        /// 文件大小(图片的宽和高 宽x1000+高)
        if let rFileSize = remoteMessage.fileSize {
            fileSize = Int64(rFileSize)
        }
        /// 群组id
        groupId = remoteMessage.groupId
        /// 群组名字
        groupName = remoteMessage.groupName
        /// 消息时间戳
        if let rTimestamp = remoteMessage.timestamp {
            timestamp = rTimestamp
        }
        /// 消息来源人id
        source = remoteMessage.source

        /// 消息发送状态
        if let rStatus = remoteMessage.status {
            status = Int32(rStatus)
        }
        
        /// 1单聊 2群聊
        if let rType = remoteMessage.type {
            type = Int32(rType)
        }
        /// 消息类型
        if let rMessageType = remoteMessage.messageType {
            messageType = Int32(rMessageType)
        }
    }
    public func updateRemoteId(_ remoteId: RemoteRecordID) {
        self.remoteId = remoteId
    }
}

extension Message: Managed {
    
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: #keyPath(timestamp), ascending: true)]
    }
    
    public static var defaultPredicate: NSPredicate {
        return notMarkedForDeletionPredicate
    }

}

extension Message: DelayedDeletable {
    @NSManaged public var markedForDeletionDate: Date?
}

extension Message: RemoteDeletable {
    public var markedForRemoteDeletion: Bool {
        get {
            return status == MessageStatus.deleted.rawValue
        }
        set {
            if newValue {
                status = MessageStatus.deleted.rawValue
            }
        }
    }
}

extension Message: DisplayableManaged {
    var avatarURL_: String? {
        return headImageUrl
    }
    
    var title_: String? {
        return nil
    }
    
    var subTitle_: String? {
        return nil
    }
    
    var content_: String? {
        return content
    }
    
    var subContent_: String? {
        return nil
    }
}
