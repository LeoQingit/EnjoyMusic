//
//  MusicScannerTool.swift
//  Music
//
//  Created by Leo Qin on 2019/9/23.
//  Copyright © 2019 Qin Leo. All rights reserved.
//

import Foundation

let kAddedToDirectoryDate = "kAddedToDirectoryDate"

class MusicScannerTool {
    static let shared: MusicScannerTool =  MusicScannerTool()
    
    var quryQueue = DispatchQueue(label: "com.scanner.www", qos: .default, attributes: .concurrent, autoreleaseFrequency: .never, target: nil)
    
    func scanMusicPath(completion: @escaping ([String])->()) {
        quryQueue.async {
            
            let manager = FileManager.default
            do {
                
                let filePaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                
                if let documentDir = filePaths.first {
                    
                    let url = URL(fileURLWithPath: documentDir)
                    let urls = try manager.contentsOfDirectory(at: url, includingPropertiesForKeys: [URLResourceKey.addedToDirectoryDateKey], options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
                    var newURLs = [URL]()
                    for item in urls {
                        let temp = try item.resourceValues(forKeys: [URLResourceKey.addedToDirectoryDateKey])
                        // 只要文件添加的时间早于上一次记录的时间就是新文件，如果没获取到那就当作新文件存入（上次访问的时间可以作为后续参考）
                        if let addedDate = temp.addedToDirectoryDate, let lastAddedDate = UserDefaults.standard.value(forKey: kAddedToDirectoryDate) as? Date {
                            if addedDate.distance(to: lastAddedDate) < 0 {
                                newURLs.append(item)
                            }
                        } else {
                            newURLs.append(item)
                        }
                    }

                    /// 设置当前时间 作为扫面的添加节点
                    if newURLs.count > 0 {
                        UserDefaults.standard.set(Date(), forKey: kAddedToDirectoryDate)
                        completion(newURLs.map{$0.lastPathComponent})
                    }
                }
            } catch {
                print(error)
            }
            
        }
    }
    
}
