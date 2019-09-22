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
    case country(MusicModel.Country)
    case continent(MusicModel.Continent)
}


extension SongSource {
    var predicate: NSPredicate {
        switch self  {
        case .all:
            return NSPredicate(value: true)
        case .yours(let id):
            return Song.predicateForOwnedByUser(withIdentifier: id)
        case .country(let c):
            return NSPredicate(format: "country = %@", argumentArray: [c])
        case .continent(let c):
            return NSPredicate(format: "country in %@", argumentArray: [c.countries])
        }
    }

    var managedObject: NSManagedObject? {
        switch self {
        case .country(let c): return c
        case .continent(let c): return c
        default: return nil
        }
    }

    func prefetch(in context: NSManagedObjectContext) -> [MusicModel.Country] {
        switch self {
        case .all:
            return MusicModel.Country.fetch(in: context) { request in
                request.predicate = MusicModel.Country.defaultPredicate
            }
        case .yours(let id):
            let yoursPredicate = MusicModel.Country.predicateForContainingSongs(withCreatorIdentifier: id)
            let predicate = MusicModel.Country.predicate(yoursPredicate)
            return MusicModel.Country.fetch(in: context) { $0.predicate = predicate }
        case .continent(let c):
            c.countries.fetchFaults()
            return Array(c.countries)
        default: return []
        }
    }
}


extension SongSource: LocalizedStringConvertible {
    var localizedDescription: String {
        switch self  {
        case .all: return ""
        case .yours: return ""
        case .country(let c): return c.localizedDescription
        case .continent(let c): return c.localizedDescription
        }
    }
}

