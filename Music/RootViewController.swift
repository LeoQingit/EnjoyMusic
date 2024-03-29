//
//  RootViewController.swift
//  Music
//

import UIKit
import CoreLocation
import CoreData
import MusicModel


class RootViewController: UIViewController, SegueHandler {

    enum SegueIdentifier: String {
        case embedNavigation = "embedNavigationController"
        case embedCamera = "embedCamera"
    }

    @IBOutlet weak var hideCameraConstraint: NSLayoutConstraint!
    var managedObjectContext: NSManagedObjectContext!

    override func viewDidLoad() {
        super.viewDidLoad()
        geoLocationController = GeoLocationController(delegate: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .embedNavigation:
            guard let nc = segue.destination as? UINavigationController,
                let vc = nc.viewControllers.first as? RegionsTableViewController
                else { fatalError("wrong view controller type") }
            vc.managedObjectContext = managedObjectContext
            nc.delegate = self
        case .embedCamera:
            guard let cameraVC = segue.destination as? CameraViewController else { fatalError("must be camera view controller") }
            cameraViewController = cameraVC
            cameraViewController?.delegate = self
        }
    }


    // MARK: Private

    fileprivate var geoLocationController: GeoLocationController!
    fileprivate var cameraViewController: CameraViewController?

    fileprivate func setCameraVisibility(_ visible: Bool) {
        hideCameraConstraint.isActive = !visible
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .beginFromCurrentState, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    fileprivate func saveSongWithImage(_ image: UIImage) {
        geoLocationController.retrieveCurrentLocation { location, placemark in
            self.managedObjectContext.performChanges {
                let _ = Song.insert(into: self.managedObjectContext, songURL: nil)
            }
        }
    }
}

extension RootViewController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let cameraVisible = (viewController as? SongDetailViewController) == nil
        setCameraVisibility(cameraVisible)
    }

}

extension RootViewController: GeoLocationControllerDelegate {

    func geoLocationDidChangeAuthorizationStatus(authorized: Bool) {
        cameraViewController?.locationIsAuthorized = authorized
    }

}

extension RootViewController: CameraViewControllerDelegate {

    func didCapture(_ image: UIImage) {
        saveSongWithImage(image)
    }

}


