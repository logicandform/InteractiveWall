//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MapKit
import MONode
import PromiseKit
import AppKit
import Quartz


class MapViewController: NSViewController, MKMapViewDelegate, GestureResponder, NSGestureRecognizerDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Map")

    @IBOutlet weak var mapView: FlippedMapView!
    var gestureManager: GestureManager!
    private var mapHandler: MapHandler?

    private var timeOfLastPan = Date()
    private var timeOfLastPinch = Date()
    private var schoolForCircle = [LocationOverlay: School]()

    private struct Constants {
        static let tileURL = "http:localhost:3200/{z}/{x}/{y}.pbf"
        static let annotationContainerClass = "MKNewAnnotationContainerView"
        static let maxZoomWidth: Double =  134217730
        static let annotationHitSize = CGSize(width: 50, height: 50)
        static let changeGestureTime: Double = 0.05
    }

    private struct Keys {
        static let touch = "touch"
        static let map = "mapID"
        static let school = "school"
        static let position = "position"
    }


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        setupMap()
        setupGestures()
        registerForNotifications()
    }

    override func viewWillAppear() {
//        view.window?.toggleFullScreen(nil)
    }


    // MARK: Setup

    private func setupMap() {
        mapHandler = MapHandler(mapView: mapView, id: appID)
//        mapView.register(PlaceView.self, forAnnotationViewWithReuseIdentifier: PlaceView.identifier)
//        mapView.register(ClusterView.self, forAnnotationViewWithReuseIdentifier: ClusterView.identifier)
//        let overlay = MKTileOverlay(urlTemplate: Constants.tileURL)
//        overlay.canReplaceMapContent = true
//        mapView.add(overlay)
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
        guard let pan = gesture as? PanGestureRecognizer, pan.lastTouchCount != 2, abs(timeOfLastPinch.timeIntervalSinceNow) > Constants.changeGestureTime else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var mapRect = mapView.visibleMapRect
            let translationX = Double(pan.delta.dx) * mapRect.size.width / Double(mapView.frame.width)
            let translationY = Double(pan.delta.dy) * mapRect.size.height / Double(mapView.frame.height)
            mapRect.origin -= MKMapPoint(x: translationX, y: -translationY)
            timeOfLastPan = Date()
            mapHandler?.send(mapRect, for: pan.state)
        case .ended:
            mapHandler?.endActivity()
        case .possible:
            mapHandler?.endUpdates()
        default:
            return
        }
    }

    private func didZoomOnMap(_ gesture: GestureRecognizer) {
        guard let pinch = gesture as? PinchGestureRecognizer, abs(timeOfLastPan.timeIntervalSinceNow) > Constants.changeGestureTime else {
            return
        }

        switch pinch.state {
        case .recognized, .momentum:
            var mapRect = mapView.visibleMapRect
            let scaledWidth = (2 - Double(pinch.scale)) * mapRect.size.width
            let scaledHeight = (2 - Double(pinch.scale)) * mapRect.size.height
            var translationX = -Double(pinch.delta.dx) * mapRect.size.width / Double(mapView.frame.width)
            var translationY = Double(pinch.delta.dy) * mapRect.size.height / Double(mapView.frame.height)
            if scaledWidth <= Constants.maxZoomWidth {
                translationX += (mapRect.size.width - scaledWidth) * Double(pinch.lastPosition.x / mapView.frame.width)
                translationY += (mapRect.size.height - scaledHeight) * (1 - Double(pinch.lastPosition.y / mapView.frame.height))
                mapRect.size = MKMapSize(width: scaledWidth, height: scaledHeight)
            }
            mapRect.origin += MKMapPoint(x: translationX, y: translationY)
            timeOfLastPinch = Date()
            mapHandler?.send(mapRect)
        case .ended:
            mapHandler?.endActivity()
        case .possible, .failed:
            mapHandler?.endUpdates()
        default:
            return
        }
    }

    /// If the tap is positioned on a selectable annotation, the annotation's didSelect function is invoked.
    private func didTapOnMap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, let position = tap.position, tap.state == .ended else {
            return
        }

        let locationOverlays = mapView.overlays.flatMap { $0 as? LocationOverlay }
        let mapCoordinate = mapView.convert(position, toCoordinateFrom: mapView)
        let mapPoint = MKMapPointForCoordinate(mapCoordinate)
        for location in locationOverlays {
            if MKMapRectContainsPoint(location.boundingMapRect, mapPoint), let school = schoolForCircle[location] {
                postNotification(for: school, at: position)
                return
            }
        }
    }

    /// Used to handle pan events recorded by a mouse
    @objc
    func didPanMouse(_ gesture: NSPanGestureRecognizer) {
        switch gesture.state {
        case .changed:
            mapHandler?.send(mapView.visibleMapRect, for: .system)
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
            mapHandler?.send(mapView.visibleMapRect, for: .system)
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

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let tileOverlay = overlay as? MKTileOverlay {
            return MKTileOverlayRenderer(tileOverlay: tileOverlay)
        }

        if let pathOverlay = overlay as? LocationOverlay {
            return CustomPathOverlayRenderer(overlay: pathOverlay)
        }

        return MKOverlayRenderer(overlay: overlay)
    }


    // MARK: Helpers

    private func createPlaces() {
        firstly {
            try CachingNetwork.getSchools()
        }.then { [weak self] schools in
            self?.addOverlays(for: schools)
        }.catch { error in
            print(error)
        }
    }

    private func addOverlays(for schools: [School]) {
        schools.forEach { school in
            let mapRect = MKMapRect(origin: MKMapPointForCoordinate(school.coordinate), size: MKMapSize(width: 300000, height: 300000))
            let location = LocationOverlay(coordinate: school.coordinate, mapRect: mapRect)
            schoolForCircle[location] = school
            mapView.add(location)
        }
    }

    /// Zoom into the annotations contained in the cluster
    private func didSelectAnnotationCallout(for cluster: MKClusterAnnotation) {
        let selectedAnnotations = cluster.memberAnnotations
        show(selectedAnnotations)
    }

    /// Display a place view controller on top of the selected callout annotation for the associated place.
    private func didSelectAnnotationCallout(for school: School) {
        guard let window = view.window else {
            return
        }

        let position = mapView.convert(school.coordinate, toPointTo: view) + window.frame.origin
        postNotification(for: school, at: position)
    }

    private func postNotification(for school: School, at position: CGPoint) {
        guard let window = view.window else {
            return
        }

        let location = window.frame.origin + position
        let info: JSON = [Keys.position: location.toJSON(), Keys.school: school.id]
        DistributedNotificationCenter.default().postNotificationName(WindowNotifications.school.name, object: nil, userInfo: info, deliverImmediately: true)
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
