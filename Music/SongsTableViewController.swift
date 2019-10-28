//
//  SongsTableViewController.swift
//  Music
//

import UIKit
import CoreData
import MusicModel
import CoreDataHelpers
import AVFoundation
import MediaPlayer
import WatchConnectivity

class SongsTableViewController: UITableViewController, SongsPresenter, SegueHandler {

    enum SegueIdentifier: String {
        case showSongDetail = "showSongDetail"
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
    
    var session: WCSession!

    var songItemMap: [Song: AVPlayerItem] = [:]
    var managedObjectContext: NSManagedObjectContext!
    var albums: [Album]?
    var songSource: SongSource! = .all {
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
        if WCSession.isSupported() {
            session = WCSession.default
            session.delegate = self
            session.activate()
        }
        albums = songSource.prefetch(in: managedObjectContext)
        setupTableView()
        player.delegate = self
    }


    // MARK: Private

    fileprivate var dataSource: TableViewDataSource<Song, SongsTableViewController>!
    fileprivate var observer: ManagedObjectObserver?

    fileprivate func setupTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.delegate = self
        let request = Song.sortedFetchRequest(with: songSource.predicate)
        request.returnsObjectsAsFaults = false
        request.fetchBatchSize = 20
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: "SongCell", fetchedResultsController: frc, delegate: self)
    }
    
    private func alertTitle(_ title: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    
    private func transferSpecificItem(indexPath: IndexPath) {
        let song = dataSource.objectAtIndexPath(indexPath)
        let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        if let urlStr = song.songURL, let filePath = filePath {
            let url = URL(fileURLWithPath: filePath + "/" + urlStr)

            if session.isPaired && session.isWatchAppInstalled {
                let transfer = session.transferFile(url, metadata: nil)
                song.progress = transfer.progress
                tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.fade)
            }
        }
    }
}


extension SongsTableViewController: TableViewDataSourceDelegate {
    func configure(_ cell: SongTableViewCell, for object: Song) {
        cell.configure(for: object)
    }
    
    func packObject(_ object: Song) -> AVPlayerItem {
        guard let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { fatalError() }
        guard let urlString = object.songURL else { fatalError() }
        let url = URL(fileURLWithPath: filePath + "/" + urlString)
        if let item = songItemMap[object] {
            return item
        } else {
           let item = AVPlayerItem(asset: AVAsset(url: url), automaticallyLoadedAssetKeys: [AssetPlayer.mediaSelectionKey])
            songItemMap[object] = item
            return item
        }
    }
    
    func object(_ packageObject: AVPlayerItem) -> Song {
        guard let song = songItemMap.filter({
            $0.value === packageObject
        }).first else {
            fatalError()
        }
        return song.key
    }
}


extension SongsTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.selectedPackageObject else { return }
        player.play(item)
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let action = UIContextualAction.init(style: UIContextualAction.Style.normal, title: "Transfer") { (action, view, block) in
            self.transferSpecificItem(indexPath: indexPath)
            block(false)
        }
        action.backgroundColor = UIColor.systemBlue
        
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction.init(style: UIContextualAction.Style.destructive, title: "Delete") { (action, view, block) in
            self.alertTitle("Default action at \(indexPath)")
        }
        
        let collect = UIContextualAction.init(style: UIContextualAction.Style.normal, title: "collect") { (action, view, block) in
            self.alertTitle("Default action at \(indexPath)")
        }
        collect.backgroundColor = UIColor.systemOrange
        
        return UISwipeActionsConfiguration(actions: [delete, collect])
    }
    
}

extension SongsTableViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("success")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print(error as Any)
    }
}


extension SongsTableViewController: WCSessionDelegate {
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print(#function)
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print(#function)
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print(#function)
    }
}

extension SongsTableViewController: AssetPlayerDelegate {
    func assetPlayer(_ player: AssetPlayer, staticMetaDataWith currentItem: AVPlayerItem) -> NowPlayableStaticMetadata {
        guard let item = songItemMap.filter({
            $0.value === currentItem
        }).first, let url = item.key.songURL else {
            fatalError()
        }
        guard let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { fatalError() }
        let assetURL = URL(fileURLWithPath: filePath + "/" + url)
        
        
        var itemArtwork: MPMediaItemArtwork?
        if let artwork = item.key.artworkURL, let artworkImage = UIImage(contentsOfFile: artwork) {
            itemArtwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in artworkImage }
            
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
        return dataSource.next(for: currentItem)
    }
    
    func assetPlayer(_ player: AssetPlayer, playPreviousTrac currentItem: AVPlayerItem) -> AVPlayerItem? {
        return dataSource.previous(for: currentItem)
    }
}
