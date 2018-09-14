//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MapKit
import MONode
import PromiseKit
import AppKit


struct MapConstants {
    static let canadaRect = MKMapRect(origin: MKMapPoint(x: 23000000, y: 25000000), size: MKMapSize(width: 160000000, height: 0))
}


class MapViewController: NSViewController, MKMapViewDelegate, GestureResponder, NSGestureRecognizerDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Map")

    @IBOutlet weak var mapView: MapViewWithMiniMap!

    var gestureManager: GestureManager!
    private var mapHandler: MapHandler?
    private var recordForAnnotation = [CircleAnnotation: Record]()
    private var showingAnnotationTitles = false
    private var currentSettings = Settings()

    private var tileURL: String {
        let tileID = max(screenID, 1)
        return "http://\(Configuration.serverIP):4\(tileID)00/v2/tiles/{z}/{x}/{y}.pbf"
    }

    private struct Constants {
        static let maxZoomWidth = Double(160000000 / Configuration.appsPerScreen)
        static let minZoomWidth = 424500.0
        static let touchRadius: CGFloat = 20
        static let annotationHitSize = CGSize(width: 50, height: 50)
        static let doubleTapScale = 0.5
        static let annotationTitleZoomLevel = Double(92000000 / Configuration.appsPerScreen)
        static let spacingBetweenAnnotations = 0.008
        static let coordinateToMapPointOriginOffset = 180.0
    }

    private struct Keys {
        static let id = "id"
        static let app = "app"
        static let type = "type"
        static let group = "group"
        static let status = "status"
        static let position = "position"
        static let settings = "settings"
        static let recordType = "recordType"
    }


    // MARK: Init

    static func instance() -> MapViewController {
        let storyboard = NSStoryboard(name: MapViewController.storyboard, bundle: nil)
        return storyboard.instantiateInitialController() as! MapViewController
    }


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        TouchManager.instance.register(gestureManager, for: .mapExplorer)

        setupMap()
        setupGestures()
    }

    override func viewDidAppear() {
        mapHandler?.reset(animated: false)
    }


    // MARK: Setup

    private func setupMap() {
        mapHandler = MapHandler(mapView: mapView)
        ConnectionManager.instance.mapHandler = mapHandler
        let overlay = MKTileOverlay(urlTemplate: tileURL)
        overlay.canReplaceMapContent = true
        mapView.add(overlay)
        mapView.miniMapPosition = appID.isEven ? .nw : .ne
        createRecords()
    }

    private func setupGestures() {
        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: mapView)
        tapGesture.gestureUpdated = { [weak self] gesture in
            self?.didTapOnMap(gesture)
        }

        let pinchGesture = PinchGestureRecognizer()
        gestureManager.add(pinchGesture, to: mapView)
        pinchGesture.gestureUpdated = { [weak self] gesture in
            self?.didPinchOnMap(gesture)
        }
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
        let sortedAnnotations = mapView.annotations.sorted(by: { $0 is MKClusterAnnotation && !($1 is MKClusterAnnotation) })
        for annotation in sortedAnnotations {
            let positionInView = mapView.convert(annotation.coordinate, toPointTo: mapView).inverted(in: view)
            if touchRect.contains(positionInView) {
                if tap.state == .began {
                    if let annotationView = mapView.view(for: annotation) as? CircleAnnotationView {
                        annotationView.runAnimation()
                        return
                    } else if let annotationView = mapView.view(for: annotation) as? ClusterAnnotationView {
                        annotationView.runAnimation()
                        return
                    }
                } else if tap.state == .ended {
                    if let annotation = annotation as? CircleAnnotation, let record = recordForAnnotation[annotation] {
                        postRecordNotification(for: record, at: CGPoint(x: positionInView.x, y: positionInView.y - 20.0))
                        return
                    } else if let clusterAnnotation = annotation as? MKClusterAnnotation {
                        didSelect(clusterAnnotation: clusterAnnotation, at: position)
                        return
                    }
                }
            }
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
        } else if let cluster = annotation as? MKClusterAnnotation {
            return ClusterAnnotationView(annotation: cluster, reuseIdentifier: ClusterAnnotationView.identifier)
        }

        return MKAnnotationView()
    }


    // MARK: Helpers

    private func createRecords() {
        // Schools
        let schoolChain = firstly {
            try CachingNetwork.getSchools()
        }.catch { error in
            print(error)
        }

        // Events
        let eventChain = firstly {
            try CachingNetwork.getEvents()
        }.catch { error in
            print(error)
        }

        // Collections
        let collectionsChain = firstly {
            try CachingNetwork.getCollections(type: .map)
        }.catch { error in
            print(error)
        }

        when(fulfilled: schoolChain, eventChain, collectionsChain).then { [weak self] results in
            self?.parseNetworkResults(results)
        }
    }

    private func parseNetworkResults(_ results: (schools: [School], events: [Event], collections: [RecordCollection])) {
        var records = [Record]()
        records.append(contentsOf: results.schools)
        records.append(contentsOf: results.events)
        records.append(contentsOf: result.collections)
        addToMap(records)
    }

    private func postRecordNotification(for record: Record, at position: CGPoint) {
        guard let window = view.window else {
            return
        }

        let location = window.frame.origin + position
        let info: JSON = [Keys.app: appID, Keys.id: record.id, Keys.position: location.toJSON(), Keys.type: record.type.rawValue]
        DistributedNotificationCenter.default().postNotificationName(RecordNotification.display.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    private func handleDoubleTap(at position: CGPoint) {
        var mapRect = mapView.visibleMapRect
        let scaledWidth = Constants.doubleTapScale * mapRect.size.width
        let scaledHeight = Constants.doubleTapScale * mapRect.size.height
        if scaledWidth >= Constants.minZoomWidth {
            let translationX = (mapRect.size.width - scaledWidth) * Double(position.x / mapView.frame.width)
            let translationY = (mapRect.size.height - scaledHeight) * (1 - Double(position.y / mapView.frame.height))
            mapRect.size = MKMapSize(width: scaledWidth, height: scaledHeight)
            mapRect.origin += MKMapPoint(x: translationX, y: translationY)
            mapHandler?.animate(to: mapRect, with: .doubleTap)
        }
    }

    private func addToMap(_ records: [Record]) {
        var adjustedRecords = [Record]()

        for record in records {
            let adjustedRecord = adjustCoordinates(of: record, current: adjustedRecords)
            adjustedRecords.append(adjustedRecord)
        }

        addAnnotations(for: adjustedRecords)
    }

    private func adjustCoordinates(of record: Record, current records: [Record]) -> Record {
        guard let recordCoordinate = record.coordinate else {
            return record
        }

        var adjustedRecord = record

        for runnerRecord in records {
            guard let runnerCoordiante = runnerRecord.coordinate else {
                continue
            }

            let latitudeCheck = recordCoordinate.latitude + Double(Constants.spacingBetweenAnnotations) > runnerCoordiante.latitude && recordCoordinate.latitude - Double(Constants.spacingBetweenAnnotations) < runnerCoordiante.latitude
            let longitudeCheck = recordCoordinate.longitude + Double(Constants.spacingBetweenAnnotations) > runnerCoordiante.longitude && recordCoordinate.longitude - Double(Constants.spacingBetweenAnnotations) < runnerCoordiante.longitude

            if latitudeCheck && longitudeCheck {
                adjustedRecord.coordinate!.latitude += Double(Constants.spacingBetweenAnnotations)
                return adjustCoordinates(of: adjustedRecord, current: records)
            }
        }

        return adjustedRecord
    }

    private func addAnnotations(for records: [Record]) {
        records.forEach { record in
            if let coordinate = record.coordinate {
                let annotation = CircleAnnotation(coordinate: coordinate, type: record.type, title: record.title)
                recordForAnnotation[annotation] = record
                mapView.addAnnotation(annotation)
            }
        }
    }

    /// Zoom into the annotations contained in the cluster
    private func didSelect(clusterAnnotation: MKClusterAnnotation, at position: CGPoint) {
        let region = restrainSpan(for: clusterAnnotation.boundingCoordinateRegion())
        var newMapRect = MKMapRect(coordinateRegion: region).withPreservedAspectRatio(in: mapView)
        let translationX = (newMapRect.size.width / 2) - newMapRect.size.width * Double(position.x / mapView.frame.width)
        let translationY = -newMapRect.size.height * (1 - Double(position.y / mapView.frame.height))
        newMapRect.origin += MKMapPoint(x: translationX, y: translationY)
        mapHandler?.animate(to: newMapRect, with: MapAnimationType.clusterTap)
    }

    /// Clamps the region span between the max and min zoom levels
    private func restrainSpan(for region: MKCoordinateRegion) -> MKCoordinateRegion {
        var restrainedRegion = region
        let maxLongSpan = MKCoordinateForMapPoint(MKMapPoint(x: Constants.maxZoomWidth, y: 0)).longitude + Constants.coordinateToMapPointOriginOffset
        let minLongSpan = MKCoordinateForMapPoint(MKMapPoint(x: Constants.minZoomWidth, y: 0)).longitude + Constants.coordinateToMapPointOriginOffset
        restrainedRegion.span.longitudeDelta = clamp(restrainedRegion.span.longitudeDelta, min: minLongSpan, max: maxLongSpan)

        return restrainedRegion
    }
}
