//
//  Model.swift
//  Music
//

import UIKit
import CoreLocation
import CoreData
import CoreDataHelpers


public class Song: NSManagedObject {

    @NSManaged public fileprivate(set) var date: Date
    @NSManaged public fileprivate(set) var colors: [UIColor]

    @NSManaged public var creatorID: String?
    @NSManaged public var remoteIdentifier: RemoteRecordID?

    @NSManaged public fileprivate(set) var album___: Album
    @NSManaged public fileprivate(set) var album: Album?
    @NSManaged public fileprivate(set) var coverURL: String?
    @NSManaged public fileprivate(set) var duration: Double
    @NSManaged public fileprivate(set) var favorite: Int16
    @NSManaged public var name: String?
    
    @NSManaged public fileprivate(set) var songURL: String?


    public override func awakeFromInsert() {
        super.awakeFromInsert()
        primitiveDate = Date()
    }

    public static func insert(into moc: NSManagedObjectContext, songURL: String?) -> Song {
        let song: Song = moc.insertObject()
        song.songURL = songURL
        song.date = Date()
        return song
    }

    public static func insert(into moc: NSManagedObjectContext, songURL: String?, remoteIdentifier: RemoteRecordID? = nil, date: Date? = nil, creatorID: String? = nil) -> Song {
        let song: Song = moc.insertObject()
        song.songURL = songURL
        song.album = Album.findOrCreate(for: "未知", in: moc)
        song.remoteIdentifier = remoteIdentifier
        if let d = date {
            song.date = d
        }
        song.creatorID = creatorID
        return song
    }

    public override func willSave() {
        super.willSave()
        if changedForDelayedDeletion || changedForRemoteDeletion {
            removeFromAlbum()
        }
    }


    // MARK: Private

    @NSManaged fileprivate var primitiveDate: Date


    fileprivate func removeFromAlbum() {
        guard album != nil else { return }
        album = nil
    }

}


extension Song: Managed {

    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: #keyPath(date), ascending: false)]
    }

    public static var defaultPredicate: NSPredicate {
        return notMarkedForDeletionPredicate
    }

}


extension Song: DelayedDeletable {
    @NSManaged public var markedForDeletionDate: Date?
}


extension Song: RemoteDeletable {
    @NSManaged public var markedForRemoteDeletion: Bool
}


private let MaxColors = 8

extension UIImage {
    fileprivate var songColors: [UIColor] {
        var colors: [UIColor] = []
        for c in dominantColors(.Music) where colors.count < MaxColors {
            colors.append(c)
        }
        return colors
    }
}

extension Data {
    public var songColors: [UIColor]? {
        guard count > 0 && count % 3 == 0 else { return nil }
        var rgbValues = Array(repeating: UInt8(), count: count)
        rgbValues.withUnsafeMutableBufferPointer { buffer in
            let voidPointer = UnsafeMutableRawPointer(buffer.baseAddress)
            let _ = withUnsafeBytes { bytes in
                memcpy(voidPointer, bytes, count)
            }
        }
        let rgbSlices = rgbValues.sliced(size: 3)
        return rgbSlices.map { slice in
            guard let color = UIColor(rawData: slice) else { fatalError("cannot fail since we know tuple is of length 3") }
            return color
        }
    }
}


extension Sequence where Iterator.Element == UIColor {
    public var songData: Data {
        let rgbValues = flatMap { $0.rgb }
        return rgbValues.withUnsafeBufferPointer {
            return Data(bytes: UnsafePointer<UInt8>($0.baseAddress!),
                count: $0.count)
        }
    }
}


private let ColorsTransformerName = "ColorsTransformer"

extension Song {
    static func registerValueTransformers() {
        _ = self.__registerOnce
    }
    fileprivate static let __registerOnce: () = {
        ClosureValueTransformer.registerTransformer(withName: ColorsTransformerName, transform: { (colors: NSArray?) -> NSData? in
                guard let colors = colors as? [UIColor] else { return nil }
                return colors.songData as NSData
            }, reverseTransform: { (data: NSData?) -> NSArray? in
                return data
                    .flatMap { ($0 as Data).songColors }
                    .map { $0 as NSArray }
        })
    }()
}


extension UIColor {

    fileprivate var rgb: [UInt8] {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: nil)
        return [UInt8(red * 255), UInt8(green * 255), UInt8(blue * 255)]
    }

    fileprivate convenience init?(rawData: [UInt8]) {
        if rawData.count != 3 { return nil }
        let red = CGFloat(rawData[0]) / 255
        let green = CGFloat(rawData[1]) / 255
        let blue = CGFloat(rawData[2]) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }

}


