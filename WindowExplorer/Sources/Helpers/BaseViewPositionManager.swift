//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa

protocol ControllerDelegate: class {
    func controllerDidClose(_ controller: BaseViewController)
    func controllerDidMove(_ controller: BaseViewController)
    func frameAndPosition(for controller: BaseViewController) -> (frame: CGRect, position: Int)?
}

class BaseViewPositionManager: BaseViewController {
    var controllers = [BaseViewController]()
    weak var delegate: ControllerDelegate?
    private var positionInQueue = [BaseViewController: Int?]()
    

    private struct Constants {
        static let controllerOffset = 50
    }


    // MARK: API

    func select(type: WindowType?, for controller: BaseViewController) {
        guard let type = type else {
            return
        }

        let controller = positionInQueue.keys.first(where: { $0 === controller })
        let position = getControllerPosition()

        if let controller = controller {
            // If the controller is in the correct position, bring it to the front, else animate to origin
            if let position = positionInQueue[controller], position != nil {
                controller.view.window?.makeKeyAndOrderFront(self)
            } else {
                updatePosition(animating: true)
                positionInQueue[controller] = position
            }
        } else if let controller = WindowManager.instance.display(type) as? MediaViewController {
            //Removed delegate statement here, but need it somehow
            
            // Image view controller takes care of setting its own position after its image has loaded in
            if controller is PlayerViewController || controller is PDFViewController {
                updatePosition(animating: false)
            }
            positionInQueue[controller] = position
        }
    }

    override func close() {
        delegate?.controllerDidClose(self)
        WindowManager.instance.closeWindow(for: self)
    }

    func removeFromQueue(_ controller: BaseViewController) {
        positionInQueue.removeValue(forKey: controller)
    }

    func makeNilInQueue(for controller: BaseViewController) {
        
    }

    func getValueInQueue(for controller: BaseViewController) -> Int?? {
        guard let controllerInQueue = positionInQueue.keys.first(where: { $0 === controller }) else {
            return nil
        }

        return positionInQueue[controllerInQueue]
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



    func getControllerPosition() -> Int {
        let currentPositions = positionInQueue.values

        for position in 0 ... positionInQueue.keys.count {
            if !currentPositions.contains(position) {
                return position
            }
        }

        return positionInQueue.count
    }

    // Updates the position of the controller, based on its delegates frame, and its positional ranking
    private func updatePosition(animating: Bool) {
        if let frameAndPosition = delegate?.frameAndPosition(for: self) {
            updateOrigin(from: frameAndPosition.frame, at: frameAndPosition.position, animating: animating)
        }
    }

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
