//
//  SongCollectionViewCell.swift
//  Music
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


