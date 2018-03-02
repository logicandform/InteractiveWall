//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit
import MONode


final class WindowManager {

    static let instance = WindowManager()

    private(set) var windows = [NSWindow: GestureManager]()

    private struct Keys {
        static let screen = "screen"
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

    func remove(_ window: NSWindow) {
        windows.removeValue(forKey: window)
    }

    func displayWindow(for type: WindowType, screen: Int, at topMiddle: CGPoint) {
        if let window = WindowFactory.window(for: type, screen: screen, at: topMiddle), let controller = window.contentViewController as? GestureResponder {
            windows[window] = controller.gestureManager
        }
    }


    // MARK: Receiving Notifications

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo, let screen = info[Keys.screen] as? Int, let locationJSON = info[Keys.position] as? JSON, let location = CGPoint(json: locationJSON) else {
            return
        }

        switch notification.name {
        case WindowNotifications.place.name:
            displayWindow(for: .place, screen: screen, at: location)
        default:
            return
        }
    }
}
