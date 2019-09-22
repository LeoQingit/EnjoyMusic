//
//  SongCollectionViewCell.swift
//  Music
//
//  Created by Florian on 27/08/15.
//  Copyright © 2015 objc.io. All rights reserved.
//

import UIKit
import MusicModel


class SongCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var songView: SongView!
}


extension SongCollectionViewCell {
    func configure(for song: Song) {
        songView.colors = song.colors
    }
}


