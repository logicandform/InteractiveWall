//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AVKit
import AppKit


class PlayerViewController: MediaViewController, PlayerControlDelegate, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "Player")

    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var playerControl: PlayerControl!
    @IBOutlet weak var dismissButton: NSView!

    private struct Constants {
        static let playerStateIndicatorRadius: CGFloat = 25
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        super.gestureManager = GestureManager(responder: self)

        setupPlayer()
        setupGestures()
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
    }

    private func setupGestures() {
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleMousePan(_:)))
        view.addGestureRecognizer(panGesture)

        let singleFingerTap = TapGestureRecognizer()
        super.gestureManager.add(singleFingerTap, to: playerView)
        singleFingerTap.gestureUpdated = didTapVideoPlayer(_:)

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

        super.close()
    }

    @objc
    private func handleMousePan(_ gesture: NSPanGestureRecognizer) {
        guard let window = view.window else {
            return
        }

        var origin = window.frame.origin
        origin += gesture.translation(in: nil)
        window.setFrameOrigin(origin)
        WindowManager.instance.checkBounds(of: self)
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        super.close()
    }


    // MARK: PlayerControlDelegate

    func playerChangedState(_ state: PlayerState) {
        guard let image = state.image else {
            return
        }

        let imageView = NSImageView(image: image)
        let radius = Constants.playerStateIndicatorRadius
        imageView.frame = CGRect(origin: CGPoint(x: playerView.frame.midX - radius, y: playerView.frame.midY - radius), size: CGSize(width: radius * 2, height: radius * 2))
        playerView.addSubview(imageView)

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = 1.0
            imageView.animator().alphaValue = 0.0
        }, completionHandler: {
            imageView.removeFromSuperview()
        })
    }
}
