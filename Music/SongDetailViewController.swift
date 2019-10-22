//
//  SongDetailViewController.swift
//  Music
//
//  Created by Daniel Eggert on 15/05/2015.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import UIKit
import MapKit
import MusicModel
import CoreDataHelpers


class SongDetailViewController: UIViewController {

    @IBOutlet weak var songView: SongView!
    @IBOutlet weak var trashButton: UIBarButtonItem!

    fileprivate var observer: ManagedObjectObserver?

    var song: Song! {
        didSet {
            observer = ManagedObjectObserver(object: song) { [unowned self] type in
                guard type == .delete else { return }
                let _ = self.navigationController?.popViewController(animated: true)
            }
//            updateViews()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        updateViews()
    }

    @IBAction func deleteSong(_ sender: UIBarButtonItem) {
        song.managedObjectContext?.performChanges {
            self.song.markForRemoteDeletion()
        }
    }


    // MARK: Private

//    fileprivate func updateViews() {
//        songView?.colors = song.colors
//        navigationItem.title = song.dateDescription
//        trashButton.isEnabled = song.belongsToCurrentUser
//    }


}


private let dateComponentsFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .full
    formatter.includesApproximationPhrase = true
    formatter.allowedUnits = [.minute, .hour, .weekday, .month, .year]
    formatter.maximumUnitCount = 1
    return formatter
}()

extension Song {
    var dateDescription: String {
        guard let timeString = dateComponentsFormatter.string(from: abs(date.timeIntervalSinceNow)) else { return "" }
        return timeString
    }
}
