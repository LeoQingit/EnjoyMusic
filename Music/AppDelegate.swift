//
//  AppDelegate.swift
//  Music
//

import UIKit
import MusicSync
import MusicModel
import CoreData

private let SongNameKey = "name"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var persistentContainer: NSPersistentContainer!
    var syncCoordinator: SyncCoordinator!
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.registerForRemoteNotifications()
        createMusicContainer { container in
            self.persistentContainer = container
            self.syncCoordinator = SyncCoordinator(container: container)
            MusicScannerTool.shared.scanMusicPath(completion: { fileNames in
                guard !fileNames.isEmpty else { return }
                let temp = Song.fetch(in: container.viewContext) { (request) in
                    request.predicate = NSPredicate.init(value: true)
                }
                container.viewContext.performChanges {
                    for name in fileNames {
                        let tp = Song.findOrCreate(in: container.viewContext, matching:  NSPredicate(format: "%K = %@", SongNameKey, name)) { song in
                            song.name = name
                        }
                    }
                }
            })
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let vc = storyboard.instantiateViewController(withIdentifier: "SongsTableViewController") as? SongsTableViewController
                else { fatalError("Wrong view controller type") }
            vc.managedObjectContext = container.viewContext
            self.window?.rootViewController = vc
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


