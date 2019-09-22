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
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var trashButton: UIBarButtonItem!

    fileprivate var observer: ManagedObjectObserver?

    var song: Song! {
        didSet {
            observer = ManagedObjectObserver(object: song) { [unowned self] type in
                guard type == .delete else { return }
                let _ = self.navigationController?.popViewController(animated: true)
            }
            updateViews()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
    }

    @IBAction func deleteSong(_ sender: UIBarButtonItem) {
        song.managedObjectContext?.performChanges {
            self.song.markForRemoteDeletion()
        }
    }


    // MARK: Private

    fileprivate func updateViews() {
        songView?.colors = song.colors
        mapView?.alpha = 1
        navigationItem.title = song.dateDescription
        trashButton.isEnabled = song.belongsToCurrentUser
        updateMapView()
    }

    fileprivate func updateMapView() {
        guard let map = mapView, let annotation = SongAnnotation(song: song) else { return }
        map.removeAnnotations(mapView!.annotations)
        map.addAnnotation(annotation)
        map.selectAnnotation(annotation, animated: false)
        map.setCenter(annotation.coordinate, animated: false)
        map.setRegion(MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 2e6, longitudinalMeters: 2e6), animated: false)
    }

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
        return ""
    }
}


class SongAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?

    fileprivate init?(song: Song) {
        coordinate = song.location?.coordinate ?? CLLocationCoordinate2D()
        title = song.country?.localizedDescription
        super.init()
        guard let _ = song.location, let _ = title else { return nil }
    }
}


