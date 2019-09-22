//
//  SongTableViewCell.swift
//  Music
//

import UIKit
import MusicModel


class SongTableViewCell: UITableViewCell {
    @IBOutlet weak var songView: SongView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var country: UILabel!
}


private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    formatter.doesRelativeDateFormatting = true
    formatter.formattingContext = .standalone
    return formatter
}()


extension SongTableViewCell {
    func configure(for song: Song) {
        songView.colors = song.colors
        label.text = dateFormatter.string(from: song.date)
        country.text = song.country?.localizedDescription ?? ""
    }
}


