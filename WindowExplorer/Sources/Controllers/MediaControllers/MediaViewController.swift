//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


protocol MediaControllerDelegate: class {
    func controllerDidClose(_ controller: MediaViewController)
    func controllerDidMove(_ controller: MediaViewController)
}


class MediaViewController: NSViewController, GestureResponder {

    @IBOutlet weak var windowDragArea: NSView!
    @IBOutlet weak var dismissButton: NSView!
    @IBOutlet weak var windowDragAreaHighlight: NSView!
    @IBOutlet weak var titleLabel: NSTextField!

    var gestureManager: GestureManager!
    var media: Media!
    var animating = false
    weak var delegate: MediaControllerDelegate?
    private weak var closeWindowTimer: Foundation.Timer?

    var titleAttributes: [NSAttributedStringKey: Any] {
        let font = NSFont(name: Constants.fontName, size: Constants.titleFontSize) ?? NSFont.systemFont(ofSize: Constants.titleFontSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        
        return [.paragraphStyle : paragraphStyle,
                .font : font,
                .foregroundColor : Constants.titleForegroundColor,
                .kern : Constants.kern]
    }

    private struct Constants {
        static let closeWindowTimeoutPeriod: TimeInterval = 300
        static let titleFontSize: CGFloat = 16
        static let titleForegroundColor: NSColor = .white
        static let kern: CGFloat = 1.5
        static let fontName = "Soleil"
        static let animationDuration = 0.5
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        gestureManager = GestureManager(responder: self)
        gestureManager.touchReceived = receivedTouch(_:)
        titleLabel.attributedStringValue = NSAttributedString(string: media.title ?? "", attributes: titleAttributes)

        setupGestures()
        setupWindowDragArea()
        resetCloseWindowTimer()
    }


    // MARK: Setup

    private func setupGestures() {
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleMousePan(_:)))
        windowDragArea.addGestureRecognizer(panGesture)

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


    // MARK: API
    
    func close() {
        delegate?.controllerDidClose(self)
        WindowManager.instance.closeWindow(for: self)
    }

    func resetCloseWindowTimer() {
        closeWindowTimer?.invalidate()
        closeWindowTimer = Timer.scheduledTimer(withTimeInterval: Constants.closeWindowTimeoutPeriod, repeats: false) { [weak self] _ in
            self?.animateViewOut()
        }
    }

    func cancelCloseWindowTime() {
        closeWindowTimer?.invalidate()
    }

    func animate(to origin: NSPoint) {
        guard let window = self.view.window, !gestureManager.isActive() else {
            return
        }

        var frame = window.frame
        frame.origin = origin
        window.makeKeyAndOrderFront(self)
        animating = true

        NSAnimationContext.runAnimationGroup({ _ in
            // TODO: Set duration as a factor of new origin vector
            NSAnimationContext.current.duration = 0.75
            NSAnimationContext.current.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            window.animator().setFrame(frame, display: true, animate: true)
        }, completionHandler: { [weak self] in
            self?.animating = false
        })
    }

    func animateViewIn() {
        view.alphaValue = 0.0
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            view.animator().alphaValue = 1.0
        })
    }

    func animateViewOut() {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            view.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.close()
        })
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
        guard let window = view.window, !animating else {
            return
        }

        resetCloseWindowTimer()
        var origin = window.frame.origin
        origin += gesture.translation(in: nil)
        window.setFrameOrigin(origin)
    }


    // MARK: GestureResponder

    /// Determines if the bounds of the draggable area is inside a given rect
    func draggableInside(bounds: CGRect) -> Bool {
        guard let window = view.window else {
            return false
        }

        // Calculate the center box of the drag area in the window's coordinate system
        let dragAreaInWindow = windowDragArea.frame.transformed(from: view.frame).transformed(from: window.frame)
        let adjustedWidth = dragAreaInWindow.width / 2
        let smallDragArea = CGRect(x: dragAreaInWindow.minX + adjustedWidth / 2, y: dragAreaInWindow.minY, width: adjustedWidth, height: dragAreaInWindow.height)
        return bounds.contains(smallDragArea)
    }


    // MARK: Helpers

    private func receivedTouch(_ touch: Touch) {
        switch touch.state {
        case .down, .up:
            resetCloseWindowTimer()
        case .moved, .indicator:
            return
        }
    }
}
