// Copyright © 2017 JABT Labs Inc. All rights reserved.

import Foundation
import MONode
import C4
import MapKit

extension PacketType {
    static let zoomAndCenter = PacketType(rawValue: 123454)
    static let disconnection = PacketType(rawValue: 123456)
    static let reset = PacketType(rawValue: 123457)
}

public extension NetworkConfiguration {
    public init(broadcast: String, port: UInt16) {
        self.init()
        self.broadcastHost = broadcast
        self.nodePort = port
    }
}

extension Packet {

    func hasPrecedence(deviceID: Int32, pairedID: Int32) -> Bool {
        return abs(id - deviceID) < abs(pairedID - deviceID)
    }
}

fileprivate enum UserActivity {
    case idle
    case active
}

class Map: UniverseController, MKMapViewDelegate, UIGestureRecognizerDelegate, SocketManagerDelegate {
    static let config = NetworkConfiguration(broadcast: "192.168.1.255", port: 15150)

    private struct Constants {
        static let availableDeviceID: Int32 = 0
        static let activityTimeoutPeriod    = TimeInterval(4)
        static let sendMapRectInterval = 1.0 / 60.0
        static let longActivityTimeoutPeriod = TimeInterval(10)
        static let setupHeight = 2
        static let masterDevice: Int32 = 1
        static let effectiveHeight = setupHeight
        static let singleDeviceLatitudeDelta = 40
        static let worldHeight = MKMapSizeWorld.height
        static let initialMapPoint = MKMapPoint(x: 9081485.9989239797, y: 38924969.338196307)
        static let initialMapSize = MKMapSize(width: 56402432.446596466, height: 42301824.334947348)
    }

    // MO
    let socketManager = SocketManager(networkConfiguration: config)
    let socketQueue = DispatchQueue(label: "socket", qos: .default)

    // MapKit
    var mapView: MKMapView!
    var panGestureRecognizer: UIPanGestureRecognizer!
    var pinchGestureRecognizer: UIPinchGestureRecognizer!

    // Timers
    private weak var sendMapRectTimer: Foundation.Timer?
    private weak var activityTimer: Foundation.Timer?
    private weak var longActivityTimer: Foundation.Timer?

    private var initialized = false
    private var pairedDeviceID = Constants.availableDeviceID
    private var activeDevices = Set<Int32>()
    private var lastMapRect = MKMapRect()
    private var userState = UserActivity.idle
    private var isMasterDevice: Bool {
        return deviceID == Constants.masterDevice
    }
    private var unpaired: Bool {
        return pairedDeviceID == 0
    }

    // MARK: Setup
    
    override func setup() {
        socketManager.delegate = self
        setupMap()
    }

    private func setupMap() {
        mapView = MKMapView(frame: UIScreen.main.bounds)
        mapView.delegate = self
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        panGestureRecognizer.delegate = self
        mapView.addGestureRecognizer(panGestureRecognizer)
        mapView.isRotateEnabled = false
        canvas.add(mapView)
        resetMap()
    }


    // MARK: Gesture Handling

