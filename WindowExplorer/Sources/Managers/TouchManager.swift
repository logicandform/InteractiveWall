//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MONode

final class TouchManager: SocketManagerDelegate {

    static let instance = TouchManager()
    static let touchNetwork = NetworkConfiguration(broadcastHost: "10.58.73.255", nodePort: 13000)

    private var socketManager: SocketManager?
    private var managersForTouch = [Touch: (NSWindow, GestureManager)]()
    private var touchesForMapID = [Int: Set<Touch>]()
    private var touchNeedsUpdate = [Touch: Bool]()


    // MARK: Init

    private init() { }
    
    
    // MARK: API

    func setupTouchSocket() {
        socketManager = SocketManager(networkConfiguration: TouchManager.touchNetwork)
        socketManager?.delegate = self
    }


    // MARK: SocketManagerDelegate

    func handlePacket(_ packet: Packet) {
        guard let touch = Touch(from: packet), shouldSend(touch) else {
            return
        }

        convert(touch, toScreen: touch.screen)

        // Check if the touch landed on a window, else notify the proper map application.
        if let manager = manager(of: touch) {
            manager.handle(touch)
        } else {
            let map = mapOwner(of: touch) ?? calculateMap(for: touch)
            send(touch, to: map)
        }
    }

    func handleError(_ message: String) {
        print(message)
    }


    // MARK: Sending CF Messages

    /// Sends a touch to the map and updates the state of the touches for map dictionary
    private func send(_ touch: Touch, to map: Int) {
        let portName = "MapListener\(map)"
        if let serverPort = CFMessagePortCreateRemote(nil, portName as CFString) {
            let touchData = touch.toData()
            CFMessagePortSendRequest(serverPort, 1, touchData as CFData, 1.0, 1.0, nil, nil)
        }
        updateTouchesForMap(with: touch, for: map)
    }


    // MARK: Helpers

    /// Calculates the manager and stores it locally for fast access to windows in the hierarchy
    private func manager(of touch: Touch) -> GestureManager? {
        switch touch.state {
        case .down:
            if let (window, manager) = calculateWindow(of: touch) {
                window.makeKeyAndOrderFront(self)
                managersForTouch[touch] = (window, manager)
                return manager
            }
        case .moved:
            if let (_, manager) = managersForTouch[touch] {
                return manager
            }
        case .up:
            if let (_, manager) = managersForTouch[touch] {
                managersForTouch.removeValue(forKey: touch)
                return manager
            }
        }

        return nil
    }

    /// Returns a gesture manager that owns the given touch, else nil.
    private func calculateWindow(of touch: Touch) -> (NSWindow, GestureManager)? {
        let windows = WindowManager.instance.windows.sorted(by: { $0.key.orderedIndex < $1.key.orderedIndex })

        if touch.state == .down {
            if let (window, manager) = windows.first(where: { $0.key.frame.contains(touch.position) }) {
                return (window, manager)
            }
        } else {
            if let (window, manager) = windows.first(where: { $0.value.owns(touch) }) {
                return (window, manager)
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
    private func convert(_ touch: Touch, toScreen screen: Int) {
        let screen = NSScreen.at(position: screen)
        let xPos = (touch.position.x / Configuration.touchScreenSize.width * CGFloat(screen.frame.width)) + screen.frame.origin.x
        let yPos = (1 - touch.position.y / Configuration.touchScreenSize.height) * CGFloat(screen.frame.height)
        touch.position = CGPoint(x: xPos, y: yPos)
    }

    private func mapOwner(of touch: Touch) -> Int? {
        guard let (mapID, _) = touchesForMapID.first(where: { $0.value.contains(touch) }) else {
            return nil
        }

        return mapID
    }

    /// Calculates the map index based off the x-position of the touch and the screens
    private func calculateMap(for touch: Touch) -> Int {
        let screen = NSScreen.at(position: touch.screen)
        let baseMapForScreen = (touch.screen - 1) * Int(Configuration.mapsPerScreen)
        let mapWidth = screen.frame.width / CGFloat(Configuration.mapsPerScreen)
        let mapForScreen = Int((touch.position.x - screen.frame.minX) / mapWidth)
        return baseMapForScreen + mapForScreen
    }

    /// Determines if a touch being sent to a map needs to be sent. To reduce the number of notifications sent, we only send every second moved event.
    private func shouldSend(_ touch: Touch) -> Bool {
        switch touch.state {
        case .down:
            touchNeedsUpdate[touch] = false
        case .up:
            touchNeedsUpdate.removeValue(forKey: touch)
        case .moved:
            if let update = touchNeedsUpdate[touch] {
                touchNeedsUpdate[touch] = !update
                return update
            }
        }

        return true
    }
}
