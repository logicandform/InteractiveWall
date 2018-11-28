//  Copyright © 2018 JABT. All rights reserved.

import AVFoundation
import Foundation


public final class AudioController {
    public static let shared = AudioController()

    let engine = AVAudioEngine()

    public init() {}

    public func play(url: URL) -> AKPlayer? {
        guard let player = AKPlayer(url: url), let sampleRate = player.audioFile?.fileFormat.sampleRate else {
            return nil
        }
        let format = MultiChannelPanAudioUnit.outputFormat(sampleRate)
        engine.connect(player.avAudioNode, to: engine.outputNode, format: format)
        try! engine.start()
        player.start()

        return player
    }
}
