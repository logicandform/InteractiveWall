//  Copyright © 2018 JABT. All rights reserved.

import AVFoundation
import Foundation

public final class AudioController {
    public static let shared = AudioController()

    let engine = AVAudioEngine()

    public init() {
    }

    public func play(url: URL) -> AKPlayer? {
        guard let player = AKPlayer(url: url) else {
            return nil
        }
        player.isLooping = true
        engine.connect(player.avAudioNode, to: engine.outputNode, format: nil)
        try! engine.start()
        player.play()

        return player
    }
}
