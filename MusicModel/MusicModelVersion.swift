//
//  MusicModelVersion.swift
//  Music
//
//  Created by Florian on 06/10/15.
//  Copyright © 2015 objc.io. All rights reserved.
//

import CoreDataHelpers


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

