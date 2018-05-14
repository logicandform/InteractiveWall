//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


protocol MediaControllerDelegate: class {
    func controllerDidClose(_ controller: MediaViewController)
    func controllerDidMove(_ controller: MediaViewController)
    func recordFrameAndPosition(for controller: MediaViewController) -> (frame: CGRect, position: Int)?
}


class MediaViewController: BaseViewController {

    var media: Media!
    weak var delegate: MediaControllerDelegate?

    private struct Constants {
        static let controllerOffset = 50
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        windowDragAreaHighlight.layer?.backgroundColor = media.tintColor.cgColor
        titleLabel.attributedStringValue = NSAttributedString(string: media.title ?? "", attributes: style.windowTitleAttributes)
    }


    // MARK: API

    override func close() {
        delegate?.controllerDidClose(self)
        WindowManager.instance.closeWindow(for: self)
    }

    // Updates the position of the controller, based on its delegates frame, and its positional ranking
    func updatePosition(animating: Bool) {
        if let recordFrameAndPosition = delegate?.recordFrameAndPosition(for: self) {
            updateOrigin(from: recordFrameAndPosition.frame, at: recordFrameAndPosition.position, animating: animating)
        }
    }


    // MARK: Gesture Handling

    override func handleWindowPan(_ gesture: GestureRecognizer) {
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


    // MARK: Helpers

    private func updateOrigin(from recordFrame: CGRect, at position: Int, animating: Bool) {
        let offsetX = CGFloat(position * Constants.controllerOffset)
        let offsetY = CGFloat(position * -Constants.controllerOffset)
        let lastScreen = NSScreen.at(position: Configuration.numberOfScreens)
        var origin = CGPoint(x: recordFrame.maxX + style.windowMargins + offsetX, y: recordFrame.maxY + offsetY - view.frame.height)

        if origin.x > lastScreen.frame.maxX - view.frame.width / 2 {
            if lastScreen.frame.height - recordFrame.maxY < view.frame.height + style.windowMargins - 2 * offsetY {
                // Below
                origin =  CGPoint(x: lastScreen.frame.maxX - view.frame.width - style.windowMargins, y: origin.y - recordFrame.height - style.windowMargins)
            } else {
                // Above
                origin =  CGPoint(x: lastScreen.frame.maxX - view.frame.width - style.windowMargins, y: origin.y + view.frame.height + style.windowMargins - 2 * offsetY)
            }
        }

        if animating {
            animate(to: origin)
        } else {
            view.window?.setFrameOrigin(origin)
        }
    }
}
