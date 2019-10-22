//
//  SongTableViewCell.swift
//  Music
//

import UIKit
import MusicModel


class SongTableViewCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var album: UILabel!
    @IBOutlet weak var transferProgress: UIProgressView!
    var observation: NSKeyValueObservation?
    
    deinit {
        observation = nil
    }
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
        label.text = song.name
        album.text = dateFormatter.string(from: song.date)
        observation = song.progress?.observe(\.fractionCompleted, options: [.initial, .new, .old], changeHandler: { [unowned self] (progress, value) in
            print(progress.totalUnitCount, value.newValue)
            let total = Double(progress.totalUnitCount)
            guard let currentValue = value.newValue else { return }
            self.transferProgress.setProgress(Float(currentValue / total), animated: true)
        })
    }
}
