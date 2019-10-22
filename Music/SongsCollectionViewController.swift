//
//  SongsCollectionViewController.swift
//  Music
//

import UIKit
import CoreData
import CoreDataHelpers
import MusicModel


class SongsCollectionViewController: UICollectionViewController, SongsPresenter, SegueHandler {

    enum SegueIdentifier: String {
        case showSongDetail = "showSongDetail"
    }

    var managedObjectContext: NSManagedObjectContext!
    var songSource: SongSource! {
        didSet {
            guard let o = songSource.managedObject as? Managed else { return }
            observer = ManagedObjectObserver(object: o) { [unowned self] type in
                guard type == .delete else { return }
                let _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else { fatalError("Wrong layout type") }
        let length = view.bounds.width/4
        layout.itemSize = CGSize(width: length, height: length)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showSongDetail:
            guard let vc = segue.destination as? SongDetailViewController
                else { fatalError("Wrong view controller type") }
            guard let song = dataSource.selectedObject
                else { fatalError("Showing detail, but no selected row?") }
            vc.song = song
        }
    }


    // MARK: Private

    fileprivate var dataSource: CollectionViewDataSource<SongsCollectionViewController>!
    fileprivate var observer: ManagedObjectObserver?

    fileprivate func setupCollectionView() {
        let request = Song.sortedFetchRequest(with: songSource.predicate)
        request.returnsObjectsAsFaults = false
        request.fetchBatchSize = 40
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        guard let cv = collectionView else { fatalError("must have collection view") }
        dataSource = CollectionViewDataSource(collectionView: cv, cellIdentifier: "SongCell", fetchedResultsController: frc, delegate: self)
    }

}

extension SongsCollectionViewController: CollectionViewDataSourceDelegate {
    func configure(_ cell: SongCollectionViewCell, for object: Song) {
        cell.configure(for: object)
    }
}


