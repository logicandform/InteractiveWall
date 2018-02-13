//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MONode
import MapKit


fileprivate enum UserActivity {
    case idle
    case active
}


let deviceID = Int32(1)

class MapActivityController: SocketManagerDelegate {
    static let mapNetwork = NetworkConfiguration(broadcastHost: "10.0.0.255", nodePort: 13333)

    private struct Constants {
        static let devicesPerColumn = 1
        static let masterDeviceID: Int32 = 1
        static let availableDeviceID: Int32 = 0
        static let sendPositionInterval = 1.0 / 60.0
        static let activityTimeoutPeriod: TimeInterval = 4
        static let longActivityTimeoutPeriod: TimeInterval = 10
        static let devicesPerColumnKey = "devicesInColumnPreference"
        static let initialMapOrigin = MKMapPoint(x: 11435029.807890361, y: 46239458.820914999)
        static let initialMapSize = MKMapSize(width: 105959171.60879987, height: 59602034.029949859)
    }

    private var mapView: MKMapView
    private var lastMapRect = MKMapRect()
    private let socketManager = SocketManager(networkConfiguration: mapNetwork)
    private let socketQueue = DispatchQueue(label: "socket", qos: .default)
    private var pairedDeviceID: Int32 = Constants.availableDeviceID
    private var activeDevices = Set<Int32>()
    private var userState = UserActivity.idle
    private weak var sendPositionTimer: Foundation.Timer?
    private weak var activityTimer: Foundation.Timer?
    private weak var longActivityTimer: Foundation.Timer?

    private var unpaired: Bool {
        return pairedDeviceID == Constants.availableDeviceID
    }

    private var isMasterDevice: Bool {
        return deviceID == Constants.masterDeviceID
    }

    private var devicesInColumn: Int {
        let preference = UserDefaults.standard.integer(forKey: Constants.devicesPerColumnKey)
        return preference.isZero ? Constants.devicesPerColumn : preference
    }


    // MARK: Init

    init(map: MKMapView) {
        self.mapView = map
        socketManager.delegate = self
    }


    // MARK: API

    func beginSendingPosition() {
        userState = .active
        pairedDeviceID = deviceID
        sendPositionTimer = Timer.scheduledTimer(withTimeInterval: Constants.sendPositionInterval, repeats: true) { [weak self] _ in
            self?.sendZoomAndCenter()
        }
    }

    func stopSendingPosition() {
        userState = .idle
        beginActivityTimeout()
        beginLongActivityTimeout()
        sendPositionTimer?.invalidate()
    }

    func resetMap() {
        var size = Constants.initialMapSize
        size /= Double(devicesInColumn)
        set(MKMapRect(origin: Constants.initialMapOrigin, size: size), packetID: Constants.masterDeviceID)
    }


    // MARK: SocketManagerDelegate

    func handleError(_ message: String) {
        print(message)
    }

    func handlePacket(_ packet: Packet) {
        switch packet.packetType {
        case .zoomAndCenter:
            handleZoomAndCenter(packet: packet)
        case .disconnection:
            handleDisconnection(packet: packet)
        case .reset:
            resetMap()
        default:
            break
        }
    }


    // MARK: Helpers

    /// Sets the map's position based on the sending packet id. If unpaired, will animate.
    private func set(_ mapRect: MKMapRect, packetID: Int32) {
        var newMapRect = mapRect
        let horizontalDifference = column(forDevice: deviceID) - column(forDevice: packetID)
        let verticalDifference = row(forDevice: deviceID) - row(forDevice: packetID)
        newMapRect.origin.x += mapRect.size.width * Double(horizontalDifference)
        newMapRect.origin.y += mapRect.size.height * Double(verticalDifference)
        mapView.setVisibleMapRect(newMapRect, animated: unpaired)
        lastMapRect = newMapRect
    }

    private func send(type: PacketType) {
        switch type {
        case .zoomAndCenter:
            var data = Data()
            data.append(mapView.visibleMapRect)
            socketQueue.async {
                let packet = Packet(type: .zoomAndCenter, id: deviceID, payload: data)
                self.socketManager.broadcastPacket(packet)
            }
        case .disconnection:
            var data = Data()
            data.append(mapView.visibleMapRect)
            socketQueue.async {
                let packet = Packet(type: .disconnection, id: deviceID, payload: data)
                self.socketManager.broadcastPacket(packet)
            }
        case .reset:
            socketQueue.async {
                let packet = Packet(type: .reset, id: deviceID)
                self.socketManager.broadcastPacket(packet)
            }
        default:
            print("No such packet type")
        }
    }

    private func sendZoomAndCenter() {
        let currentMapRect = mapView.visibleMapRect

        // If the mapRects are the same, do nothing
        if lastMapRect == currentMapRect {
            return
        }

        send(type: .zoomAndCenter)
        lastMapRect = currentMapRect
    }

    private func handleZoomAndCenter(packet: Packet) {
        guard packet.id != deviceID else {
            return
        }

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

    /// Remove the device from the currently active device list.
    private func handleDisconnection(packet: Packet) {
        guard packet.id != deviceID else {
            return
        }

        activeDevices.remove(packet.id)
    }

    /// Determines if the given packet should replace the paired device. Gives precedence to the current column over distance.
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

    /// Resets the pairedDeviceID after a timeout period
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
            }
        }
    }

    /// Finding the position of the device, rows and columns starting at 1 from top left
    private func column(forDevice id: Int32) -> Int {
        return (Int(id) - 1) / devicesInColumn + 1
    }

    private func row(forDevice id: Int32) -> Int {
        return (Int(id) - 1) % devicesInColumn + 1
    }
}
