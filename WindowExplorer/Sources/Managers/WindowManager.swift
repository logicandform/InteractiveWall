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

    func displayWindow(for place: Place?, from window: NSWindow) {
        let storyboard = NSStoryboard(name: PlayerViewController.storyboard, bundle: Bundle.main)
        let playerVC = storyboard.instantiateInitialController() as! PlayerViewController

        // get screen for the mapID displaying place
        let screen = NSScreen.screens[0]
        let size = PlayerViewController.size
        let windowFrame = CGRect(origin: CGPoint(x: window.frame.maxX + 20, y: window.frame.minY), size: size)
        let playerWindow = NSWindow(contentRect: windowFrame, styleMask: .borderless, backing: .buffered, defer: true, screen: screen)
        playerWindow.backgroundColor = NSColor.clear
        playerWindow.level = .statusBar
        playerWindow.contentViewController = playerVC
        playerWindow.setFrame(windowFrame, display: true)
        playerWindow.makeKeyAndOrderFront(self)
        gestureManagerForWindow[playerWindow] = playerVC.gestureManager
    }

    func remove(_ window: NSWindow) {
        gestureManagerForWindow.removeValue(forKey: window)
    }


    // MARK: SocketManagerDelegate

    func handlePacket(_ packet: Packet) {
        guard let touch = Touch(from: packet) else {
            return
        }

        convertToScreen(touch)

        // Check if the touch landed on a window, else notify the proper map application.
        if let manager = gestureManager(for: touch) {
            manager.handle(touch)
        } else {
            let map = mapOwner(of: touch) ?? calculateMap(for: touch)
            send(touch, to: map)
        }
    }

    func handleError(_ message: String) {
        print(message)
    }


    // MARK: Receiving Notifications

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
        gestureManagerForWindow[placeWindow] = placeVC.gestureManager
    }


    // MARK: Sending Notifications

    private func postNotification(for touch: Touch, to mapID: Int) {
        let info: JSON = [Keys.map: mapID, Keys.touch: touch.toJSON()]
        DistributedNotificationCenter.default().postNotificationName(TouchNotifications.touchEvent.name, object: nil, userInfo: info, deliverImmediately: true)
    }


    // MARK: Helpers

    private func gestureManager(for touch: Touch) -> GestureManager? {
        if touch.state == .down {
            if let (_, manager) = gestureManagerForWindow.first(where: { $0.0.frame.contains(touch.position) }) {
                return manager
            }
        } else {
            if let (_, manager) = gestureManagerForWindow.first(where: { $0.1.owns(touch) }) {
                return manager
            }
        }

        return nil
    }

    /// Sends a touch to the map and updates the state of the touches for map dictionary
    private func send(_ touch: Touch, to map: Int) {
        postNotification(for: touch, to: map)
        updateTouchesForMap(with: touch, for: map)
    }

    /// Updates the touches for map dictionary when a touch down or up occurs.
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

    /// Converts a position received from a touch screen to the coordinate of the current devices bounds.
    private func convertToScreen(_ touch: Touch) {
        guard let frame = NSScreen.main?.frame else {
            return
        }

        let xPos = touch.position.x / Configuration.touchScreenSize.width * CGFloat(frame.width)
        let yPos = (1 - touch.position.y / Configuration.touchScreenSize.height) * CGFloat(frame.height)
        touch.position = CGPoint(x: xPos, y: yPos)
    }

    private func mapOwner(of touch: Touch) -> Int? {
        guard let (map, _) = touchesForMapID.first(where: { $0.1.contains(touch) }) else {
            return nil
        }

        return map
    }

    /// Calculates the map index based off the x-position of the touch
    private func calculateMap(for touch: Touch) -> Int {
        precondition(touch.state == .down, "A touch with state == .moved or .down should have a map owner to use.")

        guard let frame = NSScreen.main?.frame else {
            return 1
        }

        let mapWidth = frame.width / CGFloat(Configuration.numberOfWindows)
        return Int(touch.position.x / mapWidth) + 1
    }
}
