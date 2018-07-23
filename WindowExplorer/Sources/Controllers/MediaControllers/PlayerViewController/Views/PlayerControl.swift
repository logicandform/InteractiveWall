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
    private(set) var volume = VolumeLevel.low
    private var duration = CMTime()
    private var scrubbing = false
    private var currentScrubImageUpdateNumber = 0.0
    lazy private var scrubImageUpdateTimeInterval = duration.seconds / Constants.scrubImageUpdatesPerVideo

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

    private struct Constants {
        static let seekBarInsetMargin: CGFloat = 15
        static let scrubImageUpdatesPerVideo = 20.0
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
        if scrubbing {
            return
        }

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
        scrubGesture.gestureUpdated = { [weak self] gesture in
            self?.didScrubControl(gesture)
        }

        let toggleButtonTap = TapGestureRecognizer()
        gestureManager.add(toggleButtonTap, to: toggleButton)
        toggleButtonTap.gestureUpdated = { [weak self] gesture in
            self?.didTapToggleButton(gesture)
        }

        let volumeButtonTap = TapGestureRecognizer()
        gestureManager.add(volumeButtonTap, to: volumeButton)
        volumeButtonTap.gestureUpdated = { [weak self] gesture in
            self?.didTapVolumeButton(gesture)
        }
    }


    // MARK: Gestures

    private func didScrubControl(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let position = pan.lastLocation else {
            return
        }

        switch pan.state {
        case .began:
            scrubbing = true
            player?.pause()
        case .recognized:
            let margin = Constants.seekBarInsetMargin
            let positionInSeekBar = Double((position.x - seekBar.frame.minX - margin) / (seekBar.frame.width - (margin * 2)))
            let seekPosition = clamp(positionInSeekBar, min: 0, max: 1)

            if seekBar.frame.minX <= position.x && seekBar.frame.maxX >= position.x {
                let timeInSeconds = seekPosition * duration.seconds
                currentTime = CMTime(seconds: timeInSeconds, preferredTimescale: duration.timescale)

                // This is an Int b/t 0 and scrubImageUpdatesPerVideo which gives the time that should be seeked when multipled by scrubImageUpdateTimeInterval
                let imageUpdateNumber = round(timeInSeconds / scrubImageUpdateTimeInterval)
                if imageUpdateNumber != currentScrubImageUpdateNumber {
                    currentScrubImageUpdateNumber = imageUpdateNumber
                    seek(to: currentTime)
                }
            }
        case .ended, .failed:
            seek(to: currentTime)
            if state == .playing {
                player?.play()
            }
            scrubbing = false
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
        } else if state == .finished {
            // If user drags out from end of video, set to paused
            state = .paused
        }

        if let timeString = string(for: time) {
            currentTimeLabel.stringValue = timeString
        }

        if !duration.seconds.isZero {
            seekBar.doubleValue = time.seconds / duration.seconds
        }
    }
}
