//
//  TableViewDataSource.swift
//  Music
//

import UIKit
import CoreData


protocol TableViewDataSourceDelegate: class {
    associatedtype Object
    associatedtype PackageObject
    associatedtype Cell: UITableViewCell
    func configure(_ cell: Cell, for object: Object)
    var numberOfAdditionalRows: Int { get }
    func packObject(_ object: Object) -> PackageObject
    func object(_ packageObject: PackageObject) -> Object
    func supplementaryObject(at indexPath: IndexPath) -> Object?
    func presentedIndexPath(for fetchedIndexPath: IndexPath) -> IndexPath
    func fetchedIndexPath(for presentedIndexPath: IndexPath) -> IndexPath?
}

extension TableViewDataSourceDelegate {
    var numberOfAdditionalRows: Int {
        return 0
    }

    func supplementaryObject(at indexPath: IndexPath) -> Object? {
        return nil
    }

    func presentedIndexPath(for fetchedIndexPath: IndexPath) -> IndexPath {
        return fetchedIndexPath
    }

    func fetchedIndexPath(for presentedIndexPath: IndexPath) -> IndexPath? {
        return presentedIndexPath
    }
}


/// Note: this class doesn't support working with multiple sections
class TableViewDataSource<Result: NSFetchRequestResult, Delegate: TableViewDataSourceDelegate>: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {

    typealias Object = Delegate.Object
    typealias PackageObject = Delegate.PackageObject
    typealias Cell = Delegate.Cell

    required init(tableView: UITableView, cellIdentifier: String, fetchedResultsController: NSFetchedResultsController<Result>, delegate: Delegate) {
        self.tableView = tableView
        self.cellIdentifier = cellIdentifier
        self.fetchedResultsController = fetchedResultsController
        self.delegate = delegate
        super.init()
        fetchedResultsController.delegate = self
        try! fetchedResultsController.performFetch()
        tableView.dataSource = self
        tableView.reloadData()
    }

    var selectedPackageObject: PackageObject? {
        guard let indexPath = tableView.indexPathForSelectedRow else { return nil }
        return packageObjectAtIndexPath(indexPath)
    }
    
    var selectedObject: Object? {
        guard let indexPath = tableView.indexPathForSelectedRow else { return nil }
        return objectAtIndexPath(indexPath)
    }
    
    var lastPackageObject: PackageObject? {
        if let count = fetchedResultsController.fetchedObjects?.count, count > 0 {
            let originalObject = fetchedResultsController.object(at: IndexPath(row: count - 1, section: 0)) as! Object
            return delegate.packObject(originalObject)
        }
        return nil
    }
    
    var firstPackageObject: PackageObject? {
        if let count = fetchedResultsController.fetchedObjects?.count, count > 0 {
            let originalObject = fetchedResultsController.object(at: IndexPath(row: 0, section: 0)) as! Object
            return delegate.packObject(originalObject)
        }
        return nil
    }

    func packageObjectAtIndexPath(_ indexPath: IndexPath) -> PackageObject {
        guard let fetchedIndexPath = delegate.fetchedIndexPath(for: indexPath) else {
            let originalObject = delegate.supplementaryObject(at: indexPath)!
            return delegate.packObject(originalObject)
        }
        
        let originalObject = (fetchedResultsController.object(at: fetchedIndexPath) as! Object)
        return delegate.packObject(originalObject)
    }
    
    func objectAtIndexPath(_ indexPath: IndexPath) -> Object {
        guard let fetchedIndexPath = delegate.fetchedIndexPath(for: indexPath) else {
            return delegate.supplementaryObject(at: indexPath)!
        }
        return (fetchedResultsController.object(at: fetchedIndexPath) as! Object)
    }

    func previous(for packageObject: PackageObject) -> PackageObject? {
        let object = delegate.object(packageObject)
        let indexPath = fetchedResultsController.indexPath(forObject: object as! Result)
        
        guard let row = indexPath?.row, let section = indexPath?.section else { fatalError() }
        if row - 1 >= 0 {
            return delegate.packObject((fetchedResultsController.object(at: IndexPath(row: row - 1, section: section)) as! Object))
        } else {
            return nil
        }
    }
    
    func next(for packageObject: PackageObject) -> PackageObject? {
        let object = delegate.object(packageObject)
        let indexPath = fetchedResultsController.indexPath(forObject: object as! Result)
        
        guard let row = indexPath?.row, let section = indexPath?.section else { fatalError() }
        if row + 1 < tableView.numberOfRows(inSection: section) {
            return delegate.packObject((fetchedResultsController.object(at: IndexPath(row: row + 1, section: section)) as! Object))
        } else {
            return nil
        }
    }

    func reconfigureFetchRequest(_ configure: (NSFetchRequest<Result>) -> ()) {
        NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: fetchedResultsController.cacheName)
        configure(fetchedResultsController.fetchRequest)
        do { try fetchedResultsController.performFetch() } catch { fatalError("fetch request failed") }
        tableView.reloadData()
    }


    // MARK: Private

    fileprivate let tableView: UITableView
    fileprivate let fetchedResultsController: NSFetchedResultsController<Result>
    fileprivate weak var delegate: Delegate!
    fileprivate let cellIdentifier: String

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = fetchedResultsController.sections?[section] else { return 0 }
        return section.numberOfObjects + delegate.numberOfAdditionalRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let object = objectAtIndexPath(indexPath)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? Cell
            else { fatalError("Unexpected cell type at \(indexPath)") }
        delegate.configure(cell, for: object)
        return cell
    }

    // MARK: NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let indexPath = newIndexPath else { fatalError("Index path should be not nil") }
            tableView.insertRows(at: [indexPath], with: .fade)
        case .update:
            guard let indexPath = indexPath else { fatalError("Index path should be not nil") }
            tableView.reloadRows(at: [indexPath], with: .fade)
        case .move:
            guard let indexPath = indexPath else { fatalError("Index path should be not nil") }
            guard let newIndexPath = newIndexPath else { fatalError("New index path should be not nil") }
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.insertRows(at: [newIndexPath], with: .fade)
            print("move", indexPath, anObject)
        case .delete:
            guard let indexPath = indexPath else { fatalError("Index path should be not nil") }
            tableView.deleteRows(at: [indexPath], with: .fade)
            print("delete", indexPath, anObject)
        @unknown default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

