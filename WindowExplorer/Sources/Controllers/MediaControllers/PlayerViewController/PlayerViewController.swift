//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AVKit
import AppKit


class PlayerViewController: MediaViewController, PlayerControlDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Player")

    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var playerControl: PlayerControl!
    @IBOutlet weak var playerStateImageView: NSImageView!
    
    private var audioPlayer: AKPlayer?

    private struct Constants {
        static let percentToDeallocateWindow: CGFloat = 40
        static let audioSyncInterval = 1.0 / 30.0
    }


    // MARK: Init

    deinit {
        audioPlayer?.disconnect()
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPlayer()
        setupGestures()
        animateViewIn()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if let window = view.window, let screen = window.screen {
            audioPlayer?.location = Double(window.frame.midX / screen.visibleFrame.width)
        }
    }


    // MARK: Overrides

    override func resetCloseWindowTimer() {
        cancelCloseWindowTime()
        if playerControl.state != .playing {
            super.resetCloseWindowTimer()
        }
    }


    // MARK: Setup

    private func setupPlayer() {
        guard media.type == .video else {
            return
        }

        let contoller = AudioController.shared
        audioPlayer = contoller.play(url: media.url)
        if let window = view.window {
            audioPlayer?.location = horizontalPosition(of: window)
        }

        let player = AVPlayer(url: media.url)
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = true
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
        audioPlayer?.schedule(at: time, duration: Constants.audioSyncInterval) { [weak self] in
            DispatchQueue.global(qos: .default).async {
                self?.scheduleAudioSegment()
            }
        }
    }

    private func setupGestures() {
        let singleFingerPlayerTap = TapGestureRecognizer()
        gestureManager.add(singleFingerPlayerTap, to: playerView)
        singleFingerPlayerTap.gestureUpdated = didTapVideoPlayer(_:)
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

        playerControl.toggleButton.image = state.smallImage
        let playerStateAlpha: CGFloat = state == .playing ? 0 : 1

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = 1.0
            playerStateImageView.animator().alphaValue = playerStateAlpha
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
