//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit
import MONode
import PromiseKit

final class WindowManager {

    static let instance = WindowManager()

    private(set) var windows = [NSWindow: GestureManager]()
    private var controllerForRecord = [RecordInfo: NSViewController]()

    private struct Keys {
        static let map = "map"
        static let id = "id"
        static let position = "position"
    }


    // MARK: Init

    /// Use singleton instance
    private init() { }


    // MARK: API
 
    /// Must be done after application launches.
    func registerForNotifications() {
        for notification in WindowNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }

    func closeWindow(for controller: NSViewController) {
        if let responder = controller as? GestureResponder, let (window, _) = windows.first(where: { $0.value === responder.gestureManager }) {
            windows.removeValue(forKey: window)
            window.close()

            if controller is RecordViewController {
                if let first = controllerForRecord.first(where: { $0.value == controller }) {
                    controllerForRecord.removeValue(forKey: first.key)
                }
            }
        }
    }

    @discardableResult
    func display(_ type: WindowType, at origin: CGPoint = .zero) -> NSViewController? {
        let window = WindowFactory.window(for: type, at: origin)

        if let controller = window.contentViewController {
            if let responder = controller as? GestureResponder {
                windows[window] = responder.gestureManager
            }

            return controller
        }

        return nil
    }

    /// If the controller is not draggable within the applications bounds, dismiss the window.
    func checkBounds(of controller: NSViewController) {
        guard let responder = controller as? GestureResponder else {
            dismissWindow(for: controller)
            return
        }

        let applicationScreens = NSScreen.screens.dropFirst()
        let first = applicationScreens.first?.frame ?? .zero
        let applicationFrame = applicationScreens.reduce(first) { $0.union($1.frame) }
        if !responder.draggableInside(bounds: applicationFrame) {
            dismissWindow(for: controller)
        }
    }

    private func dismissWindow(for controller: NSViewController) {
        if let mediaController = controller as? MediaViewController {
            mediaController.close()
        } else {
            closeWindow(for: controller)
        }
    }


    // MARK: Receiving Notifications

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let windowNotification = WindowNotification.with(notification.name), let info = notification.userInfo, let map = info[Keys.map] as? Int, let id = info[Keys.id] as? Int, let locationJSON = info[Keys.position] as? JSON, let location = CGPoint(json: locationJSON) else {
            return
        }

        RecordFactory.record(for: windowNotification.type, id: id) { [weak self] record in
            if let record = record {
                let windowType = WindowType.record(record)
                let originX = location.x - windowType.size.width / 2
                let originY = max(style.windowMargins, location.y - windowType.size.height)
                self?.display(record, at: CGPoint(x: originX, y: originY), forMap: map)
            }
        }
    }

    private func display(_ record: RecordDisplayable, at origin: CGPoint, forMap map: Int) {
        let info = RecordInfo(id: record.id, map: map, type: record.type)

        if let controller = controllerForRecord[info] as? RecordViewController {
            controller.animate(to: origin)
        } else if let controller = display(.record(record), at: origin) {
            controllerForRecord[info] = controller
        }
    }
}
