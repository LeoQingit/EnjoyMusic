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

}


extension SongsTableViewController: TableViewDataSourceDelegate {
    func configure(_ cell: SongTableViewCell, for object: Song) {
        cell.configure(for: object)
    }
}


extension SongsTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let song = dataSource.selectedObject else { fatalError("Showing detail, but no selected row?") }
        let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        if let urlStr = song.name, let filePath = filePath {
            do {
                print(urlStr)
                let data = try NSData.init(contentsOfFile: filePath + "/" + urlStr) as Data
//                let avplayer = try AVAudioPlayer(data: data)
//                self.player = avplayer
//                avplayer.volume = 0.5
//                avplayer.play()
//                avplayer.delegate = self
                session.sendMessageData(data, replyHandler: { data in
                    print(data)
                }) { error in
                    print(error)
                }
                let url = URL.init(fileURLWithPath: filePath + "/" + urlStr)
                    
                if session.isReachable {
                    let transfer = session.transferFile(url, metadata: nil)
                    
                    let progress = transfer.progress
                }
                
                
            } catch {
                print(error)
            }
        }
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
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    
}
