//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


protocol ControllerDelegate: class {
    func controllerDidClose(_ controller: BaseViewController)
    func controllerDidMove(_ controller: BaseViewController)
    func frameAndPosition(for controller: BaseViewController) -> (frame: CGRect, position: Int)?
}


class BaseViewPositionManager: BaseViewController {

    var records = [BaseViewController]()
    var positionForRecords = [BaseViewController: Int?]()
    weak var delegate: ControllerDelegate?
    

    private struct Constants {
        static let controllerOffset = 50
    }


    // MARK: API

    func add(record: BaseViewController) {
        records.append(record)
        positionForRecords[record] = nil
    }

    // Updates the position of the controller, based on its delegates frame, and its positional ranking
    func updatePosition(animating: Bool) {
        if let recordFrameAndPosition = delegate?.frameAndPosition(for: self) {
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

    func controllerDidClose(_ controller: BaseViewController) {
        guard let controller = controller as? MediaViewController else {
            return
        }

        positionForRecords.removeValue(forKey: controller)
        controller.resetCloseWindowTimer()
    }

    func controllerDidMove(_ controller: BaseViewController) {
        guard let controller = controller as? MediaViewController else {
            return
        }

        positionForRecords[controller] = nil as Int?
    }

    func frameAndPosition(for controller: BaseViewController) -> (frame: CGRect, position: Int)? {
        guard let window = view.window, let controller = controller as? MediaViewController else {
            return nil
        }

        if let position = positionForRecords[controller], position != nil {
            return (window.frame, position!)
        } else {
            return (window.frame, getControllerPosition())
        }
    }

    private func getControllerPosition() -> Int {
        let currentPositions = positionForRecords.values

        for position in 0 ... positionForRecords.keys.count {
            if !currentPositions.contains(position) {
                return position
            }
        }

        return positionForRecords.count
    }

    func updateOrigin(from recordFrame: CGRect, at position: Int, animating: Bool) {
        let offsetX = CGFloat(position * Constants.controllerOffset)
        let offsetY = CGFloat(position * -Constants.controllerOffset)
        let lastScreen = NSScreen.at(position: Configuration.numberOfScreens)
        var origin = CGPoint(x: recordFrame.maxX + style.windowMargins + offsetX, y: recordFrame.maxY + offsetY - view.frame.height)

        if origin.x > lastScreen.frame.maxX - view.frame.height / 2 {
            if lastScreen.frame.height - recordFrame.maxY < view.frame.height + style.windowMargins - 2 * offsetY {
                // Below
                origin =  CGPoint(x: lastScreen.frame.maxX - view.frame.width - style.windowMargins, y: origin.y - recordFrame.height - style.windowMargins)
            } else {
                // Above
                origin =  CGPoint(x: lastScreen.frame.maxX - view.frame.height - style.windowMargins, y: origin.y + view.frame.height + style.windowMargins - 2 * offsetY)
            }
        }

        if animating {
            animate(to: origin)
        } else {
            view.window?.setFrameOrigin(origin)
        }
    }
}
