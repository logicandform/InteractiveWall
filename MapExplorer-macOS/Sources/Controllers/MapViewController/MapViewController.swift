//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MapKit
import MONode
import PromiseKit


protocol ViewManagerDelegate: class {
    func displayView(for: Place, from: NSView?)
}


class MapViewController: NSViewController, MKMapViewDelegate, ViewManagerDelegate, GestureResponder, SocketManagerDelegate {
    static let touchNetwork = NetworkConfiguration(broadcastHost: "10.0.0.255", nodePort: 12222)

    private struct Constants {
        static let tileURL = "http://tile.openstreetmap.org/{z}/{x}/{y}.png"
    }

    @IBOutlet weak var mapView: MKMapView!
    private var activityController: MapActivityController?
    private let socketManager = SocketManager(networkConfiguration: touchNetwork)
    private var gestureManager: GestureManager!
    private var initialPanningCenter: CLLocationCoordinate2D?


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        socketManager.delegate = self
        setupMap()
        setupGestures()
    }

    override func viewWillAppear() {
        view.window?.toggleFullScreen(nil)
        activityController?.resetMap()
    }


    // MARK: Setup

    func setupMap() {
        mapView.register(PlaceView.self, forAnnotationViewWithReuseIdentifier: PlaceView.identifier)
        mapView.register(ClusterView.self, forAnnotationViewWithReuseIdentifier: ClusterView.identifier)
        createMapPlaces()
        mapView.delegate = self
//        let overlay = MKTileOverlay(urlTemplate: Constants.tileURL)
//        overlay.canReplaceMapContent = true
//        mapView.add(overlay)
    }

    func setupGestures() {
        let singleFingerPan = PanGestureRecognizer()
        gestureManager.add(singleFingerPan, to: mapView)
        singleFingerPan.gestureUpdated = mapViewDidPan(_:)

        let twoFingerPan = PanGestureRecognizer(withFingers: 2)
        gestureManager.add(twoFingerPan, to: mapView)
        twoFingerPan.gestureUpdated = mapViewDidPan(_:)

        let pinchGesture = PinchGestureRecognizer()
        gestureManager.add(pinchGesture, to: mapView)
        pinchGesture.gestureUpdated = mapViewDidZoom(_:)
    }


    // MARK: Gesture handling

    private func mapViewDidPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .began:
            activityController?.beginSendingPosition()
        case .recognized:
            var mapRect = mapView.visibleMapRect
            let translationX = Double(pan.delta.dx) * mapRect.size.width / Double(mapView.frame.width)
            let translationY = Double(pan.delta.dy) * mapRect.size.height / Double(mapView.frame.height)
            mapRect.origin -= MKMapPoint(x: translationX, y: -translationY)
            mapView.setVisibleMapRect(mapRect, animated: false)
        case .possible, .failed:
            activityController?.stopSendingPosition()
        default:
            return
        }
    }

    private func mapViewDidZoom(_ gesture: GestureRecognizer) {
        guard let pinch = gesture as? PinchGestureRecognizer else {
            return
        }

        switch pinch.state {
        case .began:
            activityController?.beginSendingPosition()
        case .recognized:
            var mapRect = mapView.visibleMapRect
            let scaledWidth = (2 - Double(pinch.scale)) * mapRect.size.width
            let scaledHeight = (2 - Double(pinch.scale)) * mapRect.size.height
            let translationX = (mapRect.size.width - scaledWidth) * Double(pinch.location.x / mapView.frame.width)
            let translationY = (mapRect.size.height - scaledHeight) * (1 - Double(pinch.location.y / mapView.frame.height))
            mapRect.origin += MKMapPoint(x: translationX, y: translationY)
            mapRect.size = MKMapSize(width: scaledWidth, height: scaledHeight)
            mapView.setVisibleMapRect(mapRect, animated: false)
        case .possible, .failed:
            activityController?.stopSendingPosition()
        default:
            return
        }
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

    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        activityController = MapActivityController(map: mapView)
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

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let tileOverlay = overlay as? MKTileOverlay else {
            return MKOverlayRenderer(overlay: overlay)
        }

        return MKTileOverlayRenderer(tileOverlay: tileOverlay)
    }


    // MARK: ViewManagerDelegate

    /// Displays a child view controller on the screen with an origin offset from the providing view or nil if from an annotation.
    func displayView(for place: Place, from focus: NSView?) {
        let storyboard = NSStoryboard(name: PlaceViewController.storyboard, bundle: nil)
        let placeVC = storyboard.instantiateInitialController() as! PlaceViewController
        placeVC.gestureManager = gestureManager
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


    // MARK: Helpers

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
        let places = placesJSON.flatMap { Place(fromJSON: $0) }
        mapView.addAnnotations(places)
    }

    /// Zoom into the annotations contained in the cluster
    private func didSelectAnnotationCallout(for cluster: MKClusterAnnotation) {
        let selectedAnnotations = cluster.memberAnnotations
        mapView.showAnnotations(selectedAnnotations, animated: true)
    }

    /// Display a place view controller on top of the selected callout annotation for the associated place.
    private func didSelectAnnotationCallout(for place: Place) {
        mapView.deselectAnnotation(place, animated: false)
        displayView(for: place, from: nil)
    }
}
