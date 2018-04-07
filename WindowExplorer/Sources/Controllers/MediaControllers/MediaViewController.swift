//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

protocol MediaControllerDelegate: class {
    func closeWindow(for mediaController: MediaViewController)
    func moved(for mediaController: MediaViewController)
}

class MediaViewController: NSViewController, GestureResponder {

    var gestureManager: GestureManager!
    var media: Media!
    weak var delegate: MediaControllerDelegate?
    private weak var closeWindowTimer: Foundation.Timer?
    var animating: Bool = false

    var titleAttributes: [NSAttributedStringKey: Any] {
        let font = NSFont(name: Constants.fontName, size: Constants.titleFontSize) ?? NSFont.systemFont(ofSize: Constants.titleFontSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        
        return [.paragraphStyle : paragraphStyle,
                .font : font,
                .foregroundColor : Constants.titleForegroundColor,
                .kern : Constants.kern]
    }

    var moved = false {
        willSet {
            if moved == false, newValue != moved {
                delegate?.moved(for: self)
            }
        }
    }

    private struct Constants {
        static let closeWindowTimeoutPeriod: TimeInterval = 600
        static let titleFontSize: CGFloat = 16
        static let titleForegroundColor: NSColor = .white
        static let kern: CGFloat = 1.5
        static let fontName = "Soleil"
    }

    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        gestureManager = GestureManager(responder: self)
        gestureManager.touchReceived = receivedTouch(_:)
        resetCloseWindowTimer()
    }


    // MARK: API
    
    func close() {
        delegate?.closeWindow(for: self)
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
            NSAnimationContext.current.duration = 0.5
            view.animator().alphaValue = 1.0
        })
    }

    func animateViewOut() {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = 0.5
            view.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.close()
        })
    }


    // MARK: Helpers

    private func receivedTouch(_ touch: Touch) {
        switch touch.state {
        case .down, .up:
            resetCloseWindowTimer()
        case .moved:
            return
        }
    }
}
