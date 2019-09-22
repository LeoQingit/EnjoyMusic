//
//  SongsPresenter.swift
//  Music
//

import CoreData

protocol SongsPresenter: class {
    var songSource: SongSource! { get set }
    var managedObjectContext: NSManagedObjectContext! { get set }
}


