//
//  AudioLengthCalculator.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/6/25.
//

import AVFoundation

class AudioLengthCalculator {
    static func duaration(for url: URL) -> UInt {
        let audioAsset = AVURLAsset(url: url, options: [:])
        let audioDuration = audioAsset.duration
        let audioDurationSeconds = audioDuration.seconds
        if audioDurationSeconds > 0 {
            return UInt((audioDurationSeconds * 10 + 5) / 10)
        }
        return 0
    }
}
