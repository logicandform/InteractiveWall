//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AVKit
import AppKit


class PlayerViewController: MediaViewController, PlayerControlDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Player")

    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var playerControl: PlayerControl!
    @IBOutlet weak var dismissButton: NSView!
    @IBOutlet weak var playerStateImageView: NSImageView!


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        
        setupPlayer()
        setupGestures()
        super.animateViewIn()
    }

 
    // MARK: Setup

    private func setupPlayer() {
        guard super.media.type == .video else {
            return
        }

        let player = AVPlayer(url: super.media.url)
        playerView.player = player

        playerControl.player = player
        playerControl.gestureManager = super.gestureManager
        playerControl.delegate = self

        playerStateImageView.wantsLayer = true
        playerStateImageView.layer?.cornerRadius = playerStateImageView.frame.width / 2
        playerStateImageView.layer?.backgroundColor = style.darkBackground.cgColor
    }

    private func setupGestures() {
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleMousePan(_:)))
        view.addGestureRecognizer(panGesture)

        let singleFingerPlayerTap = TapGestureRecognizer()
        gestureManager.add(singleFingerPlayerTap, to: playerView)
        singleFingerPlayerTap.gestureUpdated = didTapVideoPlayer(_:)

        let singleFingerPlayerControlTap = TapGestureRecognizer()
        gestureManager.add(singleFingerPlayerControlTap, to: playerControl.smallPlayerStateImageView)
        singleFingerPlayerControlTap.gestureUpdated = didTapVideoPlayer(_:)

        let singleFingerPan = PanGestureRecognizer()
        super.gestureManager.add(singleFingerPan, to: playerView)
        singleFingerPan.gestureUpdated = didPanDetailView(_:)

        let singleFingerCloseButtonTap = TapGestureRecognizer()
        super.gestureManager.add(singleFingerCloseButtonTap, to: dismissButton)
        singleFingerCloseButtonTap.gestureUpdated = didTapCloseButton(_:)
    }


    // MARK: Gesture Handling

    private func didTapVideoPlayer(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer else {
            return
        }

        if tap.state == .ended {
            playerControl.toggle()
        }
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

        super.animateViewOut()
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
        super.animateViewOut()
    }


    // MARK: PlayerControlDelegate

    func playerChangedState(_ state: PlayerState) {
        let alpha: CGFloat!
        if let image = state.image {
            playerStateImageView.image = image
            alpha = 1.0
        } else {
            alpha = 0.0
        }

        if let smallImage = state.smallImage {
            playerControl.smallPlayerStateImageView.image = smallImage
        }

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = 1.0
            playerStateImageView.animator().alphaValue = alpha
        })

        resetCloseWindowTimer()
    }

    override func resetCloseWindowTimer() {
        closeWindowTimer?.invalidate()
        if playerControl.state != .playing {
            closeWindowTimer = Timer.scheduledTimer(withTimeInterval: Constants.closeWindowTimeoutPeriod, repeats: false) { [weak self] _ in
                self?.animateViewOut()
            }
        }
    }
}
