//
//  DataUploader.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/4/30.
//

import Foundation

final class DataUploader: ElementChangeProcessor {

    var elementsInProgress = InProgressTracker<Song>()
    /// 设置更改处理器上下文
    func setup(for context: ChangeProcessorContext) {
        
    }

    /// 本地跟踪元件谓语（消息的话用状态）
    var predicateForLocallyTrackedElements: NSPredicate {
        return Song.waitingForUploadPredicate
    }
    /// 处理本地变更元件
    func processChangedLocalElement(_ objects: [Song], in context: ChangeProcessorContext) {
        processInsertedMessage(objects, in: context)
    }
    
    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> ()) {
        completion()
    }
    
    func fetchLatestRemoteRecords(in context: ChangeProcessorContext) { }
    
}

extension DataUploader {
    fileprivate func processInsertedMessage(_ insertions: [Song], in context: ChangeProcessorContext) {
        context.remote.uploadMessage(insertions, completion:
            context.perform { remoteMessage, error in
                guard error == nil else { return }
                
//                for song in insertions {
//                    guard let remoteMessage =  remoteMessage.first(where: {
//                        song.songId == $0.songId
//                    }) else { continue }
//                }
//
                
                context.delayedSaveOrRollback()
                self.elementsInProgress.markObjectsAsComplete(insertions)
            } )
    }
}
