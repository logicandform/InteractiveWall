//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AVKit
import AppKit


class PlayerViewController: MediaViewController, PlayerControlDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Player")

    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var playerControl: PlayerControl!
    @IBOutlet weak var dismissButton: NSView!
    @IBOutlet weak var playerStateImageView: AspectFillImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    
    var audioPlayer: AKPlayer?


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
            audioPlayer?.location = Double(window.frame.midX / window.screen!.visibleFrame.width)
        }

        let player = AVPlayer(url: media.url)
        player.isMuted = true
        playerView.player = player
        scheduleAudioSegment()

        playerControl.player = player
        playerControl.gestureManager = gestureManager
        playerControl.delegate = self

        playerStateImageView.wantsLayer = true
        playerStateImageView.layer?.cornerRadius = playerStateImageView.frame.width / 2
        playerStateImageView.layer?.backgroundColor = style.darkBackground.cgColor
        
        guard let title = media.title else {
            titleLabel.stringValue = ""
            return
        }
        
        titleLabel.attributedStringValue = NSAttributedString(string: title, attributes: titleAttributes)
    }

    private func scheduleAudioSegment() {
        guard let player = playerView.player else {
            return
        }

        let syncInterval = 1.0 / 30.0
        let time = player.currentTime()
        audioPlayer?.schedule(at: time, duration: syncInterval) { [weak self] in
            DispatchQueue.global(qos: .default).async {
                self?.scheduleAudioSegment()
            }
        }
    }

    private func setupGestures() {
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleMousePan(_:)))
        view.addGestureRecognizer(panGesture)

        let singleFingerPlayerTap = TapGestureRecognizer()
        gestureManager.add(singleFingerPlayerTap, to: playerView)
        singleFingerPlayerTap.gestureUpdated = didTapVideoPlayer(_:)

        let singleFingerPlayerControlTap = TapGestureRecognizer()
        gestureManager.add(singleFingerPlayerControlTap, to: playerControl.toggleButton)
        singleFingerPlayerControlTap.gestureUpdated = didTapVideoPlayer(_:)

        let singleFingerPan = PanGestureRecognizer()
        gestureManager.add(singleFingerPan, to: playerView)
        singleFingerPan.gestureUpdated = didPanDetailView(_:)

        let singleFingerCloseButtonTap = TapGestureRecognizer()
        gestureManager.add(singleFingerCloseButtonTap, to: dismissButton)
        singleFingerCloseButtonTap.gestureUpdated = didTapCloseButton(_:)
    }


    // MARK: Gesture Handling

    private func didTapVideoPlayer(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended else {
            return
        }

        playerControl.toggle()
    }

    private func didPanDetailView(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let window = view.window else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var origin = window.frame.origin
            origin += pan.delta.round()
            window.setFrameOrigin(origin)
            // TODO: Figure out absolute location for multiple screens
            audioPlayer?.location = Double(window.frame.midX / window.screen!.visibleFrame.width)
        case .possible:
            WindowManager.instance.checkBounds(of: self)
        default:
            return
        }
    }

    private func didTapCloseButton(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended else {
            return
        }

        animateViewOut()
    }

    @objc
    private func handleMousePan(_ gesture: NSPanGestureRecognizer) {
        guard let window = view.window else {
            return
        }

        resetCloseWindowTimer()
        var origin = window.frame.origin
        origin += gesture.translation(in: nil)
        window.setFrameOrigin(origin)
        WindowManager.instance.checkBounds(of: self)
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        animateViewOut()
    }


    // MARK: PlayerControlDelegate

    func playerChangedState(_ state: PlayerState) {
        playerStateImageView.image = state.image
        playerControl.toggleButton.image = state.smallImage
        let playerStateAlpha: CGFloat = state == .playing ? 0 : 1

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = 1.0
            playerStateImageView.animator().alphaValue = playerStateAlpha
        })

        resetCloseWindowTimer()
    }
}
