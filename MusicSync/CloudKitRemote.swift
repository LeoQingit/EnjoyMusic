//
//  CloudKitRemote.swift
//  Music
//

import CloudKit
import MusicModel

final class CloudKitRemote: MusicRemote {

    let cloudKitContainer = CKContainer.default()
    let maximumNumberOfSongs = 500

    func setupSongSubscription() {
        let subscriptionID = "SongDownload"
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let options: CKQuerySubscription.Options = [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        let subscription = CKQuerySubscription(recordType: "Song", predicate: predicate, subscriptionID: subscriptionID, options: options)
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        let op = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        op.modifySubscriptionsCompletionBlock = { (foo, bar, error: Error?) -> () in
            if let e = error { print("Failed to modify subscription: \(e)") }
        }
        cloudKitContainer.publicCloudDatabase.add(op)
    }

    func fetchLatestSongs(completion: @escaping ([RemoteSong]) -> ()) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Song", predicate: predicate)
        query.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        let op = CKQueryOperation(query: query)
        op.resultsLimit = maximumNumberOfSongs
        op.fetchAggregateResults(in: cloudKitContainer.publicCloudDatabase, previousResults: []) { records, _ in
            completion(records.map { RemoteSong(record: $0) }.compactMap { $0 })
        }
    }

    func fetchNewSongs(completion: @escaping ([RemoteRecordChange<RemoteSong>], @escaping (_ success: Bool) -> ()) -> ()) {
        cloudKitContainer.fetchAllPendingNotifications(changeToken: nil) { changeReasons, error, callback in
            guard error == nil else { return completion([], { _ in }) } // TODO We should handle this case with e.g. a clean refetch
            guard changeReasons.count > 0 else { return completion([], callback) }
            self.cloudKitContainer.publicCloudDatabase.fetchRecords(for: changeReasons) { changes, error in
                completion(changes.map { RemoteRecordChange(songChange: $0) }.compactMap { $0 }, callback)
            }
        }
    }

    func upload(_ songs: [Song], completion: @escaping ([RemoteSong], RemoteError?) -> ()) {
        let recordsToSave = songs.map { $0.cloudKitRecord }
        let op = CKModifyRecordsOperation(recordsToSave: recordsToSave,
            recordIDsToDelete: nil)
        op.modifyRecordsCompletionBlock = { modifiedRecords, _, error in
            let remoteSongs = modifiedRecords?.map { RemoteSong(record: $0) }.compactMap { $0 } ?? []
            let remoteError = RemoteError(cloudKitError: error)
            completion(remoteSongs, remoteError)
        }
        cloudKitContainer.publicCloudDatabase.add(op)
    }

    func remove(_ songs: [Song], completion: @escaping ([RemoteRecordID], RemoteError?) -> ()) {
        let recordIDsToDelete = songs.map { (song: Song) -> CKRecord.ID in
            guard let name = song.remoteIdentifier else { fatalError("Must have a remote ID") }
            return CKRecord.ID(recordName: name)
        }
        let op = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsToDelete)
        op.modifyRecordsCompletionBlock = { _, deletedRecordIDs, error in
            completion((deletedRecordIDs ?? []).map { $0.recordName }, RemoteError(cloudKitError: error))
        }
        cloudKitContainer.publicCloudDatabase.add(op)
    }

    func fetchUserID(completion: @escaping (RemoteRecordID?) -> ()) {
        cloudKitContainer.fetchUserRecordID { userRecordID, error in
            completion(userRecordID?.recordName)
        }
    }

}


extension RemoteError {
    fileprivate init?(cloudKitError: Error?) {
        guard let error = cloudKitError.flatMap({ $0 as NSError }) else { return nil }
        if error.permanentCloudKitError {
            self = .permanent(error.partiallyFailedRecordIDsWithPermanentError.map { $0.recordName })
        } else {
            self = .temporary
        }
    }
}


extension RemoteRecordChange {
    fileprivate init?(songChange: CloudKitRecordChange) {
        switch songChange {
        case .created(let r):
            guard let remoteSong = RemoteSong(record: r) as? T else { return nil }
            self = RemoteRecordChange.insert(remoteSong)
        case .updated(let r):
            guard let remoteSong = RemoteSong(record: r) as? T else { return nil }
            self = RemoteRecordChange.update(remoteSong)
        case .deleted(let id):
            self = RemoteRecordChange.delete(id.recordName)
        }
    }
}


extension RemoteSong {
    fileprivate static var remoteRecordName: String { return "Song" }

    fileprivate init?(record: CKRecord) {
        guard record.recordType == RemoteSong.remoteRecordName else { fatalError("wrong record type") }
        guard let date = record.object(forKey: "date") as? Date,
            let colorData = record.object(forKey: "colors") as? Data,
            let colors = colorData.songColors,
            let albumCode = record.object(forKey: "album") as? Int,
            let creatorID = record.creatorUserRecordID?.recordName
            else { return nil }
        let isoAlbum = ISO3166.Album(rawValue: Int16(albumCode)) ?? ISO3166.Album.unknown
        let location = record.object(forKey: "location") as? CLLocation
        
        self.init(id: record.recordID.recordName, creatorID: creatorID, date: date, location: location, colors: colors, isoAlbum: isoAlbum)
    }
}


extension Song {
    fileprivate var cloudKitRecord: CKRecord {
        let record = CKRecord(recordType: RemoteSong.remoteRecordName)
        //TODO(swift3) Do we have to cast / wrap NSDate, NSData, NSNumber...?
        record["date"] = date as NSDate
        record["location"] = location
        record["colors"] = colors.songData as NSData
        record["album"] = NSNumber(value: album?.iso3166Code.rawValue ?? 0)
        record["version"] = NSNumber(value: 1)
        return record
    }
}

