//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MapKit
import MONode
import PromiseKit

fileprivate enum UserActivity {
    case idle
    case active
}

private let deviceID = Int32(1)

protocol ViewManagerDelegate: class {
    func displayView(for: Place, from: NSView?)
}

class MapViewController: NSViewController, MKMapViewDelegate, NSGestureRecognizerDelegate, SocketManagerDelegate, ViewManagerDelegate {
    static let config = NetworkConfiguration(broadcastHost: "192.168.1.255", nodePort: 14444)

    /// Must be updated to reflect the current configuration of devices.
    private struct Config {
        static let masterDeviceID: Int32 = 1
        static let defaultDevicesInColumn = 1
        static let singleDeviceLatitudeDelta = 40
        static let useCustomTiles = false
    }

    private struct Constants {
        static let availableDeviceID: Int32 = 0
        static let activityTimeoutPeriod: TimeInterval = 4
        static let sendMapRectInterval = 1.0 / 60.0
        static let longActivityTimeoutPeriod: TimeInterval = 10
        static let devicesInColumnKey = "devicesInColumnPreference"
        static let initialMapPoint = MKMapPoint(x: 11435029.807890361, y: 46239458.820914999)
        static let initialMapSize = MKMapSize(width: 105959171.60879987, height: 59602034.029949859)
        static let selectAnimationDuration = 0.2
        static let increaseScaleTransform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        static let decreaseScaleTransform = CGAffineTransform(scaleX: 1, y: 1)
        static let tileURL = "http://tile.openstreetmap.org/{z}/{x}/{y}.png"
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
    private var doneSetUp = false

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

    override func viewWillAppear() {
        view.window?.toggleFullScreen(nil)
        resetMap()
        doneSetUp = true
    }

    private func setupMap() {
        mapView.register(PlaceView.self, forAnnotationViewWithReuseIdentifier: PlaceView.identifier)
        mapView.register(ClusterView.self, forAnnotationViewWithReuseIdentifier: ClusterView.identifier)
        createMapPlaces()
        mapView.delegate = self
        if Config.useCustomTiles {
            let overlay = MKTileOverlay(urlTemplate: Constants.tileURL)
            overlay.canReplaceMapContent = true
            self.mapView.add(overlay)
        }
    }

    private func createMapPlaces() {
        do {
            if let file = Bundle.main.url(forResource: "MapPoints", withExtension: "json") {
                let data = try Data(contentsOf: file)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let jsonBlob = json as? [String: Any], let json = jsonBlob["locations"] as? [[String: Any]] {
                    addPlacesToMap(placesJSON: json)
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

    private func addPlacesToMap(placesJSON: [[String: Any]]) {
        var places = [Place]()

        for json in placesJSON {
            if let place = Place(fromJSON: json) {
                places.append(place)
            }
        }

        mapView.addAnnotations(places)
    }


    // MARK: MKMapViewDelegate

    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        initialized = true
    }

    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        userState = .active
        pairedDeviceID = deviceID
//        beginSendingPosition()
    }

    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        userState = .idle
//        beginActivityTimeout()
//        beginLongActivityTimeout()
//        stopSendingPosition()
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let place = annotation as? Place {
            if let placeView = mapView.dequeueReusableAnnotationView(withIdentifier: PlaceView.identifier) as? PlaceView {
                placeView.didTapCallout = didSelectAnnotationCallout(for:)
                return placeView
            } else {
                let placeView = PlaceView(annotation: place, reuseIdentifier: PlaceView.identifier)
                placeView.didTapCallout = didSelectAnnotationCallout(for:)
                return placeView
            }
        } else if let cluster = annotation as? MKClusterAnnotation {
            if let clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: ClusterView.identifier) as? ClusterView {
                clusterView.didTapCallout = didSelectAnnotationCallout(for:)
                return clusterView
            } else {
                let clusterView = ClusterView(annotation: cluster, reuseIdentifier: ClusterView.identifier)
                clusterView.didTapCallout = didSelectAnnotationCallout(for:)
                return clusterView
            }
        }

        return nil
    }

    private func didSelectAnnotationCallout(for cluster: MKClusterAnnotation) {
        let selectedAnnotations = cluster.memberAnnotations
        mapView.showAnnotations(selectedAnnotations, animated: true)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let tileOverlay = overlay as? MKTileOverlay else {
            return MKOverlayRenderer(overlay: overlay)
        }
        return MKTileOverlayRenderer(tileOverlay: tileOverlay)
    }

    /// Display a place view controller on top of the selected callout annotation for the associated place.
    private func didSelectAnnotationCallout(for place: Place) {
        mapView.deselectAnnotation(place, animated: false)
        displayView(for: place, from: nil)
    }


    // MARK: ViewManagerDelegate

    func displayView(for place: Place, from focus: NSView?) {
        let storyboard = NSStoryboard(name: PlaceViewController.storyboard, bundle: nil)
        let placeVC = storyboard.instantiateInitialController() as! PlaceViewController
        addChildViewController(placeVC)
        view.addSubview(placeVC.view)
        var origin: CGPoint

        if let focusedView = focus {
            // Displayed from subview
            origin = focusedView.frame.origin
            origin += CGVector(dx: focusedView.bounds.width + 20.0, dy: 0)
        } else {
            // Displayed from a map annotation
            origin = mapView.convert(place.coordinate, toPointTo: view)
            origin -= CGVector(dx: placeVC.view.bounds.width / 2, dy: placeVC.view.bounds.height + 10.0)
        }

        placeVC.view.frame.origin = origin
        placeVC.place = place
        placeVC.viewDelegate = self
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
        let currentMapRect = mapView.visibleMapRect

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
        mapView.setVisibleMapRect(newMapRect, animated: (unpaired && doneSetUp))
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
