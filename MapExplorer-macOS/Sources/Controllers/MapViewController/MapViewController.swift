//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MapKit
import MONode

fileprivate enum UserActivity {
    case idle
    case active
}

private let deviceID = Int32(2)

class MapViewController: NSViewController, MKMapViewDelegate, NSGestureRecognizerDelegate, SocketManagerDelegate {
    static let config = NetworkConfiguration(broadcastHost: "192.168.1.255", nodePort: 14444)

    /// Must be updated to reflect the current configuration of devices.
    private struct Config {
        static let masterDeviceID: Int32 = 1
        static let defaultDevicesInColumn = 1
        static let singleDeviceLatitudeDelta = 40
    }

    private struct Constants {
        static let availableDeviceID: Int32 = 0
        static let activityTimeoutPeriod: TimeInterval = 4
        static let sendMapRectInterval = 1.0 / 60.0
        static let longActivityTimeoutPeriod: TimeInterval = 10
        static let devicesInColumnKey = "devicesInColumnPreference"
        static let initialMapPoint = MKMapPoint(x: 24889420.928354669, y: 47956961.545679152)
        static let initialMapSize = MKMapSize(width: 71181048.90470624, height: 53385786.67852962) // For landscape orientation
        static let selectAnimationDuration = 0.2
        static let increaseScaleTransform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        static let decreaseScaleTransform = CGAffineTransform(scaleX: 1, y: 1)

    }

    let socketManager = SocketManager(networkConfiguration: MapViewController.config)
    let socketQueue = DispatchQueue(label: "socket", qos: .default)

    private var pairedDeviceID: Int32 = Constants.availableDeviceID
    private var activeDevices = Set<Int32>()
    private var devicesInColumn: Int {
        if UserDefaults.standard.integer(forKey: Constants.devicesInColumnKey).isZero {
            return Config.defaultDevicesInColumn
        } else {
            return UserDefaults.standard.integer(forKey: Constants.devicesInColumnKey)
        }
    }

    @IBOutlet weak var mapView: MKMapView!
    private weak var sendMapRectTimer: Foundation.Timer?
    private weak var activityTimer: Foundation.Timer?
    private weak var longActivityTimer: Foundation.Timer?

    private var initialized = false
    private var lastMapRect = MKMapRect()
    private var userState = UserActivity.idle

    /// After a longActivityTimeoutPeriod this devices will reset and tell all other devices to follow
    private var isMasterDevice: Bool {
        return deviceID == Config.masterDeviceID
    }

    /// Is currently not paired to any device
    private var unpaired: Bool {
        return pairedDeviceID == Constants.availableDeviceID
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        socketManager.delegate = self
        setupMap()
    }

    private func setupMap() {
        mapView.register(CircleAnnotationView.self, forAnnotationViewWithReuseIdentifier: CircleAnnotationView.identifier)
        mapView.delegate = self
        resetMap()
    }

    private func createMapLocations() {
        do {
            if let file = Bundle.main.url(forResource: "MapPoints", withExtension: "json") {
                let data = try Data(contentsOf: file)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let jsonBlob = json as? [String: Any], let json = jsonBlob["locations"] as? [[String: Any]] {
                    addLocationsToMap(locationJSON: json)
                } else {
                    print("JSON is invalid")
                }
            } else {
                print("No file")
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    private func addLocationsToMap(locationJSON: [[String: Any]]) {
        var items = [LocationItem]()

        for location in locationJSON {
            if let item = LocationItem(fromJSON: location) {
                items.append(item)
            }
        }

        let markers = items.map { LocationAnnotation(item: $0) }
        mapView.addAnnotations(markers)
    }


    // MARK: MKMapViewDelegate

    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        initialized = true
        createMapLocations()
    }

    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        userState = .active
        pairedDeviceID = deviceID
//        beginSendingPosition()
    }

    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        userState = .idle
        beginActivityTimeout()
        beginLongActivityTimeout()
//        stopSendingPosition()
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        if let annotationView = view as? CircleAnnotationView {
//            UIView.animate(withDuration: Constants.selectAnimationDuration) {
//                annotationView.circle.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
//                annotationView.circle.transform = Constants.increaseScaleTransform
//            }
        }
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let annotationView = view as? CircleAnnotationView {
//            UIView.animate(withDuration: Constants.selectAnimationDuration) {
//                annotationView.circle.transform = Constants.decreaseScaleTransform
//                if let annotation = annotationView.annotation as? LocationAnnotation {
//                    annotationView.circle.backgroundColor = annotation.item.discipline.color
//                }
//            }
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return mapView.dequeueReusableAnnotationView(withIdentifier: CircleAnnotationView.identifier) 
    }


    // MARK: Sending packets

    func send(type: PacketType) {
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
        let currentMapRect = self.mapView.visibleMapRect

        // If the mapRects are the same, do nothing
        if lastMapRect == currentMapRect {
            return
        }

        send(type: .zoomAndCenter)
        lastMapRect = currentMapRect
    }


    // MARK: SocketManagerDelegate

    func handleError(_ message: String) {
        print(message)
    }

    func handlePacket(_ packet: Packet) {
        // Ensure packet is not from self, and the map has been initialized
        guard packet.id != deviceID || packet.packetType == .reset, initialized else {
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

    /// Resets the maps visiable rect to its initial position.
    private func resetMap() {
        let origin = Constants.initialMapPoint
        var size = Constants.initialMapSize
        size.height /= Double(devicesInColumn)
        size.width /= Double(devicesInColumn)
        let mapRect = MKMapRect(origin: origin, size: size)
        set(mapRect, packetID: Config.masterDeviceID)
    }

    /// Finding the position of the device, rows and columns starting at 1 from top left
    private func column(forDevice id: Int32) -> Int {
        return (Int(id) - 1) / devicesInColumn + 1
    }

    private func row(forDevice id: Int32) -> Int {
        return (Int(id) - 1) % devicesInColumn + 1
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
