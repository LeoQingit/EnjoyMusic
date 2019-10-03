//
//  AllSongsInterfaceController.swift
//  WatchMusic Extension
//
//  Created by Qin Leo on 2019/9/23.
//  Copyright © 2019 Qin Leo. All rights reserved.
//

import WatchKit
import Foundation
import CoreData
import WatchMusicModel
import AVFoundation
import MediaPlayer

class AllSongsInterfaceController: WKInterfaceController {

    @IBOutlet weak var mainTable: WKInterfaceTable!
    
    let audioSession = AVAudioSession.sharedInstance()

    var managedContext: NSManagedObjectContext?
    var songs: [Song] = []
    
    // The asset player controlling playback.
    var assetPlayer: AssetPlayer!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let managedContext = context as? NSManagedObjectContext {
            self.managedContext = managedContext
            songs = Song.fetch(in: managedContext) { request in

            }
        }
        
        mainTable.setNumberOfRows(songs.count, withRowType: "SongTableRowController")
        for(idx, item) in songs.enumerated() {
            let cell = mainTable.rowController(at: idx) as! SongTableRowController
            cell.nameLabel.setText(item.name)
        }
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let song = songs[rowIndex]
        guard let songData = song.songData else { return }
        
        do {
//            try audioSession.setCategory(AVAudioSession.Category.playback, mode: .default, policy: AVAudioSession.RouteSharingPolicy.longFormAudio, options: [])
//            player = try AVAudioPlayer(data: songData)
//            audioSession.activate(options: []) { (success, error) in
//                
//                self.player.play()
//            }
            
        } catch {
            
        }
        
        pushController(withName: "MusicPlayerInterfaceController", context: nil)
        
    }
    
    func optIn(_ sender: Any?) {
        
        guard assetPlayer == nil else { return }
        
        // Create the asset player, if possible.
        
        do {
            assetPlayer = try AssetPlayer()
        }
            
            // Otherwise, display an error.
            
        catch {
        }
    }
    
    // Action method: opt out of now-playability.
    
    func optOut(_ sender: Any?) {
        
        guard assetPlayer != nil else { return }
        
        assetPlayer.optOut()
        assetPlayer = nil
    }

}
