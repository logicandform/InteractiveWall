//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AVKit
import AppKit


class PlayerViewController: NSViewController, PlayerControlDelegate, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "Player")

    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var playerControl: PlayerControl!
    @IBOutlet weak var videoTitle: NSTextField!
    @IBOutlet weak var dismissButton: NSView!
    @IBOutlet weak var detailView: NSView!
    
    private(set) var gestureManager: GestureManager!
    private var panGesture: NSPanGestureRecognizer!
    private var initialPanningOrigin: CGPoint?

    private struct Constants {
        static let testVideoURL = URL(fileURLWithPath: "/Users/macpro/Downloads/test-mac.mp4")
        static let playerStateIndicatorRadius: CGFloat = 25
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = #colorLiteral(red: 0.6899075147, green: 0.7701538212, blue: 0.7426613761, alpha: 0.8230652265)
        gestureManager = GestureManager(responder: self)

        setupPlayer()
        animateViewIn()
        setupGestures()
    }

 
    // MARK: Setup

    private func setupPlayer() {
        videoTitle.stringValue = Constants.testVideoURL.lastPathComponent
        let player = AVPlayer(url: Constants.testVideoURL)
        playerView.player = player

        playerControl.player = player
        playerControl.gestureManager = gestureManager
        playerControl.delegate = self
    }

    private func setupGestures() {
        panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleMousePan(_:)))
        view.addGestureRecognizer(panGesture)

        let singleFingerTap = TapGestureRecognizer()
        gestureManager.add(singleFingerTap, to: playerView)
        singleFingerTap.gestureUpdated = didTapVideoPlayer(_:)

        let singleFingerPan = PanGestureRecognizer()
        gestureManager.add(singleFingerPan, to: view)
        singleFingerPan.gestureUpdated = didPanView(_:)

        let singleFingerCloseButtonTap = TapGestureRecognizer()
        gestureManager.add(singleFingerCloseButtonTap, to: dismissButton)
        singleFingerCloseButtonTap.gestureUpdated = didTapCloseButton(_:)
    }


    // MARK: Gestures

    private func didTapVideoPlayer(_ gesture: GestureRecognizer) {
        guard gesture is TapGestureRecognizer else {
            return
        }

        playerControl.toggle()
    }

    private func didPanView(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            view.frame.origin += pan.delta
        default:
            return
        }
    }

    private func didTapCloseButton(_ gesture: GestureRecognizer) {
        guard gesture is TapGestureRecognizer else {
            return
        }

        animateViewOut()
    }

    @objc
    private func handleMousePan(_ gesture: NSPanGestureRecognizer) {
        if gesture.state == .began {
            initialPanningOrigin = view.frame.origin
            return
        }

        if var origin = initialPanningOrigin {
            origin += gesture.translation(in: view.superview)
            view.frame.origin = origin
        }
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        animateViewOut()
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


    // MARK: Helpers

    private func animateViewIn() {
        view.alphaValue = 0.0
        detailView.frame.origin.y = view.frame.size.height

        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = 0.7
            view.animator().alphaValue = 1.0
            self?.detailView.animator().frame.origin.y = 0
        })
    }

    private func animateViewOut() {
        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            if let strongSelf = self {
                NSAnimationContext.current.duration = 1.0
                strongSelf.detailView.animator().alphaValue = 0.0
                strongSelf.detailView.animator().frame.origin.y = strongSelf.view.frame.size.height
            }
        }, completionHandler: { [weak self] in
            if let strongSelf = self {
                WindowManager.instance.closeWindow(for: strongSelf.gestureManager)
            }
        })
    }
}
