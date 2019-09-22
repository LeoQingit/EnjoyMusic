//
//  SongsPresenter.swift
//  Music
//
//  Created by Florian on 28/09/15.
//  Copyright © 2015 objc.io. All rights reserved.
//

import CoreData

protocol SongsPresenter: class {
    var songSource: SongSource! { get set }
    var managedObjectContext: NSManagedObjectContext! { get set }
}


