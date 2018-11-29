//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AVKit
import MacGestures


protocol PlayerControlDelegate: class {
    func playerChangedState(_ state: PlayerState)
    func playerChangedVolume(_ state: VolumeLevel)
}


class PlayerControl: NSView {
    static let nib = "PlayerControl"

    @IBOutlet private weak var toggleButton: NSImageView!
    @IBOutlet private weak var volumeButton: NSImageView!
    @IBOutlet private weak var contentView: NSView!
    @IBOutlet private weak var seekBar: NSSlider!
    @IBOutlet private weak var currentTimeLabel: NSTextField!
    @IBOutlet private weak var durationLabel: NSTextField!

    weak var delegate: PlayerControlDelegate?
    weak var audioPlayer: AKPlayer?
    private(set) var volume = VolumeLevel.low
    private var duration = CMTime()
    private var scrubbing = false
    private var currentScrubImageUpdateNumber = 0.0
    lazy private var scrubImageUpdateTimeInterval = duration.seconds / Constants.scrubImageUpdatesPerVideo

    weak var player: AVPlayer? {
        didSet {
            setup(for: player)
        }
    }

    weak var gestureManager: GestureManager! {
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

    private var currentTime = CMTime() {
        didSet {
            updateControl(for: currentTime)
        }
    }

    private(set) var state = PlayerState.paused {
        didSet {
            toggleButton.image = state.smallImage
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
        contentView.autoresizingMask = .width
    }


    // MARK: API

    func reset() {
        setCurrentTime(for: .zero)
        seek(to: .zero)
    }

    func set(_ newState: PlayerState) {
        if state == newState {
            return
        }

        switch newState {
        case .playing:
            state = .playing
            play(at: currentTime)
        case .paused:
            state = .paused
            stopPlaying()
        case .finished:
            return
        }
    }

    func set(volume level: VolumeLevel) {
        volume = level
        volumeButton.image = volume.image
        delegate?.playerChangedVolume(volume)
    }

    func toggle() {
        if scrubbing {
            return
        }

        switch state {
        case .playing:
            state = .paused
            stopPlaying()
        case .paused:
            state = .playing
            play(at: currentTime)
        case .finished:
            state = .paused
            seek(to: .zero)
        }
    }

    func toggleVolume() {
        switch volume {
        case .mute:
            set(volume: .low)
        case .low:
            set(volume: .medium)
        case .medium:
            set(volume: .high)
        case .high:
            set(volume: .mute)
        }
    }


    // MARK: Setup

    private func setup(for player: AVPlayer?) {
        guard let player = player, let item = player.currentItem else {
            return
        }

        player.automaticallyWaitsToMinimizeStalling = false
        duration = item.asset.duration
        if let durationString = string(for: duration) {
            durationLabel.stringValue = durationString
        }

        volumeButton.image = volume.image

        player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { [weak self] time in
            self?.currentTime = time
        }
    }

    private func setupGestures() {
        let scrubGesture = PanGestureRecognizer(recognizedThreshold: 0)
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

    func didScrubControl(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let position = pan.lastLocation else {
            return
        }

        switch pan.state {
        case .began:
            scrubbing = true
            stopPlaying()
            if seekBar.frame.minX <= position.x && seekBar.frame.maxX >= position.x {
                setCurrentTime(for: position)
                seek(to: currentTime)
            }
        case .recognized:
            if seekBar.frame.minX <= position.x && seekBar.frame.maxX >= position.x {
                setCurrentTime(for: position)

                // This is an Int b/t 0 and scrubImageUpdatesPerVideo which gives the time that should be seeked when multipled by scrubImageUpdateTimeInterval
                let imageUpdateNumber = round(currentTime.seconds / scrubImageUpdateTimeInterval)
                if imageUpdateNumber != currentScrubImageUpdateNumber {
                    currentScrubImageUpdateNumber = imageUpdateNumber
                    seek(to: currentTime)
                }
            }
        case .ended, .failed:
            seek(to: currentTime)
            if state == .playing {
                play(at: currentTime)
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
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        audioPlayer?.setPosition(time.seconds)
    }

    private func play(at time: CMTime) {
        guard let player = player, state == .playing, player.status == .readyToPlay else {
            return
        }

        let loadTime = 0.5 as TimeInterval // Time to give the video and audio to load, in seconds
        let hostTime = mach_absolute_time() + UInt64(loadTime * TimeInterval(NSEC_PER_SEC))

        // Play video
        player.setRate(1, time: .invalid, atHostTime: CMClockMakeHostTimeFromSystemUnits(hostTime))

        // Play audio
        if let audioPlayer = audioPlayer {
            audioPlayer.play(from: time.seconds, to: audioPlayer.duration, at: AVAudioTime(hostTime: hostTime))
        }
    }

    private func stopPlaying() {
        player?.pause()
        audioPlayer?.stop()
    }

    private func setCurrentTime(for position: CGPoint) {
        let margin = Constants.seekBarInsetMargin
        let positionInSeekBar = Double((position.x - seekBar.frame.minX - margin) / (seekBar.frame.width - (margin * 2)))
        let seekPosition = clamp(positionInSeekBar, min: 0, max: 1)
        let timeInSeconds = seekPosition * duration.seconds
        currentTime = CMTime(seconds: timeInSeconds, preferredTimescale: duration.timescale)
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
            currentTimeLabel?.stringValue = timeString
        }

        if !duration.seconds.isZero {
            seekBar.doubleValue = time.seconds / duration.seconds
        }
    }
}
