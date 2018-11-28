//  Copyright © 2018 JABT. All rights reserved.

import AVFoundation
import Foundation


public final class AudioController {
    public static let shared = AudioController()

    let engine = AVAudioEngine()
    private var initialized = false

    public init() {}

    public func play(url: URL) -> AKPlayer? {
        guard let player = AKPlayer(url: url), let audioFile = player.audioFile else {
            return nil
        }

        if !initialized {
            let format = MultiChannelPanAudioUnit.outputFormat(audioFile.fileFormat.sampleRate)
            engine.connect(player.avAudioNode, to: engine.outputNode, format: format)
            try! engine.start()
            player.start()
            initialized = true
        }

        return player
    }
}
