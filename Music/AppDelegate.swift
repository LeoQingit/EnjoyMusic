//
//  AppDelegate.swift
//  Music
//

import UIKit
import MusicSync
import MusicModel
import CoreData
import AVFoundation

private let SongNameKey = "name"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var persistentContainer: NSPersistentContainer!
    var syncCoordinator: SyncCoordinator!
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.registerForRemoteNotifications()
        
        do {
            try ConfigModel.shared = ConfigModel(nowPlayableBehavior: WatchOSNowPlayableBehavior())
        } catch {
            print(error)
        }
        
        createMusicContainer { container in
            self.persistentContainer = container
            self.syncCoordinator = SyncCoordinator(container: container)
            MusicScannerTool.shared.scanMusicPath(completion: { fileNames in
                guard !fileNames.isEmpty else { return }
                container.viewContext.performChanges {
                    for name in fileNames {
                        
                        var compareName: String
                        if let compareNameSub = name.split(separator: ".").first {
                            compareName = String(compareNameSub)
                        } else {
                            compareName = name
                        }

                        let currentCount = Song.count(in: container.viewContext) {
                            $0.predicate = NSPredicate(format: "%K = %@", SongNameKey, compareName)
                        }
                        
                        if currentCount == 0 {
                            guard let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return }
                            let url = URL(fileURLWithPath: filePath + "/" + name)
                            let asset = AVURLAsset(url: url)
                            
                            var commonDic: [AVMetadataKey: Any] = [:]
                            for format in asset.availableMetadataFormats {
                                let metaItems = asset.metadata(forFormat: format)
                                for item in metaItems where item.commonKey != nil {
                                    commonDic[item.commonKey!] = item.value
                                }
                            }
                            
                            let _ = Song.insert(into: container.viewContext, songURL: name, infoMap: commonDic)
                            
                        }
                    }
                }
            })
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let navigationVC = storyboard.instantiateViewController(withIdentifier: "ItemScene") as? UINavigationController else { fatalError("Wrong view controller type") }
            guard let vc = navigationVC.topViewController as? SongsTableViewController else
                { fatalError("Wrong view controller type") }
            vc.managedObjectContext = container.viewContext
            self.window?.rootViewController = navigationVC
        }
        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        guard let info = userInfo as? [String: NSObject] else { return }
        syncCoordinator.application(application, didReceiveRemoteNotification: info)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        persistentContainer.viewContext.batchDeleteObjectsMarkedForLocalDeletion()
        persistentContainer.viewContext.refreshAllObjects()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        ConfigModel.shared.nowPlayableBehavior.handleNowPlayableSessionEnd()
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        persistentContainer.viewContext.refreshAllObjects()
    }

}


