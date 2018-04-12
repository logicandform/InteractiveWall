//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AVKit
import AppKit


class PlayerViewController: MediaViewController, PlayerControlDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Player")

    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var windowDragArea: NSView!
    @IBOutlet weak var windowDragAreaHighlight: NSView!
    @IBOutlet weak var playerControl: PlayerControl!
    @IBOutlet weak var dismissButton: NSView!
    @IBOutlet weak var playerStateImageView: AspectFillImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    
    private var audioPlayer: AKPlayer?

    private struct Constants {
        static let percentToDeallocateWindow: CGFloat = 40
    }


    // MARK: Init

    deinit {
        audioPlayer?.disconnect()
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.attributedStringValue = NSAttributedString(string: media.title ?? "", attributes: titleAttributes)

        setupPlayer()
        setupGestures()
        setupWindowDragArea()
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
            audioPlayer?.location = Double(window.frame.midX / window.screen!.visibleFrame.width)
        }

        let player = AVPlayer(url: media.url)
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

        let windowPan = PanGestureRecognizer()
        gestureManager.add(windowPan, to: windowDragArea)
        windowPan.gestureUpdated = handleWindowPan(_:)

        let singleFingerCloseButtonTap = TapGestureRecognizer()
        gestureManager.add(singleFingerCloseButtonTap, to: dismissButton)
        singleFingerCloseButtonTap.gestureUpdated = didTapCloseButton(_:)
    }

    private func setupWindowDragArea() {
        windowDragArea.wantsLayer = true
        windowDragArea.layer?.backgroundColor = style.dragAreaBackground.cgColor
        windowDragAreaHighlight.wantsLayer = true
        windowDragAreaHighlight.layer?.backgroundColor = media.tintColor.cgColor
    }


    // MARK: Gesture Handling

    private func handleWindowPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let window = view.window, !animating else {
            return
        }

        switch pan.state {
        case .began:
            delegate?.controllerDidMove(self)
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
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended, !animating else {
            return
        }

        animateViewOut()
    }

    @objc
    private func handleMousePan(_ gesture: NSPanGestureRecognizer) {
        guard let window = view.window else {
            return
        }

        var origin = window.frame.origin
        origin += gesture.translation(in: nil)
        window.setFrameOrigin(origin)
    }

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


    // MARK: GestureResponder

    /// Determines if the bounds of the draggable area is inside a given rect
    override func draggableInside(bounds: CGRect) -> Bool {
        guard let window = view.window else {
            return false
        }

        // Calculate the center box of the drag area in the window's coordinate system
        let dragAreaInWindow = windowDragArea.frame.transformed(from: view.frame).transformed(from: window.frame)
        let adjustedWidth = dragAreaInWindow.width / 2
        let smallDragArea = CGRect(x: dragAreaInWindow.minX + adjustedWidth / 2, y: dragAreaInWindow.minY, width: adjustedWidth, height: dragAreaInWindow.height)
        return bounds.contains(smallDragArea)
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
}
