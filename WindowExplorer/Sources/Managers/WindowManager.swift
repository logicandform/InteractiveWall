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
    private var gestureManagerForWindow = [NSWindow: GestureManager]()
    private var touchesForMapID = [Int: Set<Touch>]()

    private struct Keys {
        static let position = "position"
        static let place = "place"
        static let touch = "touch"
        static let map = "mapID"
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
    }


    // MARK: Sending Notifications

    private func postNotification(for touch: Touch, to mapID: Int) {
        let info: JSON = [Keys.map: mapID, Keys.touch: touch.toJSON()]
        DistributedNotificationCenter.default().postNotificationName(TouchNotifications.touchEvent.name, object: nil, userInfo: info, deliverImmediately: true)
    }


    // MARK: SocketManagerDelegate

    func handlePacket(_ packet: Packet) {
        guard let touch = Touch(from: packet) else {
            return
        }

        convertToScreen(touch)

        // Check if the touch landed on a window, else notify the proper MapViewController.
        if let gestureManager = gestureManager(for: touch) {
            gestureManager.handle(touch)
        } else {
            let map = mapOwner(of: touch) ?? calculateMap(for: touch)
            convert(touch, to: map)
            send(touch, to: map)
        }
    }

    func handleError(_ message: String) {
        print(message)
    }


    // MARK: Touch Handling

    private func send(_ touch: Touch, to map: Int) {
        postNotification(for: touch, to: map)
        updateTouchesForMap(with: touch, for: map)
    }

    private func updateTouchesForMap(with touch: Touch, for map: Int) {
        switch touch.state {
        case .down:
            if touchesForMapID[map] != nil {
                touchesForMapID[map]!.insert(touch)
            } else {
                touchesForMapID[map] = Set([touch])
            }
        case .up:
            if touchesForMapID[map] != nil {
                touchesForMapID[map]!.remove(touch)
            }
        case .moved:
            return
        }
    }


    // MARK: Helpers

    private func gestureManager(for touch: Touch) -> GestureManager? {
        if touch.state == .down {
            if let (_, manager) = gestureManagerForWindow.first(where: { $0.0.frame.contains(touch.position) }) {
                return manager
            }
        } else {
            if let manager = gestureManagerForWindow.values.first(where: { $0.owns(touch) }) {
                return manager
            }
        }

        return nil
    }

    /// Converts a position received from a touch screen to the coordinate of the current devices bounds.
    private func convertToScreen(_ touch: Touch) {
        guard let frame = NSScreen.main?.frame else {
            return
        }

        let xPos = touch.position.x / Configuration.touchScreenSize.width * CGFloat(frame.width)
        let yPos = (1 - touch.position.y / Configuration.touchScreenSize.height) * CGFloat(frame.height)
        touch.position = CGPoint(x: xPos, y: yPos)
    }

    /// Converts the touches x-position to the frame of the mapVC at that position.
    private func convert(_ touch: Touch, to map: Int) {
        guard let frame = NSScreen.main?.frame else {
            return
        }

        let mapWidth = frame.width / CGFloat(Configuration.numberOfWindows)
        touch.position.x -= CGFloat(map - 1) * mapWidth
    }

    private func mapOwner(of touch: Touch) -> Int? {
        guard let (map, _) = touchesForMapID.first(where: { $0.1.contains(touch) }) else {
            return nil
        }

        return map
    }

    private func calculateMap(for touch: Touch) -> Int {
        precondition(touch.state == .down, "A touch with state == .moved or .down should have a map owner to use.")

        guard let frame = NSScreen.main?.frame else {
            return 1
        }

        let mapWidth = frame.width / CGFloat(Configuration.numberOfWindows)
        return Int(touch.position.x / mapWidth) + 1
    }
}
