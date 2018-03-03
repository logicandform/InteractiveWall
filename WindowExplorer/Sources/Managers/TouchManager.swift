//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MONode

final class TouchManager: SocketManagerDelegate {

    static let instance = TouchManager()
    static let touchNetwork = NetworkConfiguration(broadcastHost: "10.0.0.255", nodePort: 12221)

    private var socketManager: SocketManager?
    private var touchesForMapID = [Int: Set<Touch>]()

    private struct Keys {
        static let touch = "touch"
        static let map = "mapID"
    }


    // MARK: Init

    private init() { }
    
    
    // MARK: API

    func setupTouchSocket() {
        socketManager = SocketManager(networkConfiguration: TouchManager.touchNetwork)
        socketManager?.delegate = self
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


    // MARK: Sending Notifications

    /// Sends a touch to the map and updates the state of the touches for map dictionary
    private func send(_ touch: Touch, to map: Int) {
        postNotification(for: touch, to: map)
        updateTouchesForMap(with: touch, for: map)
    }

    private func postNotification(for touch: Touch, to mapID: Int) {
        let info: JSON = [Keys.map: mapID, Keys.touch: touch.toJSON()]
        DistributedNotificationCenter.default().postNotificationName(TouchNotifications.touchEvent.name, object: nil, userInfo: info, deliverImmediately: true)
    }


    // MARK: Helpers

    /// Returns a gesture manager that owns the given touch, else nil.
    private func gestureManager(for touch: Touch) -> GestureManager? {
        let windows = WindowManager.instance.windows.reversed()
        if touch.state == .down {
            if let (_, manager) = windows.first(where: { $0.0.frame.contains(touch.position) }) {
                return manager
            }
        } else {
            if let (_, manager) = windows.first(where: { $0.1.owns(touch) }) {
                return manager
            }
        }

        return nil
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
        guard let screen = NSScreen.screens.at(index: touch.screen) else {
            return
        }

        let xPos = (touch.position.x / Configuration.touchScreenSize.width * CGFloat(screen.frame.width)) + screen.frame.origin.x
        let yPos = (1 - touch.position.y / Configuration.touchScreenSize.height) * CGFloat(screen.frame.height)
        touch.position = CGPoint(x: xPos, y: yPos)
    }

    private func mapOwner(of touch: Touch) -> Int? {
        guard let (mapID, _) = touchesForMapID.first(where: { $0.1.contains(touch) }) else {
            return nil
        }

        return mapID
    }

    /// Calculates the map index based off the x-position of the touch and the screens
    private func calculateMap(for touch: Touch) -> Int {
        precondition(touch.state == .down, "A touch with state == .moved or .down should have a map owner to use.")

        guard let screen = NSScreen.screens.at(index: touch.screen) else {
            return 0
        }

        let baseMapForScreen = touch.screen * Int(Configuration.numberOfWindows)
        let mapWidth = screen.frame.width / CGFloat(Configuration.numberOfWindows)
        let mapForScreen = Int((touch.position.x - screen.frame.minX) / mapWidth)
        let offset = Configuration.loadMapsOnFirstScreen ? 0 : Configuration.numberOfWindows
        return baseMapForScreen + mapForScreen - offset
    }
}
