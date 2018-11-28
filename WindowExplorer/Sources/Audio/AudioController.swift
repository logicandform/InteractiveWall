//  Copyright © 2018 JABT. All rights reserved.

import AVFoundation
import Foundation


public final class AudioController {
    public static let shared = AudioController()

    let engine = AVAudioEngine()

    public init() {}

    public func play(url: URL) -> AKPlayer? {
        guard let player = AKPlayer(url: url), let audioFile = player.audioFile else {
            return nil
        }

        let format = MultiChannelPanAudioUnit.outputFormat(audioFile.fileFormat.sampleRate)
        DispatchQueue.main.async { [weak self] in
            if let strongSelf = self {
                strongSelf.engine.connect(player.avAudioNode, to: strongSelf.engine.outputNode, format: format)
                try! strongSelf.engine.start()
                player.start()
            }
        }

        return player
    }
}
