//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Quartz
import AVKit
import AppKit

enum PlayerState {
    case play
    case pause
}

class PlayerViewController: NSViewController {
    static let storyboard = NSStoryboard.Name(rawValue: "Player")

    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var detailView: NSView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var closeButtonView: NSView!
    @IBOutlet weak var durationDisplay: NSTextField!
    @IBOutlet weak var sliderView: NSView!

    private struct Constants {
        static let url =  URL(fileURLWithPath: "/Users/Jeremy/Desktop/")
        static let sliderPointRadius = 0.1
    }

    private var playerState = PlayerState.pause
    private var panGesture: NSPanGestureRecognizer!
    private var initialPanningOrigin: CGPoint?
    private weak var viewDelegate: ViewManagerDelegate?
    private var currentTime: Double? {
        return playerView.player!.currentTime().seconds
    }
    private var duration: Double?
    weak var gestureManager: GestureManager!
    var endURL: String!
    var panningRatio: Double?



    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayer()
        animateViewIn()
        setupGestures()
    }


    // MARK: Setup

    private func setupPlayer() {
        view.wantsLayer = true
        view.layer?.backgroundColor = #colorLiteral(red: 0.6899075147, green: 0.7701538212, blue: 0.7426613761, alpha: 0.8230652265)
        titleLabel.stringValue = endURL

        let completeURL = Constants.url.appendingPathComponent(endURL)
        playerView.player = AVPlayer(url: completeURL)
        playerView.controlsStyle = .inline
        duration = playerView.player!.currentItem!.asset.duration.seconds
        durationDisplay.stringValue = duration!.description
        panningRatio = Double(sliderView.frame.width) / duration!
    }

    private func setupGestures() {
        panGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        view.addGestureRecognizer(panGesture)

        let singleFingerTap = TapGestureRecognizer()
        gestureManager.add(singleFingerTap, to: playerView)
        singleFingerTap.gestureUpdated = playerViewDidTap(_:)

        let singleFingerPan = PanGestureRecognizer()
        gestureManager.add(singleFingerPan, to: view)
        singleFingerPan.gestureUpdated = viewDidPan(_:)

        let singleFingerCloseButtonTap = TapGestureRecognizer()
        gestureManager.add(singleFingerCloseButtonTap, to: closeButtonView)
        singleFingerCloseButtonTap.gestureUpdated = closeButtonViewDidTap(_:)

        let singleFingerSliderPan = PanGestureRecognizer()
        gestureManager.add(singleFingerSliderPan, to: sliderView)
        singleFingerSliderPan.gestureUpdated = sliderViewDidPan(_:)
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        animateViewOut()
    }


    // MARK: Helpers

    private func animateViewIn() {
        detailView.alphaValue = 0.0
        detailView.frame.origin.y = view.frame.size.height

        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.7
            detailView.animator().alphaValue = 1.0
            detailView.animator().frame.origin.y = 0
        })
    }

    private func animateViewOut() {
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 1.0
            detailView.animator().alphaValue = 0.0
            detailView.animator().frame.origin.y = view.frame.size.height
        }, completionHandler: {
            self.view.removeFromSuperview()
        })
    }

    @objc
    private func handlePan(gesture: NSPanGestureRecognizer) {
        if gesture.state == .began {
            initialPanningOrigin = view.frame.origin
            return
        }

        if var origin = initialPanningOrigin {
            origin += gesture.translation(in: view.superview)
            view.frame.origin = origin
        }
    }

    private func playerViewDidTap(_ gesture: GestureRecognizer) {
        guard gesture is TapGestureRecognizer, let player = playerView.player else {
            return
        }

        if playerState == .play {
            player.pause()
            playerState = .pause
        } else {
            player.play()
            playerState = .play
        }
    }

    private func viewDidPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var origin = view.frame.origin
            origin += pan.delta
            view.frame.origin = origin
        default:
            return
        }
    }

    private func closeButtonViewDidTap(_ gesture: GestureRecognizer) {
        guard gesture is TapGestureRecognizer else {
            return
        }

        animateViewOut()
    }

    private func sliderViewDidPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let location = pan.location else {
            return
        }

        let pointInSlider = currentTime! / duration!
        let pointInView = Double(location.x / sliderView.frame.width)

        if pointInView + Constants.sliderPointRadius > pointInSlider && pointInView - Constants.sliderPointRadius < pointInSlider {

            switch pan.state {
            case .recognized:
                var startX = location.x
                startX += pan.delta.dx
                let dx = pan.delta.dx / sliderView.frame.width
                let timeChanged = duration! * Double(dx)
                let scale = CMTimeScale()
                let newTime = CMTime(seconds: timeChanged, preferredTimescale: scale)
                playerView.player?.seek(to: newTime)

            default:
                return


            }
        }
    }
}
