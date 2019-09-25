//
//  MusicScannerTool.swift
//  Music
//
//  Created by Leo Qin on 2019/9/23.
//  Copyright © 2019 Qin Leo. All rights reserved.
//

import Foundation

class MusicScannerTool {
    static let shared: MusicScannerTool =  MusicScannerTool()
    
    var quryQueue = DispatchQueue(label: "com.scanner.www", qos: .default, attributes: .concurrent, autoreleaseFrequency: .never, target: nil)
    
    func scanMusicPath(completion: @escaping (URL?)->()) {
        quryQueue.async {
            
            let manager = FileManager.default
            do {
                
                let filePaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                
                if let documentDir = filePaths.first {
                    let filelist = try manager.contentsOfDirectory(atPath: documentDir)
                    for item in filelist {
                        completion(URL(string: documentDir)?.appendingPathComponent(item))
                    }
                }
                
            } catch {
                print(error)
            }
            
        }
    }
    
}
