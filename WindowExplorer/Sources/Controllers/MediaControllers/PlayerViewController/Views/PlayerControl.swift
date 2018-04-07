//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AVKit


protocol PlayerControlDelegate: class {
    func playerChangedState(_ state: PlayerState)
    func playerChangedVolume(_ state: VolumeLevel)
}


class PlayerControl: NSView {
    static let nib = NSNib.Name(rawValue: "PlayerControl")

    @IBOutlet weak var toggleButton: NSImageView!
    @IBOutlet weak var volumeButton: NSImageView!
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var seekBar: NSSlider!
    @IBOutlet weak var currentTimeLabel: NSTextField!
    @IBOutlet weak var durationLabel: NSTextField!

    weak var delegate: PlayerControlDelegate?
    private var duration = CMTime()
    private var volume = VolumeLevel.low

    var player: AVPlayer? {
        didSet {
            setup(for: player)
        }
    }

    var gestureManager: GestureManager! {
        didSet {
            setupGestures()
        }
    }

    var tintColor: NSColor? {
        didSet {
            if let color = tintColor, let cell = seekBar.cell as? ColoredSliderCell {
                cell.leadingColor = color
            }
        }
    }

    private var currentTime: CMTime = CMTime() {
        didSet {
            updateControl(for: currentTime)
        }
    }

    private(set) var state = PlayerState.paused {
        didSet {
            delegate?.playerChangedState(state)
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
        switch state {
        case .playing:
            state = .paused
            player?.pause()
        case .paused:
            state = .playing
            player?.play()
        case .finished:
            seek(to: CMTimeMake(0, duration.timescale))
            state = .paused
        }
    }


    // MARK: Setup

    private func setup(for player: AVPlayer?) {
        guard let player = player, let item = player.currentItem else {
            return
        }

        duration = item.asset.duration
        if let durationString = string(for: duration) {
            durationLabel.stringValue = durationString
        }

        volumeButton.image = volume.image
        delegate?.playerChangedVolume(volume)

        player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, 1), queue: DispatchQueue.main) { [weak self] time in
            self?.currentTime = time
        }
    }

    private func setupGestures() {
        let scrubGesture = PanGestureRecognizer()
        gestureManager.add(scrubGesture, to: contentView)
        scrubGesture.gestureUpdated = didScrubControl(_:)

        let toggleButtonTap = TapGestureRecognizer()
        gestureManager.add(toggleButtonTap, to: toggleButton)
        toggleButtonTap.gestureUpdated = didTapToggleButton(_:)

        let volumeButtonTap = TapGestureRecognizer()
        gestureManager.add(volumeButtonTap, to: volumeButton)
        volumeButtonTap.gestureUpdated = didTapVolumeButton(_:)
    }


    // MARK: Gestures

    private func didScrubControl(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let position = pan.lastLocation else {
            return
        }

        switch pan.state {
        case .began, .recognized:
            let seekPosition = Double((position.x - seekBar.frame.minX) / seekBar.frame.width)
            if seekBar.minValue <= seekPosition && seekPosition <= seekBar.maxValue {
                let timeInSeconds = seekPosition * duration.seconds
                let time = CMTime(seconds: timeInSeconds, preferredTimescale: duration.timescale)
                seek(to: time)
            }
        default:
            return
        }
    }

    private func didTapToggleButton(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended else {
            return
        }

        toggle()
    }

    private func didTapVolumeButton(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended else {
            return
        }

        toggleVolume()
    }


    // MARK: Helpers

    private func seek(to time: CMTime) {
        player?.seek(to: time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }

    private func toggleVolume() {
        switch volume {
        case .mute:
            volume = .low
        case .low:
            volume = .medium
        case .medium:
            volume = .high
        case .high:
            volume = .mute
        }

        volumeButton.image = volume.image
        delegate?.playerChangedVolume(volume)
    }

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
        }

        return nil
    }

    private func updateControl(for time: CMTime) {
        if currentTime == duration {
            state = .finished
        }

        if let timeString = string(for: time) {
            currentTimeLabel.stringValue = timeString
        }

        if !duration.seconds.isZero {
            seekBar.doubleValue = time.seconds / duration.seconds
        }
    }
}
