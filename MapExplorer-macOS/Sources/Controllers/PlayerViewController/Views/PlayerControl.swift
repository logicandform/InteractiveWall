//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AVKit


fileprivate enum PlayerState {
    case playing
    case paused
}


class PlayerControl: NSView {
    static let nib = NSNib.Name(rawValue: "PlayerControl")

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var seekBar: NSSlider!
    @IBOutlet weak var currentTimeLabel: NSTextField!
    @IBOutlet weak var durationLabel: NSTextField!

    var gestureManager: GestureManager!
    private var state = PlayerState.paused
    private var currentDuration: CMTime?

    var player: AVPlayer? {
        didSet {
            setup(for: player)
        }
    }

    var currentTime: CMTime = CMTime() {
        didSet {
            updateControls(for: currentTime)
        }
    }


    // MARK: Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        Bundle.main.loadNibNamed(PlayerControl.nib, owner: self, topLevelObjects: nil)
        addSubview(contentView)
        contentView.frame = bounds
    }


    // MARK: API

    func toggle() {
        if state == .playing {
            state = .paused
            player?.pause()
        } else {
            state = .playing
            player?.play()
        }
    }


    // MARK: Setup

    private func setup(for player: AVPlayer?) {
        guard let player = player, let item = player.currentItem else {
            return
        }

        currentDuration = item.asset.duration
        if let durationString = string(for: item.asset.duration) {
            durationLabel.stringValue = durationString
        }

        player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, 1), queue: DispatchQueue.main) { [weak self] time in
            self?.currentTime = time
        }
    }


    // MARK: Helpers

    private func string(for time: CMTime) -> String? {
        let (hours, minutes, seconds) = time.hoursMinutesSeconds
        let dateFormatter = DateFormatter()
        let dateString: String

        if hours.isZero {
            dateFormatter.dateFormat = "mm:ss"
            dateString = "\(minutes):\(seconds)"
        } else {
            dateFormatter.dateFormat = "HH:mm:ss"
            dateString = "\(hours):\(minutes):\(seconds)"
        }

        if let date = dateFormatter.date(from: dateString) {
            return dateFormatter.string(from: date)
        } else {
            return nil
        }
    }


    private func updateControls(for time: CMTime) {
        if let timeString = string(for: time) {
            currentTimeLabel.stringValue = timeString
        }

        if let duration = currentDuration, !duration.seconds.isZero {
            seekBar.doubleValue = time.seconds / duration.seconds
        }
    }
}
