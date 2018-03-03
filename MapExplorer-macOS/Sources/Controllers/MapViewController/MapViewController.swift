//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MapKit
import MONode
import PromiseKit
import AppKit


class MapViewController: NSViewController, MKMapViewDelegate, GestureResponder, NSGestureRecognizerDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Map")

    @IBOutlet weak var mapView: MKMapView!
    var gestureManager: GestureManager!
    private var mapHandler: MapHandler?

    private struct Constants {
        static let tileURL = "http://c.tile.stamen.com/watercolor/{z}/{x}/{y}.jpg"
        static let annotationContainerClass = "MKNewAnnotationContainerView"
        static let maxZoomWidth: Double =  134217730
        static let annotationHitSize = CGSize(width: 50, height: 50)
    }

    private struct Keys {
        static let touch = "touch"
        static let map = "mapID"
        static let place = "place"
        static let position = "position"
    }


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        setupMaps()
        setupGestures()
        registerForNotifications()
    }

    override func viewWillAppear() {
//        view.window?.toggleFullScreen(nil)
    }


    // MARK: Setup

    private func setupMaps() {
        mapHandler = MapHandler(mapView: mapView, id: appID)
        mapView.register(PlaceView.self, forAnnotationViewWithReuseIdentifier: PlaceView.identifier)
        mapView.register(ClusterView.self, forAnnotationViewWithReuseIdentifier: ClusterView.identifier)
        let overlay = MKTileOverlay(urlTemplate: Constants.tileURL)
        overlay.canReplaceMapContent = true
        mapView.add(overlay)
        createPlaces()
    }

    private func setupGestures() {
        let nsPan = NSPanGestureRecognizer(target: self, action: #selector(didPanMouse(_:)))
        nsPan.delegate = self
        mapView.addGestureRecognizer(nsPan)

        let nsPinch = NSMagnificationGestureRecognizer(target: self, action: #selector(didPinchTrackpad(_:)))
        nsPinch.delegate = self
        nsPinch.delaysMagnificationEvents = false
        mapView.addGestureRecognizer(nsPinch)

        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: mapView)
        tapGesture.gestureUpdated = didTapOnMap(_:)

        let panGesture = PanGestureRecognizer(withFingers: [1, 2, 3, 4, 5])
        gestureManager.add(panGesture, to: mapView)
        panGesture.gestureUpdated = didPanOnMap(_:)

        let pinchGesture = PinchGestureRecognizer()
        gestureManager.add(pinchGesture, to: mapView)
        pinchGesture.gestureUpdated = didZoomOnMap(_:)
    }

    private func registerForNotifications() {
        for notification in TouchNotifications.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }


    // MARK: Gesture handling

    private func didPanOnMap(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var mapRect = mapView.visibleMapRect
            let translationX = Double(pan.delta.dx) * mapRect.size.width / Double(mapView.frame.width)
            let translationY = Double(pan.delta.dy) * mapRect.size.height / Double(mapView.frame.height)
            mapRect.origin -= MKMapPoint(x: translationX, y: -translationY)
            mapHandler?.send(mapRect)
        case .possible, .failed:
            mapHandler?.endUpdates()
        default:
            return
        }
    }

    private func didZoomOnMap(_ gesture: GestureRecognizer) {
        guard let pinch = gesture as? PinchGestureRecognizer else {
            return
        }

        switch pinch.state {
        case .recognized, .momentum:
            var mapRect = mapView.visibleMapRect
            let scaledWidth = (2 - Double(pinch.scale)) * mapRect.size.width
            let scaledHeight = (2 - Double(pinch.scale)) * mapRect.size.height
            // Uncomment and delete the other two duplicate veriable below for pinch with pan gesture
            //            var translationX = -Double(pinch.delta.dx) * mapRect.size.width / Double(mapView.frame.width)
            //            var translationY = Double(pinch.delta.dy) * mapRect.size.height / Double(mapView.frame.height)
            var translationX = 0.0
            var translationY = 0.0
            if scaledWidth <= Constants.maxZoomWidth {
                translationX += (mapRect.size.width - scaledWidth) * Double(pinch.lastPosition.x / mapView.frame.width)
                translationY += (mapRect.size.height - scaledHeight) * (1 - Double(pinch.lastPosition.y / mapView.frame.height))
                mapRect.size = MKMapSize(width: scaledWidth, height: scaledHeight)
            }
            mapRect.origin += MKMapPoint(x: translationX, y: translationY)
            mapHandler?.send(mapRect)
        case .possible, .failed:
            mapHandler?.endUpdates()
        default:
            return
        }
    }

    /// If the tap is positioned on a selectable annotation, the annotation's didSelect function is invoked.
    private func didTapOnMap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, let position = tap.position, let container = mapView.subviews.first(where: { $0.className == Constants.annotationContainerClass }) else {
            return
        }

        var selected = [SelectableView]()

        for annotation in container.subviews {
            let radius = Constants.annotationHitSize.width / 2
            let hitFrame = CGRect(origin: CGPoint(x: annotation.frame.midX - radius, y: annotation.frame.midY - radius), size: Constants.annotationHitSize)

            if let selectableView = annotation as? SelectableView, hitFrame.contains(position.inverted(in: mapView)) {
                if let cluster = selectableView as? ClusterView {
                    cluster.didSelectView()
                    return
                } else {
                    selected.append(selectableView)
                }
            }
        }

        selected.first?.didSelectView()
    }

    /// Used to handle pan events recorded by a mouse
    @objc
    func didPanMouse(_ gesture: NSPanGestureRecognizer) {
        switch gesture.state {
        case .changed:
            mapHandler?.send(mapView.visibleMapRect, gestureType: .system)
        case .ended:
            mapHandler?.endUpdates()
        default:
            return
        }
    }

    /// Used to handle pinch events recorded by a trackpad
    @objc
    func didPinchTrackpad(_ gesture: NSMagnificationGestureRecognizer) {
        switch gesture.state {
        case .changed:
            mapHandler?.send(mapView.visibleMapRect, gestureType: .system)
        case .ended:
            mapHandler?.endUpdates()
        default:
            return
        }
    }


    // MARK: Notification Handling

    @objc
    private func handleNotification(_ notification: NSNotification) {
        switch notification.name {
        case TouchNotifications.touchEvent.name:
            handleTouch(notification)
        default:
            return
        }
    }

    private func handleTouch(_ notification: NSNotification) {
        guard let info = notification.userInfo, let mapID = info[Keys.map] as? Int, let touchJSON = info[Keys.touch] as? JSON, let touch = Touch(json: touchJSON) else {
            return
        }

        if mapID == appID {
            gestureManager.handle(touch)
        }
    }


    // MARK: NSGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: NSGestureRecognizer) -> Bool {
        return true
    }


    // MARK: MKMapViewDelegate

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let place = annotation as? Place {
            if let placeView = mapView.dequeueReusableAnnotationView(withIdentifier: PlaceView.identifier) as? PlaceView {
                placeView.didSelect = didSelectAnnotationCallout(for:)
                return placeView
            } else {
                let placeView = PlaceView(annotation: place, reuseIdentifier: PlaceView.identifier)
                placeView.didSelect = didSelectAnnotationCallout(for:)
                return placeView
            }
        } else if let cluster = annotation as? MKClusterAnnotation {
            if let clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: ClusterView.identifier) as? ClusterView {
                clusterView.didSelect = didSelectAnnotationCallout(for:)
                return clusterView
            } else {
                let clusterView = ClusterView(annotation: cluster, reuseIdentifier: ClusterView.identifier)
                clusterView.didSelect = didSelectAnnotationCallout(for:)
                return clusterView
            }
        }

        return nil
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let tileOverlay = overlay as? MKTileOverlay else {
            return MKOverlayRenderer(overlay: overlay)
        }

        return MKTileOverlayRenderer(tileOverlay: tileOverlay)
    }


    // MARK: Helpers

    private func createPlaces() {
        do {
            if let file = Bundle.main.url(forResource: "MapPoints", withExtension: "json") {
                let data = try Data(contentsOf: file)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let jsonBlob = json as? JSON, let placesJSON = jsonBlob["locations"] as? [JSON] {
                    add(placesJSON)
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

    private func add(_ placesJSON: [JSON]) {
        let places = placesJSON.flatMap { Place(json: $0) }
        mapView.addAnnotations(places)
    }

    /// Zoom into the annotations contained in the cluster
    private func didSelectAnnotationCallout(for cluster: MKClusterAnnotation) {
        let selectedAnnotations = cluster.memberAnnotations
        show(selectedAnnotations)
    }

    /// Display a place view controller on top of the selected callout annotation for the associated place.
    private func didSelectAnnotationCallout(for place: Place) {
        mapView.deselectAnnotation(place, animated: false)
        postNotification(for: place)
    }

    private func postNotification(for place: Place) {
        guard let window = view.window, let screen = NSScreen.screens.at(index: screenID) else {
            return
        }

        let mapWidth = screen.frame.width / CGFloat(Configuration.numberOfWindows)
        var origin = window.frame.origin
        origin += mapView.convert(place.coordinate, toPointTo: view)
        origin.x += CGFloat(appID) * mapWidth

        let info: JSON = [Keys.position: origin.toJSON(), Keys.place: place.title ?? "no title"]
        DistributedNotificationCenter.default().postNotificationName(WindowNotifications.place.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    /// Zooms into a cluster of annotations to make them more visible.
    private func show(_ annotations: [MKAnnotation]) {
        let centroid = findCenterOfAnnotations(annotations: annotations)
        let span = restrainSpan(annotations: annotations)
        let region = MKCoordinateRegion(center: centroid, span: span)
        mapView.setRegion(region, animated: true)
    }

    /// Finds the centroid of a group of annotations.
    private func findCenterOfAnnotations(annotations: [MKAnnotation]) -> CLLocationCoordinate2D {
        var centroidX = 0.0
        var centroidY = 0.0
        var count = 0.0
        for annotation in annotations {
            centroidX += annotation.coordinate.longitude
            centroidY += annotation.coordinate.latitude
            count += 1.0
        }

        centroidX /= count
        centroidY /= count
        return CLLocationCoordinate2D(latitude: centroidY, longitude: centroidX)
    }

    /// Checks if the placeView currently displayed is hidden behind the screen, and adjusts it accordingly.
    private func adjustBoundaries(of view: NSView) {
        let origin = view.frame.origin
        if origin.y < 0 {
            view.frame.origin = CGPoint(x: view.frame.origin.x, y: 15)
        }
        if origin.x < 0 {
            view.frame.origin = CGPoint(x: 15, y: view.frame.origin.y)
        }
        if view.frame.maxX > self.view.frame.maxX {
            view.frame.origin = CGPoint(x: self.view.frame.maxX - view.frame.width, y: view.frame.origin.y)
        }
    }

    /// Checks the coordinates of each annotation and returns a span that comfortably fits all annotations within the current screen view.
    private func restrainSpan(annotations: [MKAnnotation]) -> MKCoordinateSpan {
        var minX = Double.greatestFiniteMagnitude
        var minY = Double.greatestFiniteMagnitude
        var maxX = -Double.greatestFiniteMagnitude
        var maxY = -Double.greatestFiniteMagnitude

        for annotation in annotations {
            if annotation.coordinate.longitude < minX {
                minX = annotation.coordinate.longitude
            }
            if annotation.coordinate.longitude > maxX {
                maxX = annotation.coordinate.longitude
            }
            if annotation.coordinate.latitude < minY {
                minY = annotation.coordinate.latitude
            }
            if annotation.coordinate.latitude > maxY {
                maxY = annotation.coordinate.latitude
            }
        }

        let spanX = (maxX - minX) * 2
        let spanY = (maxY - minY) * 2
        return MKCoordinateSpan(latitudeDelta: spanY, longitudeDelta: spanX)
    }
}
