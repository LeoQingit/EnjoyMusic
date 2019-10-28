//
//  MainInterfaceController.swift
//  WatchMusic Extension
//
//  Created by Leo Qin on 2019/9/23.
//  Copyright © 2019 Qin Leo. All rights reserved.
//

import WatchKit
import WatchConnectivity
import CoreAudio
import CoreData
import AVFoundation
import Foundation
import WatchMusicModel

class MainInterfaceController: WKInterfaceController {

    @IBOutlet weak var mainTable: WKInterfaceTable!
    var player: AVAudioPlayer!
    
    var managedObjectContext: NSManagedObjectContext!
    
    var session: WCSession!
    
    var concurrentQueue: DispatchQueue = DispatchQueue(label: "com.musics.www", qos: .background, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        
        let mainTitleArr = [
            "正在播放",
            "所有歌曲",
            "我喜欢"
        ]
        
        mainTable.setNumberOfRows(mainTitleArr.count, withRowType: "MainTableRowController")
        for(idx, item) in mainTitleArr.enumerated() {
            let cell = mainTable.rowController(at: idx) as! MainTableRowController
            cell.titleLabel.setText(item)
        }
        
        
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}


extension MainInterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print(message)
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        
//        concurrentQueue.async { [unowned self] in
            do {
                /// 切换到子线程操作
                let sourceData = try Data(contentsOf: file.fileURL)
                
                if let enumerator = FileManager.default.enumerator(at: URL.library.appendingPathComponent("Musics"), includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles, errorHandler: nil) {
                    for case let fileURL as URL in enumerator {
                        let resourceValues = try fileURL.resourceValues(forKeys: Set<URLResourceKey>(arrayLiteral: .isDirectoryKey))
                        guard let isDirectory = resourceValues.isDirectory else { continue }
                        if !isDirectory {
                            let localData = try Data(contentsOf: fileURL)
                            guard localData != sourceData else {
                                return
                            }
                        }
                    }
                }
                
                let fromPath = file.fileURL
                
                if !FileManager.default.fileExists(atPath: URL.library.appendingPathComponent("Musics").path) {
                    try FileManager.default.createDirectory(at: URL.library.appendingPathComponent("Musics", isDirectory: true), withIntermediateDirectories: true, attributes: nil)
                }
                
                let toPath = URL.library.appendingPathComponent("Musics").appendingPathComponent(file.fileURL.lastPathComponent)
                
                try FileManager.default.moveItem(at: fromPath, to: toPath)
                
                let asset = AVURLAsset(url: toPath)
                
                var commonDic: [AVMetadataKey: Any] = [:]
                for format in asset.availableMetadataFormats {
                    let metaItems = asset.metadata(forFormat: format)
                    for item in metaItems where item.commonKey != nil {
                        commonDic[item.commonKey!] = item.value
                    }
                }
                
                self.managedObjectContext.performChanges {[unowned self] in
                    let _ = Song.insert(into: self.managedObjectContext, songURL: toPath.lastPathComponent, infoMap: commonDic)
                }
            } catch {
//                fatalError(error.localizedDescription)
            }
//        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        if rowIndex == 1 {
            pushController(withName: "AllSongsInterfaceController", context: managedObjectContext)
        }
    }
    
    
}
