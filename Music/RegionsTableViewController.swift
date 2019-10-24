//
//  RegionsTableViewController.swift
//  Music
//
//  Created by Daniel Eggert on 15/05/2015.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import UIKit
import MusicModel
import CoreData
import CoreDataHelpers


class RegionsTableViewController: UITableViewController, SegueHandler {

    enum SegueIdentifier: String {
        case showAllSongs = "showAllSongs"
        case showYourSongs = "showYourSongs"
        case showAlbumSongs = "showAlbumSongs"
        case showArtlistSongs = "showArtlistSongs"
    }

    @IBOutlet weak var filterSegmentedControl: UISegmentedControl!
    var managedObjectContext: NSManagedObjectContext!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "title"
        setupTableView()
        prepareDefaultNavigationStack()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? SongsContainerViewController else { fatalError("Wrong view controller type") }
        vc.managedObjectContext = managedObjectContext
        switch segueIdentifier(for: segue) {
        case .showAllSongs:
            vc.songSource = .all
        case .showYourSongs:
            vc.songSource = .yours(managedObjectContext.userID)
        case .showAlbumSongs:
            guard let album = dataSource?.selectedPackageObject as? Album else { fatalError("Must be a album") }
            vc.songSource = .album(album)
        case .showArtlistSongs:
            guard let artlist = dataSource?.selectedPackageObject as? Artlist else { fatalError("Must be a artlist") }
            vc.songSource = .artlist(artlist)
        }
    }

    @IBAction func filterChanged(_ sender: UISegmentedControl) {
        updateDataSource()
    }


    // MARK: Private

    fileprivate var dataSource: TableViewDataSource<NSFetchRequestResult, RegionsTableViewController>!

    fileprivate func setupTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.delegate = self
        setupDataSource()
    }

    fileprivate func prepareDefaultNavigationStack() {
        let vc = SongsContainerViewController.instantiateFromStoryboard(for: .all, managedObjectContext: managedObjectContext)
        navigationController?.pushViewController(vc, animated: false)
    }

    fileprivate func setupDataSource() {
        let regionType = filterSegmentedControl.regionType
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: regionType.entityName)
        request.sortDescriptors = regionType.defaultSortDescriptors
        request.fetchBatchSize = 20
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: "Region", fetchedResultsController: frc, delegate: self)
    }

    fileprivate func updateDataSource() {
        dataSource.reconfigureFetchRequest { request in
            let regionType = filterSegmentedControl.regionType
            request.entity = regionType.entity
            request.sortDescriptors = regionType.defaultSortDescriptors
        }
    }
}


extension RegionsTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let region = dataSource.objectAtIndexPath(indexPath)
//        performSegue(withIdentifier: region.segue)
    }
}


extension RegionsTableViewController: TableViewDataSourceDelegate {
    func object(_ packageObject: String) -> String {
        return ""
    }
    
    
    func supplementaryObject(at indexPath: IndexPath) -> String? {
        switch indexPath.row {
        case 0: return "UserRegion.all"
        case 1: return "UserRegion.yours"
        default: return nil
        }
    }

    func configure(_ cell: RegionTableViewCell, for object: String) {
        cell.configure(for: object)
    }
    
    func packObject(_ object: String) -> String {
        return ""
    }

    var numberOfAdditionalRows: Int {
        return 2
    }

    func fetchedIndexPath(for presentedIndexPath: IndexPath) -> IndexPath? {
        let fetchedRow = presentedIndexPath.row - 2
        guard fetchedRow >= 0 else { return nil }
        return IndexPath(row: fetchedRow, section: presentedIndexPath.section)
    }

    func presentedIndexPath(for fetchedIndexPath: IndexPath) -> IndexPath {
        return IndexPath(row: fetchedIndexPath.row + 2, section: fetchedIndexPath.section)
    }
}


extension UISegmentedControl {
    fileprivate var regionType: Managed.Type {
        switch selectedSegmentIndex {
        case 0: return SongMetadata.self
        case 1: return Album.self
        case 2: return Artlist.self
        default: fatalError("Invalid filter index")
        }
    }
}

