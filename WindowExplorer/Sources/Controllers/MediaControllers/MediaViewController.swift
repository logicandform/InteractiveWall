//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class MediaViewController: BaseViewController {

    var media: Media!


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        windowDragAreaHighlight.layer?.backgroundColor = media.tintColor.cgColor
        titleLabel.attributedStringValue = NSAttributedString(string: media.title ?? "", attributes: style.windowTitleAttributes)
    }


    // MARK: Overrides

    override func close() {
        parentDelegate?.controllerDidClose(self)
        WindowManager.instance.closeWindow(for: self)
    }

    override func subview(contains position: CGPoint) -> Bool {
        return true
    }


    // MARK: Gesture Handling

    override func handleWindowPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let window = view.window, !animating else {
            return
        }

        switch pan.state {
        case .began:
            parentDelegate?.controllerDidMove(self)
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
}
