//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MapKit
import MONode
import PromiseKit
import AppKit

protocol ViewManagerDelegate: class {
    func displayView(for: Place, from: NSView)
}


class MapViewController: NSViewController, MKMapViewDelegate, ViewManagerDelegate, GestureResponder, SocketManagerDelegate, NSGestureRecognizerDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Map")
    static let touchNetwork = NetworkConfiguration(broadcastHost: "10.0.0.255", nodePort: 12222)

    private struct Constants {
        static let numberOfMapViews = 3
        static let tileURL = "http://tile.openstreetmap.org/{z}/{x}/{y}.png"
        static let annotationContainerClass = "MKNewAnnotationContainerView"
        static let maxZoomWidth: Double =  134217730
        static let annotationHitSize = CGSize(width: 50, height: 50)
        static let numberOfScreens = 1.0
        static let initialMapOriginX = 6000000.0
        static let initialMapOriginY = 62000000.0
        static let initialMapSizeWidth = 120000000.0
        static let initialMapSizeHeight = 0.0
    }

    @IBOutlet weak var stackView: NSStackView!
    var mapViews = [MKMapView]()
    var mapManager: LocalMapManager?
    private let socketManager = SocketManager(networkConfiguration: touchNetwork)
    private var gestureManager: GestureManager!

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        socketManager.delegate = self
        setupMaps()
        setupGestures()
    }

    override func viewWillAppear() {
        view.window?.toggleFullScreen(nil)
    }

    func setupMaps() {
        stackView.subviews.flatMap { $0 as? MKMapView }.forEach { mapView in
            mapViews.append(mapView)
            mapView.register(PlaceView.self, forAnnotationViewWithReuseIdentifier: PlaceView.identifier)
            mapView.register(ClusterView.self, forAnnotationViewWithReuseIdentifier: ClusterView.identifier)
            createPlaces(for: mapView)
            mapView.delegate = self
        }
    }

    func setupGestures() {
        mapViews.forEach { mapView in
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
            panGesture.gestureUpdated = mapViewDidPan(_:)

            let pinchGesture = PinchGestureRecognizer()
            gestureManager.add(pinchGesture, to: mapView)
            pinchGesture.gestureUpdated = mapViewDidZoom(_:)
        }
    }


    // MARK: Gesture handling

    private func mapViewDidPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let mapView = gestureManager.view(for: gesture) as? MKMapView else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var mapRect = mapView.visibleMapRect
            let translationX = Double(pan.delta.dx) * mapRect.size.width / Double(mapView.frame.width)
            let translationY = Double(pan.delta.dy) * mapRect.size.height / Double(mapView.frame.height)
            mapRect.origin -= MKMapPoint(x: translationX, y: -translationY)
            mapManager?.set(mapRect, of: mapView)
        case .possible, .failed:
            mapManager?.finishedUpdating(mapView)
        default:
            return
        }
    }

    private func mapViewDidZoom(_ gesture: GestureRecognizer) {
        guard let pinch = gesture as? PinchGestureRecognizer, let mapView = gestureManager.view(for: gesture) as? MKMapView else {
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
            mapManager?.set(mapRect, of: mapView)
        case .possible, .failed:
            mapManager?.finishedUpdating(mapView)
        default:
            return
        }
    }

    /// If the tap is positioned on a selectable annotation, the annotation's didSelect function is invoked.
    private func didTapOnMap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, let position = tap.position, let mapView = gestureManager.view(for: gesture) as? MKMapView, let container = mapView.subviews.first(where: { $0.className == Constants.annotationContainerClass }) else {
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
        guard let mapView = mapViews.first(where: { $0.gestureRecognizers.contains(gesture) }) else {
            return
        }

        switch gesture.state {
        case .changed:
            mapManager?.set(mapView.visibleMapRect, of: mapView)
        case .ended:
            mapManager?.finishedUpdating(mapView)
        default:
            return
        }
    }

    /// Used to handle pinch events recorded by a trackpad
    @objc
    func didPinchTrackpad(_ gesture: NSMagnificationGestureRecognizer) {
        guard let mapView = mapViews.first(where: { $0.gestureRecognizers.contains(gesture) }) else {
            return
        }

        switch gesture.state {
        case .changed:
            mapManager?.set(mapView.visibleMapRect, of: mapView)
        case .ended:
            mapManager?.finishedUpdating(mapView)
        default:
            return
        }
    }


    // MARK: NSGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: NSGestureRecognizer) -> Bool {
        return true
    }


    // MARK: SocketManagerDelegate

    func handlePacket(_ packet: Packet) {
        guard let touch = Touch(from: packet) else {
            return
        }

        gestureManager.handle(touch)
    }

    func handleError(_ message: String) {
        print(message)
    }


    // MARK: MKMapViewDelegate

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let place = annotation as? Place {
            if let placeView = mapView.dequeueReusableAnnotationView(withIdentifier: PlaceView.identifier) as? PlaceView {
                placeView.mapView = mapView
                placeView.didSelect = didSelectAnnotationCallout(for:on:)
                return placeView
            } else {
                let placeView = PlaceView(annotation: place, reuseIdentifier: PlaceView.identifier)
                placeView.mapView = mapView
                placeView.didSelect = didSelectAnnotationCallout(for:on:)
                return placeView
            }
        } else if let cluster = annotation as? MKClusterAnnotation {
            if let clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: ClusterView.identifier) as? ClusterView {
                clusterView.mapView = mapView
                clusterView.didSelect = didSelectAnnotationCallout(for:on:)
                return clusterView
            } else {
                let clusterView = ClusterView(annotation: cluster, reuseIdentifier: ClusterView.identifier)
                clusterView.mapView = mapView
                clusterView.didSelect = didSelectAnnotationCallout(for:on:)
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


    // MARK: ViewManagerDelegate

    /// Displays a child view controller on the screen with an origin offset from the providing view or nil if from an annotation.
    func displayView(for place: Place, from focus: NSView) {
        let storyboard = NSStoryboard(name: PlaceViewController.storyboard, bundle: nil)
        let placeVC = storyboard.instantiateInitialController() as! PlaceViewController
        placeVC.gestureManager = gestureManager
        addChildViewController(placeVC)
        view.addSubview(placeVC.view)
        var origin: CGPoint

        if let mapView = focus as? MKMapView {
            // Displayed from a map annotation
            origin = mapView.convert(place.coordinate, toPointTo: view)
            origin -= CGVector(dx: placeVC.view.bounds.width / 2, dy: placeVC.view.bounds.height + 10.0)
        } else {
            // Displayed from subview
            origin = focus.frame.origin
            origin += CGVector(dx: focus.bounds.width + 20.0, dy: 0)
        }

        placeVC.view.frame.origin = origin
        adjustBoundaries(of: placeVC.view)
        placeVC.place = place
        placeVC.viewDelegate = self
    }


    // MARK: Helpers

    private func createPlaces(for mapView: MKMapView) {
        do {
            if let file = Bundle.main.url(forResource: "MapPoints", withExtension: "json") {
                let data = try Data(contentsOf: file)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let jsonBlob = json as? [String: Any], let placesJSON = jsonBlob["locations"] as? [[String: Any]] {
                    add(placesJSON, to: mapView)
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

    private func add(_ placesJSON: [[String: Any]], to mapView: MKMapView) {
        let places = placesJSON.flatMap { Place(fromJSON: $0) }
        mapView.addAnnotations(places)
    }

    /// Zoom into the annotations contained in the cluster
    private func didSelectAnnotationCallout(for cluster: MKClusterAnnotation, on mapView: MKMapView) {
        let selectedAnnotations = cluster.memberAnnotations
        show(selectedAnnotations, on: mapView)
    }

    /// Display a place view controller on top of the selected callout annotation for the associated place.
    private func didSelectAnnotationCallout(for place: Place, on mapView: MKMapView) {
        mapView.deselectAnnotation(place, animated: false)
        displayView(for: place, from: mapView)
    }

    /// Zooms into a cluster of annotations to make them more visible.
    private func show(_ annotations: [MKAnnotation], on mapView: MKMapView) {
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
}
