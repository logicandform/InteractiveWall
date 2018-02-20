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
        static let annotationContainerClass = "MKNewAnnotationContainerView"
        static let maxZoomWidth: Double =  134217730
        static let annotationHitSize = CGSize(width: 50, height: 50)
    }

    @IBOutlet weak var mapView: MKMapView!
    private var activityController: ActivityController?
    private let socketManager = SocketManager(networkConfiguration: touchNetwork)
    private var gestureManager: GestureManager!


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        socketManager.delegate = self
        setupMap()
        setupGestures()
    }

    override func viewWillAppear() {
//        activityController = NetworkMapActivityController(map: mapView)
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
        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: mapView)
        tapGesture.gestureUpdated = didTapOnMap(_:)

        let panGesture = PanGestureRecognizer(withFingers: [1, 2, 3, 4, 5])
        gestureManager.add(panGesture, to: mapView)
        panGesture.gestureUpdated = mapViewDidPan(_:)

//        let pinchGesture = PinchGestureRecognizer()
//        gestureManager.add(pinchGesture, to: mapView)
//        pinchGesture.gestureUpdated = mapViewDidZoom(_:)
    }


    // MARK: Gesture handling

    private func mapViewDidPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .began:
            activityController?.beginSendingPosition()
        case .recognized, .momentum:
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
            mapView.setVisibleMapRect(mapRect, animated: false)
        case .possible, .failed:
            activityController?.stopSendingPosition()
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
            let hitFrame = CGRect(origin: CGPoint(x: annotation.frame.midX - radius, y: mapView.frame.height - annotation.frame.midY - radius), size: Constants.annotationHitSize)

            if let selectableView = annotation as? SelectableView, hitFrame.contains(position) {
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
        adjustBoundaries(of: placeVC.view)
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
        showAnnotations(annotations: selectedAnnotations)
    }

    /// Display a place view controller on top of the selected callout annotation for the associated place.
    private func didSelectAnnotationCallout(for place: Place) {
        mapView.deselectAnnotation(place, animated: false)
        displayView(for: place, from: nil)
    }

    /// Zooms into a cluster of annotations to make them more visible.
    private func showAnnotations(annotations: [MKAnnotation]) {
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
