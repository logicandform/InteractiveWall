//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MapKit
import MONode
import PromiseKit
import AppKit


class MapViewController: NSViewController, MKMapViewDelegate, GestureResponder, NSGestureRecognizerDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Map")

    @IBOutlet weak var mapView: FlippedMapWithMiniMap!
    @IBOutlet weak var border: NSView!

    var gestureManager: GestureManager!
    private var mapHandler: MapHandler?
    private var recordForAnnotation = [CircleAnnotation: Record]()
    private var showingAnnotationTitles = false
    private let touchListener = TouchListener()

    private var tileURL: String {
        let tileID = max(screenID, 1)
        return "http://10.58.73.153:4\(tileID)00/v2/tiles/{z}/{x}/{y}.pbf"
    }

    private struct Constants {
        static let maxZoomWidth =  Double(134207500 / Configuration.mapsPerScreen)
        static let minZoomWidth = 424500.0
        static let touchRadius: CGFloat = 20
        static let annotationHitSize = CGSize(width: 50, height: 50)
        static let doubleTapScale = 0.5
        static let annotationTitleZoomLevel = Double(36000000 / Configuration.mapsPerScreen)
        static let spacingBetweenAnnotations = 0.02
    }

    private struct Keys {
        static let map = "map"
        static let id = "id"
        static let position = "position"
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
        setupMap()
        setupGestures()
        setupBorder()

        touchListener.listenToPort(named: "MapListener\(appID)")
        touchListener.receivedTouch = { [weak self] touch in
            self?.gestureManager.handle(touch)
        }
    }

    override func viewDidAppear() {
        mapHandler?.reset()
    }


    // MARK: Setup

    private func setupMap() {
        mapHandler = MapHandler(mapView: mapView, id: appID)
        let overlay = MKTileOverlay(urlTemplate: tileURL)
        overlay.canReplaceMapContent = true
        mapView.add(overlay)
        createAnnotations()
    }

    private func setupGestures() {
        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: mapView)
        tapGesture.gestureUpdated = didTapOnMap(_:)

        let pinchGesture = PinchGestureRecognizer()
        gestureManager.add(pinchGesture, to: mapView)
        pinchGesture.gestureUpdated = didPinchOnMap(_:)
    }

    private func setupBorder() {
        mapHandler?.border = border
        border.translatesAutoresizingMaskIntoConstraints = false

        if appID % Configuration.mapsPerScreen == 0 {
            border.trailingAnchor.constraint(equalTo: mapView.trailingAnchor).isActive = true
        } else {
            border.leadingAnchor.constraint(equalTo: mapView.leadingAnchor).isActive = true
        }

        border.wantsLayer = true
        border.layer?.backgroundColor = style.borderColor.cgColor
        border.isHidden = true
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
            let positionInView = mapView.convert(annotation.coordinate, toPointTo: mapView).inverted(in: view)
            if touchRect.contains(positionInView) {
                if tap.state == .began {
                    if let annotationView = mapView.view(for: annotation) as? CircleAnnotationView {
                        annotationView.runAnimation()
                        return
                    }
                } else if tap.state == .ended, let annotation = annotation as? CircleAnnotation, let record = recordForAnnotation[annotation] {
                    postWindowNotification(for: record, at: CGPoint(x: positionInView.x, y: positionInView.y - 20.0))
                    return
                }
            }
        }

        if tap.state == .doubleTapped {
            handleDoubleTap(at: position)
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

    // When the map region changes, if annotationTitleZoomLevel is crossed the annotations title visibilty updates
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if showingAnnotationTitles != (mapView.visibleMapRect.size.width < Constants.annotationTitleZoomLevel) {
            showingAnnotationTitles = mapView.visibleMapRect.size.width < Constants.annotationTitleZoomLevel
            toggleAnnotationTitles(on: showingAnnotationTitles)
        }
    }

    // When annotations come back into the visibleRect their title visibility updates
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            if let circleAnnotationView = view as? CircleAnnotationView {
                circleAnnotationView.showTitle(showingAnnotationTitles)
            }
        }
    }


    // MARK: Helpers

    private func createAnnotations() {
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

        when(fulfilled: schoolChain, eventChain).then { [weak self] results -> Void in
            self?.parseNetworkResults(results)
        }
    }

    private func parseNetworkResults(_ results: ([School], [Event])) {
        var recordsToLoad = [Record]()
        recordsToLoad.append(contentsOf: results.0)
        recordsToLoad.append(contentsOf: results.1)

        addToMap(recordsToLoad)
    }

    private func postWindowNotification(for record: Record, at position: CGPoint) {
        guard let window = view.window else {
            return
        }

        let location = window.frame.origin + position
        let info: JSON = [Keys.map: appID, Keys.id: record.id, Keys.position: location.toJSON()]
        DistributedNotificationCenter.default().postNotificationName(WindowNotification.with(record.type).name, object: nil, userInfo: info, deliverImmediately: true)
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
            mapHandler?.send(mapRect, animated: true)
            mapHandler?.endActivity()
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
        var adjustedRecord = record

        for runnerRecord in records {
            let recordLatitude = record.coordinate.latitude
            let recordLongitude = record.coordinate.longitude
            let runnerRecordLatitude = runnerRecord.coordinate.latitude
            let runnerRecordLongitude = runnerRecord.coordinate.longitude
            let latitudeCheck = recordLatitude + Double(Constants.spacingBetweenAnnotations) > runnerRecordLatitude && recordLatitude - Double(Constants.spacingBetweenAnnotations) < runnerRecordLatitude
            let longitudeCheck = recordLongitude + Double(Constants.spacingBetweenAnnotations) > runnerRecordLongitude && recordLongitude - Double(Constants.spacingBetweenAnnotations) < runnerRecordLongitude

            if latitudeCheck && longitudeCheck {
                adjustedRecord.coordinate.latitude += Double(Constants.spacingBetweenAnnotations)
                return adjustCoordinates(of: adjustedRecord, current: records)
            }
        }

        return adjustedRecord
    }

    private func addAnnotations(for records: [Record]) {
        records.forEach { record in
            let annotation = CircleAnnotation(coordinate: record.coordinate, record: record.type, title: record.title)
            recordForAnnotation[annotation] = record
            mapView.addAnnotation(annotation)
        }
    }

    private func toggleAnnotationTitles(on: Bool) {
        for annotation in mapView.annotations {
            if let annotationView = mapView.view(for: annotation) as? CircleAnnotationView {
                annotationView.showTitle(on)
            }
        }
    }
}
