//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit
import MONode


protocol GestureManaging {
    var gestureManager: GestureManager? { get }
}


final class WindowManager: SocketManagerDelegate {

    static let instance = WindowManager()
    static let touchNetwork = NetworkConfiguration(broadcastHost: "10.0.0.255", nodePort: 12222)

    private let socketManager = SocketManager(networkConfiguration: touchNetwork)
    private var windows = [NSWindow]()

    private struct Keys {
        static let position = "position"
        static let place = "place"
        static let touch = "touch"
    }


    // MARK: Init

    /// Use singleton instance
    private init() {
        socketManager.delegate = self
    }


    // MARK: API

    /// Must be done after application launches.
    func registerForNotifications() {
        for notification in WindowNotifications.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }


    // MARK: Notification Handling

    @objc
    private func handleNotification(_ notification: NSNotification) {
        switch notification.name {
        case WindowNotifications.place.name:
            handlePlace(notification)
        default:
            return
        }
    }

    private func handlePlace(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo, let positionJSON = userInfo[Keys.position] as? JSON, var location = CGPoint(json: positionJSON), let place = userInfo[Keys.place] as? String else {
            return
        }

        let storyboard = NSStoryboard(name: PlaceViewController.storyboard, bundle: Bundle.main)
        let placeVC = storyboard.instantiateInitialController() as! PlaceViewController
        // get screen for the mapID displaying place
        let screen = NSScreen.screens[0]
        let size = PlaceViewController.size
        location -= CGVector(dx: size.width / 2, dy: size.height)
        let windowFrame = NSRect(x: location.x, y: location.y, width: size.width, height: size.height)
        let placeWindow = NSWindow(contentRect: windowFrame, styleMask: .borderless, backing: .buffered, defer: true, screen: screen)
        placeWindow.backgroundColor = NSColor.clear
        placeWindow.level = .statusBar
        placeWindow.contentViewController = placeVC
        placeWindow.setFrame(windowFrame, display: true)
        placeWindow.makeKeyAndOrderFront(self)
        windows.append(placeWindow)
    }


    // MARK: Sending Notifications

    private func postNotification(for touch: Touch) {
        if case .touchDown = touch.state {
            convertPosition(of: touch)
        }

        let info = [Keys.touch: touch.toJSON()]
        DistributedNotificationCenter.default().postNotificationName(TouchNotifications.touchEvent.name, object: nil, userInfo: info, deliverImmediately: true)
    }


    // MARK: SocketManagerDelegate

    func handlePacket(_ packet: Packet) {
        guard let touch = Touch(from: packet) else {
            return
        }

        // Check if the touch landed on a window, else notify the proper MapViewController.
        if let gestureManager = gestureManager(for: touch) {
            gestureManager.handle(touch)
        } else {
            postNotification(for: touch)
        }
    }

    func handleError(_ message: String) {
        print(message)
    }


    // MARK: Helpers

    private func gestureManager(for touch: Touch) -> GestureManager? {
        for window in windows.reversed() {
            if window.frame.contains(touch.position), let gestureManager = gestureManager(for: window) {
                return gestureManager
            } else {
                // window has been closed, remove from array
            }
        }

        return nil
    }

    private func gestureManager(for window: NSWindow) -> GestureManager? {
        guard let gestureViewController = window.contentViewController as? GestureManaging else {
            return nil
        }

        return gestureViewController.gestureManager
    }

    /// Converts the touches x-position to the frame of the mapVC at that position.
    private func convertPosition(of touch: Touch) {
        guard let frame = NSScreen.main?.frame else {
            return
        }

        let mapWidth = frame.width / CGFloat(Configuration.numberOfWindows)
        let result = touch.position.x / mapWidth
        let xPos = mapWidth * result.truncatingRemainder(dividingBy: 1.0)
        touch.position.x = xPos
    }

}
