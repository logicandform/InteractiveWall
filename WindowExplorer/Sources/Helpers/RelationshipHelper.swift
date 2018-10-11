//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


protocol RelationshipDelegate: class {
    func controllerDidClose(_ controller: BaseViewController)
    func controllerDidMove(_ controller: BaseViewController)
    func index(of controller: BaseViewController) -> Int?
    func requestUpdate(for controller: BaseViewController, animate: Bool)
}


final class RelationshipHelper: RelationshipDelegate {

    weak var parent: BaseViewController?
    var controllerClosed: ((BaseViewController) -> Void)?
    private var indexForController = [BaseViewController: Int?]()


    // MARK: API

    /// Displays a window based on the parents frame else animates it to that position
    func display(_ window: WindowType) {
        guard let parentFrame = parent?.view.window?.frame else {
            return
        }

        if let controller = controller(for: window) {
            if let position = indexForController[controller], position != nil {
                updateChildPositionsFrom(frame: parentFrame, animate: true)
                controller.view.window?.orderFront(nil)
            } else {
                indexForController[controller] = nextIndex()
                controller.updateFromParent(frame: parentFrame, animate: true)
                updateChildPositionsFrom(frame: parentFrame, animate: true)
            }
        } else if let controller = WindowManager.instance.display(window) as? BaseViewController {
            controller.parentDelegate = self
            indexForController[controller] = nextIndex()
            controller.updateFromParent(frame: parentFrame, animate: false)
            updateChildPositionsFrom(frame: parentFrame, animate: true)
        }
    }

    /// Compresses child controller indexes so their are no gaps, then updates their frame positions
    func updateChildPositionsFrom(frame: CGRect, animate: Bool) {
        let sortedControllers = indexForController.filter { $0.value != nil }.sorted { $0.value! < $1.value! }

        for (controller, _) in sortedControllers {
            reassignIndex(for: controller)
            controller.updateFromParent(frame: frame, animate: animate)
        }
    }

    func reset() {
        indexForController.keys.forEach { indexForController[$0] = nil as Int? }
    }

    func isEmpty() -> Bool {
        return indexForController.keys.isEmpty
    }


    // MARK: RelationshipDelegate

    func controllerDidClose(_ controller: BaseViewController) {
        indexForController.removeValue(forKey: controller)
        controllerClosed?(controller)
        if indexForController.isEmpty {
            parent?.closeWindowIfExpired()
        }
    }

    func controllerDidMove(_ controller: BaseViewController) {
        indexForController[controller] = nil as Int?
    }

    func index(of controller: BaseViewController) -> Int? {
        if let index = indexForController[controller], index != nil {
            return index!
        } else {
            return firstAvailablePosition()
        }
    }

    func requestUpdate(for controller: BaseViewController, animate: Bool) {
        guard let parentFrame = parent?.view.window?.frame else {
            return
        }

        controller.updateFromParent(frame: parentFrame, animate: animate)
    }


    // MARK: Helpers

    private func controller(for type: WindowType) -> BaseViewController? {
        return indexForController.keys.first(where: { $0.type == type })
    }

    private func firstAvailablePosition() -> Int {
        let currentPositions = indexForController.values

        var position = 0
        while currentPositions.contains(position) {
            position += 1
        }

        return position
    }

    /// Attempts to assign a lower available index for the given controller
    private func reassignIndex(for controller: BaseViewController) {
        let nextIndex = firstAvailablePosition()

        if let currentIndex = indexForController[controller], currentIndex != nil {
            if nextIndex < currentIndex! {
                indexForController[controller] = nextIndex
            }
        } else {
            indexForController[controller] = nextIndex
        }
    }

    private func nextIndex() -> Int {
        let currentPosition = indexForController.values.compactMap { $0 }
        if let max = currentPosition.max() {
            return max + 1
        } else {
            return 0
        }
    }
}
