//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AVKit
import AppKit


class PlayerViewController: NSViewController, PlayerControlDelegate, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "Player")

    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var playerControl: PlayerControl!
    @IBOutlet weak var dismissButton: NSView!

    private(set) var gestureManager: GestureManager!
    var videoURL: URL?

    private struct Constants {
        static let testVideoURL = URL(fileURLWithPath: "/Users/imacpro/Desktop/test-mac.mp4")
        static let playerStateIndicatorRadius: CGFloat = 25
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        gestureManager = GestureManager(responder: self)

        setupPlayer()
        setupGestures()
    }

 
    // MARK: Setup

    private func setupPlayer() {
        let url = videoURL ?? Constants.testVideoURL
        let player = AVPlayer(url: url)
        playerView.player = player

        playerControl.player = player
        playerControl.gestureManager = gestureManager
        playerControl.delegate = self
    }

    private func setupGestures() {
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleMousePan(_:)))
        view.addGestureRecognizer(panGesture)

        let singleFingerTap = TapGestureRecognizer()
        gestureManager.add(singleFingerTap, to: playerView)
        singleFingerTap.gestureUpdated = didTapVideoPlayer(_:)

        let singleFingerPan = PanGestureRecognizer()
        gestureManager.add(singleFingerPan, to: playerView)
        singleFingerPan.gestureUpdated = didPanDetailView(_:)

        let singleFingerCloseButtonTap = TapGestureRecognizer()
        gestureManager.add(singleFingerCloseButtonTap, to: dismissButton)
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
        guard gesture is TapGestureRecognizer else {
            return
        }

        WindowManager.instance.closeWindow(for: self)
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
        WindowManager.instance.closeWindow(for: self)
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
