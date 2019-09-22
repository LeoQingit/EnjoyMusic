//
//  SongsTableViewController.swift
//  Music
//

import UIKit
import CoreData
import MusicModel
import CoreDataHelpers


class SongsTableViewController: UITableViewController, SongsPresenter, SegueHandler {

    enum SegueIdentifier: String {
        case showSongDetail = "showSongDetail"
    }

    var managedObjectContext: NSManagedObjectContext!
    var countries: [Country]?
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
        countries = songSource.prefetch(in: managedObjectContext)
        setupTableView()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showSongDetail:
            guard let vc = segue.destination as? SongDetailViewController else { fatalError("Wrong view controller type") }
            guard let song = dataSource.selectedObject else { fatalError("Showing detail, but no selected row?") }
            vc.song = song
        }
    }


    // MARK: Private

    fileprivate var dataSource: TableViewDataSource<Song, SongsTableViewController>!
    fileprivate var observer: ManagedObjectObserver?

    fileprivate func setupTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        let request = Song.sortedFetchRequest(with: songSource.predicate)
        request.returnsObjectsAsFaults = false
        request.fetchBatchSize = 20
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: "SongCell", fetchedResultsController: frc, delegate: self)
    }

}


extension SongsTableViewController: TableViewDataSourceDelegate {
    func configure(_ cell: SongTableViewCell, for object: Song) {
        cell.configure(for: object)
    }
}


