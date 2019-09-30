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
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print(file)
        
        do {
            let data = try Data(contentsOf: file.fileURL)

            managedObjectContext.performChanges {[unowned self] in
                let _ = Song.insert(into: self.managedObjectContext, songName: file.fileURL.lastPathComponent, songData: data)
            }
            
        } catch {
            
        }
        
        
    }
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        print(messageData)
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        if rowIndex == 1 {
            pushController(withName: "AllSongsInterfaceController", context: managedObjectContext)
        }
    }
    
    
}
