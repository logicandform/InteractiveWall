//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


protocol RelationshipDelegate: class {
    func controllerDidClose(_ controller: BaseViewController)
    func controllerDidMove(_ controller: BaseViewController)
    func frameAndPosition(for controller: BaseViewController) -> (frame: CGRect, position: Int)?
}


final class RelationshipHelper: RelationshipDelegate {

    weak var parent: BaseViewController?
    private var positionForController = [BaseViewController: Int?]()


    // MARK: API

    func display(_ window: WindowType) {
        if let controller = controller(for: window) {
            if let position = positionForController[controller], position != nil {
                controller.view.window?.makeKeyAndOrderFront(self)
            } else {
                controller.updatePosition(animating: true)
                positionForController[controller] = availablePosition()
            }
        } else if let controller = WindowManager.instance.display(window) as? BaseViewController {
            controller.parentDelegate = self
            controller.updatePosition(animating: false)
            positionForController[controller] = availablePosition()
        }
    }

    func reset() {
        positionForController.keys.forEach { positionForController[$0] = nil as Int? }
    }

    func isEmpty() -> Bool {
        return positionForController.keys.isEmpty
    }


    // MARK: RelationshipDelegate

    func controllerDidClose(_ controller: BaseViewController) {
        positionForController.removeValue(forKey: controller)
        parent?.resetCloseWindowTimer()
    }

    func controllerDidMove(_ controller: BaseViewController) {
        positionForController[controller] = nil as Int?
    }

    func frameAndPosition(for controller: BaseViewController) -> (frame: CGRect, position: Int)? {
        guard let parentFrame = parent?.view.window?.frame else {
            return nil
        }

        if let position = positionForController[controller], position != nil {
            return (parentFrame, position!)
        } else {
            return (parentFrame, availablePosition())
        }
    }


    // MARK: Helpers

    private func controller(for type: WindowType) -> BaseViewController? {
        return positionForController.keys.first(where: { $0.type == type })
    }

    private func availablePosition() -> Int {
        let currentPositions = positionForController.values

        var position = 0
        while currentPositions.contains(position) {
            position += 1
        }

        return position
    }
}
