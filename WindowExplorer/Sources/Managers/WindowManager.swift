//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit
import MONode


final class WindowManager {

    static let instance = WindowManager()

    private(set) var windows = [NSWindow: GestureManager]()

    private struct Keys {
        static let position = "position"
        static let place = "place"
    }


    // MARK: Init

    /// Use singleton instance
    private init() { }


    // MARK: API
 
    /// Must be done after application launches.
    func registerForNotifications() {
        for notification in WindowNotifications.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }

    func closeWindow(for controller: NSViewController) {
        if let responder = controller as? GestureResponder, let (window, _) = windows.first(where: { $0.value === responder.gestureManager }) {
            windows.removeValue(forKey: window)
            window.close()
        }
    }

    func displayWindow(for type: WindowType, at origin: CGPoint) {
        let window = WindowFactory.window(for: type, at: origin)

        if let controller = window.contentViewController as? GestureResponder {
            windows[window] = controller.gestureManager
        }
    }


    // MARK: Receiving Notifications

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo, let locationJSON = info[Keys.position] as? JSON, let location = CGPoint(json: locationJSON) else {
            return
        }

        switch notification.name {
        case WindowNotifications.place.name:
            let origin = location - CGPoint(x: WindowType.place.size.width / 2, y: WindowType.place.size.height)
            displayWindow(for: .place, at: origin)
        default:
            return
        }
    }
}
