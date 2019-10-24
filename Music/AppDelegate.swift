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
        
        ConfigModel.shared = ConfigModel(nowPlayableBehavior: WatchOSNowPlayableBehavior())
        
        createMusicContainer { container in
            self.persistentContainer = container
            self.syncCoordinator = SyncCoordinator(container: container)
            MusicScannerTool.shared.scanMusicPath(completion: { fileNames in
                guard !fileNames.isEmpty else { return }
                container.viewContext.performChanges {
                    for name in fileNames {
                        
                        
                        let currentCount = Song.count(in: container.viewContext) {
                            $0.predicate = NSPredicate(format: "%K = %@", SongNameKey, name)
                        }
                        
                        if currentCount == 0 {
                            guard let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return }
                            let url = URL(fileURLWithPath: filePath + "/" + name)
                            let asset = AVURLAsset(url: url)
                            
                            
                            for format in asset.availableMetadataFormats {
                                let metaItems = asset.metadata(forFormat: format)
                                for item in metaItems where item.commonKey != nil {
                                    switch item.commonKey! {
                                    case .commonKeyAlbumName:
                                        break
                                    case .commonKeyTitle:
                                        break
                                    case .commonKeyArtist:
                                        break
                                    case .commonKeyCreationDate:
                                        break
                                    default:
                                        break
                                    }
                                }
                            }
                            
                            let _ = Song.insert(into: container.viewContext, songURL: name)
                            
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

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        persistentContainer.viewContext.refreshAllObjects()
    }

}


