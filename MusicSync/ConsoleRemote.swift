//
//  ConsoleRemote.swift
//  Music
//
//  Created by Florian on 22/09/15.
//  Copyright © 2015 objc.io. All rights reserved.
//

import MusicModel


final class ConsoleRemote: MusicRemote {

    fileprivate func log(_ str: String) {
        print("--- Dummy network adapter logging to console; See README for instructions to enable CloudKit ---\n* ", str)
    }

    func setupSongSubscription() {
        log("Setting up subscription")
    }

    func fetchLatestSongs(completion: @escaping ([RemoteSong]) -> ()) {
        log("Fetching latest songs")
        completion([])
    }

    func fetchNewSongs(completion: @escaping ([RemoteRecordChange<RemoteSong>], @escaping (_ success: Bool) -> ()) -> ()) {
        log("Fetching new songs")
        completion([], { _ in })
    }

    func upload(_ songs: [Song], completion: @escaping ([RemoteSong], RemoteError?) -> ()) {
        log("Uploading \(songs.count) songs")
        let remoteSongs = songs.map { RemoteSong(song: $0) }.compactMap { $0 }
        completion(remoteSongs, nil)
    }

    func remove(_ songs: [Song], completion: @escaping ([RemoteRecordID], RemoteError?) -> ()) {
        log("Deleting \(songs.count) songs")
        let ids = songs.map { $0.remoteIdentifier }.compactMap { $0 }
        completion(ids, nil)
    }

    func fetchUserID(completion: @escaping (RemoteRecordID?) -> ()) {
        log("Fetching ID of logged in user")
        completion(nil)
    }

}


extension RemoteSong {

    fileprivate init?(song: Song) {
        self.init(id: "__dummyId__", creatorID: nil, date: song.date, location: song.location, colors: song.colors, isoCountry: song.country?.iso3166Code ?? .unknown)
    }
}


