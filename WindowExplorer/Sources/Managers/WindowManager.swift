//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit
import MONode
import PromiseKit

final class WindowManager {

    static let instance = WindowManager()

    private(set) var windows = [NSWindow: GestureManager]()

    private struct Keys {
        static let position = "position"
        static let school = "school"
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

    // If the none of the screens contain the detail view, dealocate it
    func checkBounds(of controller: NSViewController) {
        guard let screenIndex = controller.view.window?.screen?.index else {
            closeWindow(for: controller)
            return
        }

        var indicies = NSScreen.screens.indices

        if !Configuration.loadMapsOnFirstScreen {
            indicies.removeFirst()
        }

        if !indicies.contains(screenIndex) {
            closeWindow(for: controller)
        }
    }


    // MARK: Receiving Notifications

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo, let locationJSON = info[Keys.position] as? JSON, let location = CGPoint(json: locationJSON) else {
            return
        }

        switch notification.name {
        case WindowNotifications.school.name:
            if let schoolID = info[Keys.school] as? Int {
                displaySchool(id: schoolID, at: location)
            }
        default:
            return
        }
    }

    private func displaySchool(id: Int, at location: CGPoint) {
        firstly {
            CachingNetwork.getSchool(by: id)
        }.then { [weak self] school -> Void in
            let type = WindowType.record(school)
            let origin = location - CGPoint(x: type.size.width / 2, y: type.size.height)
            self?.displayWindow(for: type, at: origin)
        }.catch { error in
            print(error)
        }
    }
}
