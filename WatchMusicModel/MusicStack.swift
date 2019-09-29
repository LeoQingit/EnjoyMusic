//
//  MusicStack.swift
//  Music
//

import CoreData
import WatchCoreDataHelpers

private let ubiquityToken: String = {
    guard let token = FileManager.default.ubiquityIdentityToken else { return "unknown" }
    let string = try!NSKeyedArchiver.archivedData(withRootObject:token, requiringSecureCoding: false).base64EncodedString(options: [])

    return string.removingCharacters(in: CharacterSet.letters.inverted)
}()
private let storeURL = URL.library.appendingPathComponent("\(ubiquityToken).music")

private let musicContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "Music", managedObjectModel: MusicModelVersion.current.managedObjectModel())
    let storeDescription = NSPersistentStoreDescription(url: storeURL)
    storeDescription.shouldMigrateStoreAutomatically = false
    container.persistentStoreDescriptions = [storeDescription]
    return container
}()

public func createMusicContainer(migrating: Bool = false, progress: Progress? = nil, completion: @escaping (NSPersistentContainer) -> ()) {
    musicContainer.loadPersistentStores { _, error in
        if error == nil {
            musicContainer.viewContext.mergePolicy = MusicMergePolicy(mode: .local)
            DispatchQueue.main.async { completion(musicContainer) }
        } else {
            guard !migrating else { fatalError("was unable to migrate store") }
            DispatchQueue.global(qos: .userInitiated).async {
                migrateStore(from: storeURL, to: storeURL, targetVersion: MusicModelVersion.current, deleteSource: true, progress: progress)
                createMusicContainer(migrating: true, progress: progress,
                     completion: completion)
            }
        }
    }
}


