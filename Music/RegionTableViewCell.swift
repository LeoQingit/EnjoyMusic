//
//  RegionTableViewCell.swift
//  Music
//

import UIKit
import MusicModel

class RegionTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
}


extension RegionTableViewCell {
    func configure(for object: DisplayableRegion) {
        titleLabel.text = object.localizedDescription
        detailLabel.text = object.localizedDetailDescription
    }
}

