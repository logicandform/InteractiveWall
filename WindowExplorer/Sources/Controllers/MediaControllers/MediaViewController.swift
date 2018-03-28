//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

protocol MediaControllerDelegate: class {
    func closeWindow(for mediaController: MediaViewController)
}

class MediaViewController: NSViewController, GestureResponder {
    var gestureManager: GestureManager!
    var media: Media!
    weak var closeWindowTimer: Foundation.Timer?
    weak var delegate: MediaControllerDelegate?

    struct Constants {
        static let closeWindowTimeoutPeriod: TimeInterval = 60
    }

    override func viewDidLoad() {
        resetCloseWindowTimer()
        gestureManager = GestureManager(responder: self)
        gestureManager.touchReceived = recievedTouch(touch:)
    }
    
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

    private func recievedTouch(touch: Touch) {
        resetCloseWindowTimer()
    }
}
