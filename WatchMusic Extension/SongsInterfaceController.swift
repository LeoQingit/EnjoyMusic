//
//  SongsInterfaceController.swift
//  WatchMusic Extension
//
//  Created by Qin Leo on 2019/9/23.
//  Copyright © 2019 Qin Leo. All rights reserved.
//

import WatchKit
import Foundation
import CoreData
import WatchCoreDataHelpers
import WatchMusicModel
import AVFoundation
import MediaPlayer

let kSongTableRowType = "SongTableRowController"

class SongsInterfaceController: WKInterfaceController {

    @IBOutlet weak var mainTable: WKInterfaceTable!
    
    var songItemMap: [Song: AVPlayerItem] = [:]
    
    let audioSession = AVAudioSession.sharedInstance()

    var managedContext: NSManagedObjectContext?
    
    var songs: [Song] = []
    
    var songSource: SongSource! = .all {
        didSet {
            guard let o = songSource.managedObject as? Managed else { return }
            observer = ManagedObjectObserver(object: o) { [unowned self] type in
                guard type == .delete else { return }
//                let _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    var player: AssetPlayer = { () -> AssetPlayer in
        var player: AssetPlayer
        do {
            player = try AssetPlayer()
        } catch {
            fatalError(error.localizedDescription)
        }
        return player
    }()
    
    // MARK: Private

    fileprivate var observer: ManagedObjectObserver?
    fileprivate var fetchedResultsController: NSFetchedResultsController<Song>!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        guard let managedContext = context as? NSManagedObjectContext else {
            return
        }
        self.managedContext = managedContext
        
        let request = Song.sortedFetchRequest(with: songSource.predicate)
        request.returnsObjectsAsFaults = false
        request.fetchBatchSize = 20
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        try! frc.performFetch()

        fetchedResultsController = frc
        
        player.delegate = self
        
        guard let rowsNum = frc.sections?.first?.numberOfObjects, rowsNum > 0 else {
            return
        }
        
        mainTable.setNumberOfRows(rowsNum, withRowType: kSongTableRowType)
        
        for idx in 0...max(0, rowsNum - 1) {
            configureTableRow(index: idx)
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    private func getPlayerItem(_ object: Song) -> AVPlayerItem {
        guard let urlString = object.songURL else { fatalError() }
        let url = URL(fileURLWithPath: URL.library.appendingPathComponent("Musics").path + "/" + urlString)
        if let item = songItemMap[object] {
            return item
        } else {
            let item = AVPlayerItem(asset: AVAsset(url: url), automaticallyLoadedAssetKeys: [AssetPlayer.mediaSelectionKey])
            songItemMap[object] = item
            return item
        }
    }
    
    private func getSong(_ packageObject: AVPlayerItem) -> Song {
        guard let song = songItemMap.filter({
            $0.value === packageObject
        }).first else {
            fatalError()
        }
        return song.key
    }
    
    private func configureTableRow(index: Int) {
        let row = mainTable.rowController(at: index) as! SongTableRowController
        let object = fetchedResultsController.object(at: IndexPath(row: index, section: 0))
        row.nameLabel.setText(object.name)
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let item = fetchedResultsController.object(at: IndexPath(row: rowIndex, section: 0))
        player.play(getPlayerItem(item))
        pushController(withName: "MusicPlayerInterfaceController", context: nil)
    }
}

extension SongsInterfaceController: NSFetchedResultsControllerDelegate {
    // MARK: NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let indexPath = newIndexPath else { fatalError("Index path should be not nil") }
            mainTable.insertRows(at: IndexSet(integer: indexPath.row), withRowType: kSongTableRowType)
            configureTableRow(index: indexPath.row)
            
        case .update:
            guard let indexPath = indexPath else { fatalError("Index path should be not nil") }
            configureTableRow(index: indexPath.row)
        case .move:
            guard let indexPath = indexPath else { fatalError("Index path should be not nil") }
            guard let newIndexPath = newIndexPath else { fatalError("New index path should be not nil") }
            guard let song = anObject as? Song else { fatalError("Wrong Type") }
            mainTable.removeRows(at: IndexSet(integer: indexPath.row))
            mainTable.insertRows(at: IndexSet(integer: newIndexPath.row), withRowType: kSongTableRowType)
            let rowController = mainTable.rowController(at: indexPath.row) as! SongTableRowController
            rowController.nameLabel.setText(song.name)
        case .delete:
            guard let indexPath = indexPath else { fatalError("Index path should be not nil") }
            mainTable.removeRows(at: IndexSet(integer: indexPath.row))
        @unknown default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
    }
}

extension SongsInterfaceController: AssetPlayerDelegate {
    func assetPlayer(_ player: AssetPlayer, staticMetaDataWith currentItem: AVPlayerItem) -> NowPlayableStaticMetadata {
        guard let item = songItemMap.filter({
            $0.value === currentItem
        }).first, let url = item.key.songURL else {
            fatalError()
        }
        let assetURL = URL.documents.appendingPathComponent(url)
        
        var itemArtwork: MPMediaItemArtwork?
        
        if let artwork = item.key.artworkURL, let data = try? Data(contentsOf: URL.library.appendingPathComponent("ArtWorks").appendingPathComponent(artwork)) {
            if let artworkImage = UIImage(data: data) {
                itemArtwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in artworkImage }
            }
        }
        
        return NowPlayableStaticMetadata(assetURL: assetURL,
                                         mediaType: .audio,
                                         isLiveStream: false,
                                         title: item.key.name ?? "####",
                                         artist: item.key.artlist?.name ?? "###",
                                         artwork: itemArtwork,
                                         albumArtist: item.key.artlist?.name ?? "###",
                                         albumTitle: item.key.album?.name ?? "####")
        
    }
    
    func assetPlayer(_ player: AssetPlayer, playNextTrac currentItem: AVPlayerItem) -> AVPlayerItem? {
        let song = getSong(currentItem)
        if let index = fetchedResultsController.indexPath(forObject: song) {
            if mainTable.numberOfRows > index.row + 1 {
                return getPlayerItem(fetchedResultsController.object(at: IndexPath.init(row: index.row + 1, section: 0)))
            }
        }
        return nil
    }
    
    func assetPlayer(_ player: AssetPlayer, playPreviousTrac currentItem: AVPlayerItem) -> AVPlayerItem? {
        let song = getSong(currentItem)
        if let index = fetchedResultsController.indexPath(forObject: song) {
            if index.row - 1 >= 0 {
                return getPlayerItem(fetchedResultsController.object(at: IndexPath.init(row: index.row - 1, section: 0)))
            }
        }
        return nil
    }
}