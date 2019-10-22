//
//  SongSource.swift
//  Music
//

import MusicModel
import CoreData
import CoreDataHelpers

enum SongSource {
    case all
    case yours(String?)
    case album(MusicModel.Album)
    case artlist(MusicModel.Artlist)
}


extension SongSource {
    var predicate: NSPredicate {
        switch self  {
        case .all:
            return NSPredicate(value: true)
        case .yours(let id):
            return Song.predicateForOwnedByUser(withIdentifier: id)
        case .album(let c):
            return NSPredicate(format: "album = %@", argumentArray: [c])
        case .artlist(let c):
            return NSPredicate(format: "album in %@", argumentArray: [c.albums])
        }
    }

    var managedObject: NSManagedObject? {
        switch self {
        case .album(let c): return c
        case .artlist(let c): return c
        default: return nil
        }
    }

    func prefetch(in context: NSManagedObjectContext) -> [MusicModel.Album] {
        switch self {
        case .all:
            return MusicModel.Album.fetch(in: context) { request in
                request.predicate = MusicModel.Album.defaultPredicate
            }
        case .yours(let id):
            let yoursPredicate = MusicModel.Album.predicateForContainingSongs(withCreatorIdentifier: id)
            let predicate = MusicModel.Album.predicate(yoursPredicate)
            return MusicModel.Album.fetch(in: context) { $0.predicate = predicate }
        case .artlist(let c):
            c.albums.fetchFaults()
            return Array(c.albums)
        default: return []
        }
    }
}

