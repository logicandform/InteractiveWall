//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MapKit
import MONode
import PromiseKit
import AppKit


class MapViewController: NSViewController, MKMapViewDelegate, GestureResponder, NSGestureRecognizerDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Map")

    @IBOutlet weak var mapView: FlippedMapView!

    var gestureManager: GestureManager!
    private var mapHandler: MapHandler?
    private let touchListener = TouchListener()
    private var recordForAnnotation = [CircleAnnotation: Record]()

    private struct Constants {
        static let tileURL = "http://localhost:4200/v2/tiles/{z}/{x}/{y}.pbf"
        static let maxZoomWidth: Double =  44739244
        static let minZoomWidth: Double = 424500
        static let touchRadius: CGFloat = 20
        static let annotationHitSize = CGSize(width: 50, height: 50)
    }

    private struct Keys {
        static let map = "map"
        static let id = "id"
        static let position = "position"
    }


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        touchListener.listenToPort(named: "MapListener\(appID)")
        touchListener.receivedTouch = { [weak self] touch in
            self?.gestureManager.handle(touch)
        }

        setupMap()
        setupGestures()
    }

    override func viewDidAppear() {
        mapHandler?.reset()
    }

    // MARK: Setup

    private func setupMap() {
        mapHandler = MapHandler(mapView: mapView, id: appID)
        let overlay = MKTileOverlay(urlTemplate: Constants.tileURL)
        overlay.canReplaceMapContent = true
        mapView.add(overlay)
        createAnnotations()
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

        let pinchGesture = PinchGestureRecognizer()
        gestureManager.add(pinchGesture, to: mapView)
        pinchGesture.gestureUpdated = didPinchOnMap(_:)
    }


    // MARK: Gesture handling

    private func didPinchOnMap(_ gesture: GestureRecognizer) {

        guard let pinch = gesture as? PinchGestureRecognizer else {
            return
        }

        switch pinch.state {
        case .recognized, .momentum:
            var mapRect = mapView.visibleMapRect
            let scaledWidth = (2 - Double(pinch.scale)) * mapRect.size.width
            let scaledHeight = (2 - Double(pinch.scale)) * mapRect.size.height
            var translationX = -Double(pinch.delta.dx) * mapRect.size.width / Double(mapView.frame.width)
            var translationY = Double(pinch.delta.dy) * mapRect.size.height / Double(mapView.frame.height)
            if scaledWidth >= Constants.minZoomWidth && scaledWidth <= Constants.maxZoomWidth {
                translationX += (mapRect.size.width - scaledWidth) * Double(pinch.center.x / mapView.frame.width)
                translationY += (mapRect.size.height - scaledHeight) * (1 - Double(pinch.center.y / mapView.frame.height))
                mapRect.size = MKMapSize(width: scaledWidth, height: scaledHeight)
            }
            mapRect.origin += MKMapPoint(x: translationX, y: translationY)
            mapHandler?.send(mapRect, for: pinch.state)
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
        guard let tap = gesture as? TapGestureRecognizer, let position = tap.position else {
            return
        }

        let touchRect = CGRect(x: position.x - Constants.touchRadius, y: position.y - Constants.touchRadius, width: Constants.touchRadius * 2, height: Constants.touchRadius * 2)
        for annotation in mapView.annotations {
            var annotationPoint = mapView.convert(annotation.coordinate, toPointTo: mapView)
            annotationPoint.y = (view.window?.frame.height)! - annotationPoint.y
            if touchRect.contains(annotationPoint) {
                if tap.state == .began {
                    if let annotationView = mapView.view(for: annotation) as? CircleAnnotationView {
                        annotationView.runAnimation()
                        return
                    }
                } else if tap.state == .ended, let annotation = annotation as? CircleAnnotation, let record = recordForAnnotation[annotation] {
                    postWindowNotification(for: record, at: CGPoint(x: annotationPoint.x, y: annotationPoint.y - 20.0))
                    return
                }
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


    // MARK: NSGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: NSGestureRecognizer) -> Bool {
        return true
    }


    // MARK: MKMapViewDelegate

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let tileOverlay = overlay as? MKTileOverlay {
            return MKTileOverlayRenderer(tileOverlay: tileOverlay)
        }

        return MKOverlayRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? CircleAnnotation {
            return CircleAnnotationView(annotation: annotation, reuseIdentifier: CircleAnnotationView.identifier)
        }

        return MKAnnotationView()
    }


    // MARK: Helpers

    private func createAnnotations() {

        // Schools
        firstly {
            try CachingNetwork.getSchools()
        }.then { [weak self] schools in
            self?.addAnnotations(for: schools)
        }.catch { error in
            print(error)
        }

        // Events
        firstly {
            try CachingNetwork.getEvents()
        }.then { [weak self] events in
            self?.addAnnotations(for: events)
        }.catch { error in
            print(error)
        }
    }

    private func addAnnotations(for records: [Record]) {
        records.forEach { record in
            let annotation = CircleAnnotation(coordinate: record.coordinate, record: record.type)
            recordForAnnotation[annotation] = record
            mapView.addAnnotation(annotation)
        }
    }

    /// Zoom into the annotations contained in the cluster
    private func didSelectAnnotationCallout(for cluster: MKClusterAnnotation) {
        let selectedAnnotations = cluster.memberAnnotations
        show(selectedAnnotations)
    }

    /// Display a place view controller on top of the selected callout annotation for the associated place.
    private func didSelectAnnotationCallout(for record: Record) {
        guard let window = view.window else {
            return
        }

        let position = mapView.convert(record.coordinate, toPointTo: view) + window.frame.origin
        postWindowNotification(for: record, at: position)
    }

    private func postWindowNotification(for record: Record, at position: CGPoint) {
        guard let window = view.window else {
            return
        }

        let location = window.frame.origin + position
        let info: JSON = [Keys.map: appID, Keys.id: record.id, Keys.position: location.toJSON()]
        DistributedNotificationCenter.default().postNotificationName(WindowNotification.with(record.type).name, object: nil, userInfo: info, deliverImmediately: true)
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
