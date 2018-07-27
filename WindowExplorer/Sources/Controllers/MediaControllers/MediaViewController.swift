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

    override func updatePosition(animating: Bool) {
        if let frameAndPosition = parentDelegate?.frameAndPosition(for: self) {
            updateOrigin(from: frameAndPosition.frame, at: frameAndPosition.position, animating: animating)
        }
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


    // MARK: Helpers

    func updateOrigin(from recordFrame: CGRect, at position: Int, animating: Bool) {
        let offsetX = CGFloat(position * style.controllerOffset)
        let offsetY = CGFloat(position * -style.controllerOffset)
        let lastScreen = NSScreen.at(position: Configuration.numberOfScreens)
        var origin = CGPoint(x: recordFrame.maxX + style.windowMargins + offsetX, y: recordFrame.maxY + offsetY - view.frame.height)

        if origin.x > lastScreen.frame.maxX - view.frame.width / 2 {
            if lastScreen.frame.height - recordFrame.maxY < view.frame.height + style.windowMargins - 2 * offsetY {
                // Below
                origin = CGPoint(x: lastScreen.frame.maxX - view.frame.width - style.windowMargins, y: origin.y - recordFrame.height - style.windowMargins)
            } else {
                // Above
                origin = CGPoint(x: lastScreen.frame.maxX - view.frame.width - style.windowMargins, y: origin.y + view.frame.height + style.windowMargins - 2 * offsetY)
            }
        }

        if animating {
            animate(to: origin)
        } else {
            view.window?.setFrameOrigin(origin)
        }
    }
}
