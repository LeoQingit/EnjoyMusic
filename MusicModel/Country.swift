//
//  Country.swift
//  Music
//

import UIKit
import CoreLocation
import CoreData
import CoreDataHelpers


public class Country: NSManagedObject {

    @NSManaged fileprivate(set) var songs: Set<Song>
    @NSManaged fileprivate(set) var continent: Continent?
    @NSManaged public internal(set) var numberOfSongs: Int64
    @NSManaged internal var updatedAt: Date

    public fileprivate(set) var iso3166Code: ISO3166.Country {
        get {
            guard let c = ISO3166.Country(rawValue: numericISO3166Code) else { fatalError("Unknown country code") }
            return c
        }
        set {
            numericISO3166Code = newValue.rawValue
        }
    }

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        primitiveUpdatedAt = Date()
    }

    static func findOrCreate(for isoCountry: ISO3166.Country, in context: NSManagedObjectContext) -> Country {
        let predicate = Country.predicate(format: "%K == %d", #keyPath(numericISO3166Code), Int(isoCountry.rawValue))
        let country = findOrCreate(in: context, matching: predicate) {
            $0.iso3166Code = isoCountry
            $0.continent = Continent.findOrCreateContinent(for: isoCountry, in: context)
        }
        return country
    }

    public override func prepareForDeletion() {
        guard let c = continent else { return }
        if c.countries.filter({ !$0.isDeleted }).isEmpty {
            managedObjectContext?.delete(c)
        }
    }

    public override func willSave() {
        super.willSave()
        if hasChangedSongs {
            updateSongCount()
            if songs.count == 0 {
                markForLocalDeletion()
            }
        }
        if hasInsertedSongs {
            refreshUpdateDate()
        }
        if changedForDelayedDeletion {
            removeFromContinent()
        }
    }

    var changedSongCountDelta: Int64 {
        guard hasChangedSongs else { return 0 }
        return numberOfSongs - committedNumberOfSongs
    }


    // MARK: Private
    @NSManaged fileprivate var numericISO3166Code: Int16
    @NSManaged fileprivate var primitiveUpdatedAt: Date


    fileprivate var hasChangedSongs: Bool {
        return changedValue(forKey: #keyPath(songs)) != nil
    }

    fileprivate var hasInsertedSongs: Bool {
        guard hasChangedSongs else { return false }
        return songs.filter { $0.isInserted }.count > 0
    }

    fileprivate var committedNumberOfSongs: Int64 {
        let n = committedValue(forKey: #keyPath(numberOfSongs)) as? Int ?? 0
        return Int64(n)
    }

    fileprivate func refreshUpdateDate() {
        guard changedValue(forKey: UpdateTimestampKey) == nil else { return }
        updatedAt = Date()
        continent?.refreshUpdateDate()
    }

    fileprivate func updateSongCount() {
        guard Int64(songs.count) != numberOfSongs else { return }
        numberOfSongs = Int64(songs.count)
        continent?.updateSongCount()
    }

    fileprivate func removeFromContinent() {
        guard continent != nil else { return }
        continent = nil
    }


}


extension Country: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: UpdateTimestampKey, ascending: false)]
    }

    public static var defaultPredicate: NSPredicate {
        return notMarkedForLocalDeletionPredicate
    }
}

extension Country: DelayedDeletable {
    @NSManaged public var markedForDeletionDate: Date?
}

extension Country: UpdateTimestampable {}

