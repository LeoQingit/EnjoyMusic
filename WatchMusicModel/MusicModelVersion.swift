//
//  MusicModelVersion.swift
//  Music
//

import WatchCoreDataHelpers


enum MusicModelVersion: String {
    case Version1 = "Music"
}


extension MusicModelVersion: ModelVersion {
    static var all: [MusicModelVersion] { return [.Version1] }
    static var current: MusicModelVersion { return .Version1 }

    var name: String { return rawValue }
    var modelBundle: Bundle { return Bundle(for: Song.self) }
    var modelDirectoryName: String { return "Music.momd" }
}