    @objc
    func didPan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            // Set paired device to self
            userState = .active
            pairedDeviceID = deviceID
            beginSendingPosition()
        case .ended:
            // Set timer to reset the pairedDeviceID to allow receiving packets
            userState = .idle
            beginActivityTimeout()
            beginLongActivityTimeout()
            stopSendingPosition()
        default:
            break
        }
    }
   
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }


    // MARK: MKMapViewDelegate

    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool){
        initialized = true
    }


    // MARK: Sending packets

    func send(type: PacketType) {
        switch type {
        case .zoomAndCenter:
            var data = Data()
            data.append(mapView.visibleMapRect)
            socketQueue.async {
                let packet = Packet(type: .zoomAndCenter, id: self.deviceID, payload: data)
                self.socketManager.broadcastPacket(packet)
            }
        case .disconnection:
            var data = Data()
            data.append(mapView.visibleMapRect)
            socketQueue.async {
                let packet = Packet(type: .disconnection, id: self.deviceID, payload: data)
                self.socketManager.broadcastPacket(packet)
            }
        case .reset:
            socketQueue.async {
                let packet = Packet(type: .reset, id: self.deviceID)
                self.socketManager.broadcastPacket(packet)
            }
        default:
            print("No such packet type")
        }
    }

    private func sendZoomAndCenter() {
        let mapRect = self.mapView.visibleMapRect

        // If the mapRects are the same, do nothing
        if lastMapRect.origin.x == mapRect.origin.x && lastMapRect.origin.y == mapRect.origin.y && lastMapRect.size.width == mapRect.size.width && lastMapRect.size.height == mapRect.size.height {
            return
        }

        send(type: .zoomAndCenter)
        lastMapRect = mapRect
    }


    // MARK: SocketManagerDelegate

    func handleError(_ message: String) {
        print(message)
    }
    
    func handlePacket(_ packet: Packet) {
        // If not ready or packet is from self, return
        if !initialized || packet.id == deviceID {
            return
        }

        switch packet.packetType {
        case .zoomAndCenter:
            handleZoomAndCenter(packet: packet)
            
        case .disconnection:
            activeDevices.remove(packet.id)

        case .reset:
            resetMap()
        
        default:
            break
        }
    }

    private func handleZoomAndCenter(packet: Packet) {
        // Only activates long activity timer for the master device
        beginLongActivityTimeout()
        activeDevices.insert(packet.id)

        // If unpaired, or the packet has precedence over the currently paired device
        if unpaired || shouldPair(packet) {
            pairedDeviceID = packet.id
        } else if packet.id != pairedDeviceID {
            // Ignore packets that are not the pairedDevice or father away devices
            return
        }

        // Send center coordinate in packet payload
        let data = packet.payload!
        let mapRect = data.extract(MKMapRect.self, at: 0)

        set(mapRect, packetID: packet.id)
        beginActivityTimeout()
    }


    // MARK: Helpers

    /// Sets the maps visible rect based on the sending packet id. If unpaired, will animate.
    private func set(_ mapRect: MKMapRect, packetID: Int32) {
        var newMapRect = mapRect
        let rectWidth = newMapRect.size.width
        let rectHeight = newMapRect.size.height
        let horizontalDifference = column(forDevice: deviceID) - column(forDevice: packetID)
        let verticalDifference = row(forDevice: deviceID) - row(forDevice: packetID)
        newMapRect.origin.x += rectWidth * Double(horizontalDifference)
        newMapRect.origin.y += rectHeight * Double(verticalDifference)
        mapView.setVisibleMapRect(newMapRect, animated: unpaired)
        lastMapRect = newMapRect
    }

    /// Determines if the given packet should replace the paired device. Gives precedence to the column over distance.
    private func shouldPair(_ packet: Packet) -> Bool {
        let pairedColumn = column(forDevice: pairedDeviceID)
        let packetColumn = column(forDevice: packet.id)
        let deviceColumn = column(forDevice: deviceID)
        let sameColumnDistance = abs(deviceColumn - packetColumn) == abs(deviceColumn - pairedColumn)

        if sameColumnDistance {
            return packet.hasPrecedence(deviceID: deviceID, pairedID: pairedDeviceID)
        }

        return abs(deviceColumn - packetColumn) < abs(deviceColumn - pairedColumn) ? true : false
    }

    /// Resets the pariedDeviceID after a timeout period.
    private func beginActivityTimeout() {
        activityTimer?.invalidate()
        activityTimer = Timer.scheduledTimer(withTimeInterval: Constants.activityTimeoutPeriod, repeats: false) { [weak self] _ in
            guard let strongSelf = self else {
                return
            }

            // Ensure that user is not currently panning
            if strongSelf.userState == .idle {
                strongSelf.pairedDeviceID = Constants.availableDeviceID
                strongSelf.send(type: .disconnection)
            }
        }
    }
    
    /// If running on the master device, resets all devices after a timeout period
    private func beginLongActivityTimeout() {
        guard isMasterDevice else {
            return
        }

        longActivityTimer?.invalidate()
        longActivityTimer = Timer.scheduledTimer(withTimeInterval: Constants.longActivityTimeoutPeriod, repeats: false) { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            // Ensure that user is not currently panning
            if strongSelf.userState == .idle {
                strongSelf.send(type: .reset)
                strongSelf.resetMap()
            }
        }
    }

    /// Resets the maps visiable rect to its initial position.
    private func resetMap() {
        let initialMapRect = MKMapRect(origin: Constants.initialMapPoint, size: Constants.initialMapSize)
        set(initialMapRect, packetID: Constants.masterDevice)
    }

    /// Finding the position of the device, rows and columns starting at 1 from top left
    private func column(forDevice id: Int32) -> Int {
        return (Int(id) - 1) / Constants.setupHeight + 1
    }

    private func row(forDevice id: Int32) -> Int {
        return (Int(id) - 1) % Constants.setupHeight + 1
    }

    private func beginSendingPosition() {
        sendMapRectTimer = Timer.scheduledTimer(withTimeInterval: Constants.sendMapRectInterval, repeats: true) { [weak self] _ in
            self?.sendZoomAndCenter()
        }
    }

    private func stopSendingPosition() {
        sendMapRectTimer?.invalidate()
    }
}
