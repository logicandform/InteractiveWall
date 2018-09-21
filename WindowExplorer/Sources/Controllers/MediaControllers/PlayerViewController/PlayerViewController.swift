//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AVKit
import AppKit


class PlayerViewController: MediaViewController, PlayerControlDelegate {
    static let storyboard = "Player"

    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var playerControl: PlayerControl!
    @IBOutlet weak var playerStateImageView: NSImageView!

    private var audioPlayer: AKPlayer?


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPlayer()
        setupGestures()
        animateViewIn()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if let window = view.window {
            audioPlayer?.location = horizontalPosition(of: window)
        }
        audioPlayer?.volume = playerControl.volume.gain
        playerControl.toggle()
    }


    // MARK: Overrides

    override func resetCloseWindowTimer() {
        closeWindowTimer?.invalidate()
        if playerControl.state != .playing {
            super.resetCloseWindowTimer()
        }
    }

    override func handleWindowPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let window = view.window, !animating else {
            return
        }

        switch pan.state {
        case .began:
            parentDelegate?.controllerDidMove(self)
        case .recognized, .momentum:
            var origin = window.frame.origin
            origin += pan.delta.round()
            window.setFrameOrigin(origin)
            audioPlayer?.location = horizontalPosition(of: window)
        case .possible:
            WindowManager.instance.checkBounds(of: self)
        default:
            return
        }
    }

    override func close() {
        parentDelegate?.controllerDidClose(self)
        WindowManager.instance.closeWindow(for: self)
        audioPlayer?.disconnect()
    }

    override func updatePosition(animating: Bool) {
        super.updatePosition(animating: animating)
        if let window = view.window {
            audioPlayer?.location = horizontalPosition(of: window)
        }
    }


    // MARK: Setup

    private func setupPlayer() {
        guard media.type == .video else {
            return
        }

        let url = Configuration.localMediaURLs ? media.localURL : media.url
        let controller = AudioController.shared
        audioPlayer = controller.play(url: url)

        let player = AVPlayer(url: url)
        player.isMuted = true
        playerView.player = player

        scheduleAudioSegment()

        playerControl.player = player
        playerControl.gestureManager = gestureManager
        playerControl.tintColor = media.tintColor
        playerControl.delegate = self

        playerStateImageView.wantsLayer = true
        playerStateImageView.layer?.cornerRadius = playerStateImageView.frame.width / 2
        playerStateImageView.layer?.backgroundColor = style.darkBackground.cgColor
    }

    private func scheduleAudioSegment() {
        guard let player = playerView.player else {
            return
        }

        let time = player.currentTime()
        audioPlayer?.schedule(at: time, duration: style.audioSyncInterval) { [weak self] in
            DispatchQueue.global(qos: .default).async {
                self?.scheduleAudioSegment()
            }
        }
    }

    private func setupGestures() {
        let singleFingerPlayerTap = TapGestureRecognizer()
        gestureManager.add(singleFingerPlayerTap, to: playerView)
        singleFingerPlayerTap.gestureUpdated = { [weak self] gesture in
            self?.didTapVideoPlayer(gesture)
        }
    }


    // MARK: Gesture Handling

    private func didTapVideoPlayer(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended, !animating else {
            return
        }

        playerControl.toggle()
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        animateViewOut()
    }


    // MARK: PlayerControlDelegate

    func playerChangedState(_ state: PlayerState) {
        if let image = state.image {
            playerStateImageView.image = image
        }

        let playerStateAlpha: CGFloat = state == .playing ? 0 : 1
        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = 1
            self?.playerStateImageView.animator().alphaValue = playerStateAlpha
        })

        resetCloseWindowTimer()
    }

    func playerChangedVolume(_ state: VolumeLevel) {
        audioPlayer?.volume = state.gain
    }


    // MARK: Helpers

    /// Returns the player's horizontal location inside the application's frame from 0 -> 1
    func horizontalPosition(of window: NSWindow) -> Double {
        let minX = NSScreen.screens.dropFirst().map { $0.frame.minX }.min()!
        let maxX = NSScreen.screens.map { $0.frame.maxX }.max()!
        return Double((window.frame.midX - minX) / (maxX - minX))
    }
}
