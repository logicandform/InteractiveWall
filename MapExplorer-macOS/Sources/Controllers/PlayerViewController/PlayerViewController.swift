//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AVKit
import AppKit


class PlayerViewController: NSViewController {
    static let storyboard = NSStoryboard.Name(rawValue: "Player")

    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var playerControl: PlayerControl!
    @IBOutlet weak var videoTitle: NSTextField!
    @IBOutlet weak var dismissButton: NSView!

    weak var gestureManager: GestureManager!
    private var panGesture: NSPanGestureRecognizer!
    private var initialPanningOrigin: CGPoint?
    private weak var viewDelegate: ViewManagerDelegate?

    private struct Constants {
        static let testVideoURL = URL(fileURLWithPath: "/Users/Tim/Downloads/test-mac.mp4")
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = #colorLiteral(red: 0.6899075147, green: 0.7701538212, blue: 0.7426613761, alpha: 0.8230652265)

        setupPlayer()
        animateViewIn()
        setupGestures()
    }


    // MARK: Setup

    private func setupPlayer() {
        // Player
        videoTitle.stringValue = Constants.testVideoURL.lastPathComponent
        let player = AVPlayer(url: Constants.testVideoURL)
        playerView.player = player

        // Controls
        playerControl.player = player
        playerControl.gestureManager = gestureManager
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


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        animateViewOut()
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


    // MARK: Helpers

    private func animateViewIn() {
        view.alphaValue = 0.0
        view.frame.origin.y = view.frame.size.height

        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.7
            view.animator().alphaValue = 1.0
            view.animator().frame.origin.y = 0
        })
    }

    private func animateViewOut() {
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 1.0
            view.animator().alphaValue = 0.0
            view.animator().frame.origin.y = view.frame.size.height
        }, completionHandler: {
            self.view.removeFromSuperview()
        })
    }
}
