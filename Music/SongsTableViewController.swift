//
//  SongsTableViewController.swift
//  Music
//

import UIKit
import CoreData
import MusicModel
import CoreDataHelpers
import AVFoundation
import WatchConnectivity

class SongsTableViewController: UITableViewController, SongsPresenter, SegueHandler {

    enum SegueIdentifier: String {
        case showSongDetail = "showSongDetail"
    }
    var player: AVAudioPlayer!
    var session: WCSession!

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
        if let urlStr = song.name, let filePath = filePath {
            let url = URL(fileURLWithPath: filePath + "/" + urlStr)
            
            if session.isPaired && session.isWatchAppInstalled {
                let transfer = session.transferFile(url, metadata: nil)
                session.sendMessage(["hello":"world"], replyHandler: { (value) in
                    print(value)
                }) { (error) in
                    print(error)
                }
                song.progress = transfer.progress
                tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.none)
            }
        }
    }

}


extension SongsTableViewController: TableViewDataSourceDelegate {
    func configure(_ cell: SongTableViewCell, for object: Song) {
        cell.configure(for: object)
    }
}


extension SongsTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /*
         let metadatas: [NowPlayableStaticMetadata] = [
         
         NowPlayableStaticMetadata(assetURL: song1URL,
         mediaType: .audio,
         isLiveStream: false,
         title: "First Song",
         artist: "Singer of Songs",
         artwork: artworkNamed("Song 1"),
         albumArtist: "Singer of Songs",
         albumTitle: "Songs to Sing"),
         
         NowPlayableStaticMetadata(assetURL: videoURL,
         mediaType: .video,
         isLiveStream: false,
         title: "Bip Bop, The Movie",
         artist: nil,
         artwork: nil,
         albumArtist: nil,
         albumTitle: nil),
         
         NowPlayableStaticMetadata(assetURL: song2URL,
         mediaType: .audio,
         isLiveStream: false,
         title: "Second Song",
         artist: "Other Singer",
         artwork: artworkNamed("Song 2"),
         albumArtist: "Singer of Songs",
         albumTitle: "Songs to Sing"),
         
         NowPlayableStaticMetadata(assetURL: videoURL,
         mediaType: .video,
         isLiveStream: false,
         title: "Bip Bop, The Sequel",
         artist: nil,
         artwork: nil,
         albumArtist: nil,
         albumTitle: nil),
         
         NowPlayableStaticMetadata(assetURL: song3URL,
         mediaType: .audio,
         isLiveStream: false,
         title: "Third Song",
         artist: "Singer of Songs",
         artwork: artworkNamed("Song 3"),
         albumArtist: "Singer of Songs",
         albumTitle: "Songs to Sing")
         ]
         
         */
        
        //                let avplayer = try AVAudioPlayer(data: data)
        //                self.player = avplayer
        //                avplayer.volume = 0.5
        //                avplayer.play()
        //                avplayer.delegate = self
        
    }
    
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let collectAction = UITableViewRowAction(style: .default, title: "Collect")     { (action, indexPath) in
            self.alertTitle("Default action at \(indexPath)")
        }
        collectAction.backgroundColor = UIColor.systemOrange
        
        let transferAction = UITableViewRowAction(style: .normal, title: "Transfer") { (action, indexPath) in
            self.transferSpecificItem(indexPath: indexPath)
        }
        transferAction.backgroundColor = UIColor.systemBlue
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            self.alertTitle("Delete action at \(indexPath)")
        }
        return [collectAction, transferAction, deleteAction]
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
