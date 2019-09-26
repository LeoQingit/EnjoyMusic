//
//  InterfaceController.swift
//  WatchMusic Extension
//
//  Created by Leo Qin on 2019/9/23.
//  Copyright © 2019 Qin Leo. All rights reserved.
//

import WatchKit
import WatchConnectivity
import CoreAudio
import AVFoundation
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var mainTable: WKInterfaceTable!
    var player: AVAudioPlayer!
    
    var session: WCSession!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        session = WCSession.default
        session.delegate = self
        session.activate()
        

        
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


extension InterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print(file)
        let avSession = AVAudioSession.sharedInstance()
        
        
        do {
            let data = try Data.init(contentsOf: file.fileURL)
            try avSession.setCategory(AVAudioSession.Category.playback, mode: .default, policy: .longForm, options: [])
            player = try AVAudioPlayer(data: data)
            avSession.activate(options: []) { (success, error) in
                // Check for an error and play audio.
                
                
                self.player.play()
            }
            
        } catch {
            
        }
        
        
    }
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        print(messageData)
    }
    
    
}
