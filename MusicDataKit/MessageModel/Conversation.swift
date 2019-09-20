//
//  Conversation.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/6/3.
//

import CoreData

//struct AlbumStatus: OptionSet {
//    let rawValue: Int32
//    
//    static let common       = AlbumStatus(rawValue: 1 << 0)
//    static let topChat      = AlbumStatus(rawValue: 1 << 1)
//    static let deleted      = AlbumStatus(rawValue: 1 << 2)
//    static let interruption = AlbumStatus(rawValue: 1 << 3)
//}
//
//public class Conversation: NSManagedObject {
//    public static var entity = setupEntityDescription()
//    @NSManaged public var avatar: String?
//    @NSManaged public var chatId: String?
//    @NSManaged public var lastMessageContent: String?
//    @NSManaged public var lastMessageTime: TimeInterval
//    @NSManaged public var name: String?
//    @NSManaged public var status: Int32
//    /// 聊天类型 1单聊 2群聊
//    @NSManaged public var type: Int32
//    @NSManaged public var unreadNum: Int32
//    @NSManaged public var messages: Set<Song>?
//    @NSManaged private(set) var group: Group?
//    var conversationStatus: ConversationStatus {
//        get {
//            return ConversationStatus(rawValue: status)
//        }
//        
//        set {
//            status = conversationStatus.rawValue
//        }
//    }
//    
//    static func findOrCreate(with message: Message, in context: NSManagedObjectContext) -> Conversation? {
//        
//        switch message.messageCategory {
//        case .single:
//            guard let chatID = message.userId else { return nil }
//            let predicate = Conversation.predicate(format: "%K == %@", #keyPath(chatId), chatID)
//            let conversation = findOrCreate(in: context, matching: predicate, configure: { newConversation in
//                newConversation.chatId = chatID
//                newConversation.type = message.type
//                
//                if message.userId != context.userID {
//                    newConversation.avatar = message.headImageUrl
//                    newConversation.name = message.userName
//                } else if message.chatId != context.userID {
//                    newConversation.name = message.chatUserName
//                } else {
//                    newConversation.avatar = message.headImageUrl
//                    newConversation.name = "Unknown"
//                }
//                
//                let groupPredicate = Group.predicate(format: "%K == %@", #keyPath(Group.groupId), chatID)
//                newConversation.group = Group.findOrFetch(in: context, matching: groupPredicate)
//            })
//            
//            update(conversation: conversation, with: message)
//            return conversation
//        case .group:
//            guard let chatID = message.groupId else { return nil }
//            let predicate = Conversation.predicate(format: "%K == %@", #keyPath(chatId), chatID)
//            let conversation = findOrCreate(in: context, matching: predicate, configure: { newConversation in
//                newConversation.chatId = chatID
//                newConversation.type = message.type
//                newConversation.name = message.groupName
//                
//                let groupPredicate = Group.predicate(format: "%K == %@", #keyPath(Group.groupId), chatID)
//                newConversation.group = Group.findOrFetch(in: context, matching: groupPredicate)
//            })
//            
//            update(conversation: conversation, with: message)
//            return conversation
//        default:
//            return nil
//        }
//    }
//    
//    fileprivate static func update(conversation: Conversation, with message: Message) {
//        if conversation.lastMessageTime < message.timestamp {
//            conversation.lastMessageTime = message.timestamp
//            conversation.lastMessageContent = message.content
//        }
//    }
//}
//
//fileprivate let lastMessageTimeKey = "lastMessageTime"
//
//extension Conversation: Managed {
//    public static var defaultSortDescriptors: [NSSortDescriptor] { return [NSSortDescriptor(key: lastMessageTimeKey, ascending: false)] }
//    public static var defaultPredicate: NSPredicate { return notMarkedForLocalDeletionPredicate }
//}
//
//extension Conversation: DelayedDeletable {
//    @NSManaged public var markedForDeletionDate: Date?
//}
//
//extension Conversation: RemoteDeletable {
//    public var markedForRemoteDeletion: Bool {
//        get {
//            return status == ConversationStatus.deleted.rawValue
//        }
//        set {
//            if newValue {
//                status = ConversationStatus.deleted.rawValue
//            }
//        }
//    }
//}
//
//
