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
    private var progressObservation: NSKeyValueObservation?
    private var progressViObservation: NSKeyValueObservation?
    
    deinit {
        progressObservation = nil
        progressViObservation = nil
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
        progressObservation = song.progress?.observe(\.completedUnitCount, options: [.initial, .new], changeHandler: { [unowned self] (progress, value) in
            print(progress.localizedDescription ?? "")
            let total = Double(progress.totalUnitCount)
            guard let currentValue = value.newValue else { return }
            DispatchQueue.main.async {
                self.transferProgress.setProgress(Float(Double(currentValue) / total), animated: true)
            }
        })
    }
}
