//
//  MusicRemote.swift
//  Music
//

import CoreLocation
import WatchMusicModel


enum RemoteRecordChange<T: RemoteRecord> {
    case insert(T)
    case update(T)
    case delete(RemoteRecordID)
}

enum RemoteError {
    case permanent([RemoteRecordID])
    case temporary

    var isPermanent: Bool {
        switch self {
        case .permanent: return true
        default: return false
        }
    }
}

protocol MusicRemote {
    func setupSongSubscription()
    func fetchLatestSongs(completion: @escaping ([RemoteSong]) -> ())
    func fetchNewSongs(completion: @escaping ([RemoteRecordChange<RemoteSong>], @escaping (_ success: Bool) -> ()) -> ())
    func upload(_ songs: [Song], completion: @escaping ([RemoteSong], RemoteError?) -> ())
    func remove(_ songs: [Song], completion: @escaping ([RemoteRecordID], RemoteError?) -> ())
    func fetchUserID(completion: @escaping (RemoteRecordID?) -> ())
}


