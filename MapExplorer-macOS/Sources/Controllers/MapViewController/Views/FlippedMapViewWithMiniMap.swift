//  Copyright © 2018 JABT. All rights reserved.


import Cocoa
import AppKit
import MapKit

class FlippedMapWithMiniMap: MKMapView, MKMapViewDelegate {
    fileprivate var removeLegal = true

    private var miniMap: FlippedMapView!
    private var miniMapNeedsConstraints = true

    struct Constants {
        static let miniMapWidthRatio: CGFloat = 1/4
        static let miniMapMargin: CGFloat = 10
        static let defaultMiniMapPosition: CompassDirection = .nw
    }


    // MARK: Init

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupMiniMap()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setupMiniMap()
    }


    // MARK: Setup

    // TODO: Figure out this resolution stuff
    private func setupMiniMap() {
        guard let lastScreen = NSScreen.screens.last else {
            return
        }

        let heightToWidthRatio = lastScreen.frame.size.height / lastScreen.frame.size.width
        let width = lastScreen.frame.width / CGFloat(Configuration.mapsPerScreen) * Constants.miniMapWidthRatio
        let rect = CGRect(x: 0, y: 0, width: width, height: width * heightToWidthRatio)

        miniMap = FlippedMapView(frame: rect)
        miniMap.mapType = self.mapType
        miniMap.isScrollEnabled = false
        miniMap.isZoomEnabled = false
        miniMap.setVisibleMapRect(MKMapRect(origin: CanadaRect.origin, size: CanadaRect.size), animated: false)
        miniMap.delegate = self
        self.addSubview(miniMap)
        miniMapPosition = Constants.defaultMiniMapPosition
    }


    // MARK: API

    var miniMapIsHidden: Bool = false {
        willSet {
            miniMap.isHidden = newValue
        }
    }

    var miniMapPosition: CompassDirection = Constants.defaultMiniMapPosition {
        didSet {
            updateMiniMapPosition()
        }
    }


    // MARK: Overrides

    override var isFlipped: Bool {
        return false
    }

    override func layout() {
        if removeLegal {
            var subviews = self.subviews
            subviews.removeLast()
            subviews.last?.removeFromSuperview()
            removeLegal = true
        }
        super.layout()
    }

    override func add(_ overlay: MKOverlay) {
        super.add(overlay)
        miniMap.add(overlay)
    }

    override func setVisibleMapRect(_ mapRect: MKMapRect, animated animate: Bool) {
        super.setVisibleMapRect(mapRect, animated: animate)
        updateMiniMap(with: mapRect)
    }

    override func addAnnotation(_ annotation: MKAnnotation) {
        super.addAnnotation(annotation)
        miniMap.addAnnotation(annotation)
    }

    override func addAnnotations(_ annotations: [MKAnnotation]) {
        super.addAnnotations(annotations)
        miniMap.addAnnotations(annotations)
    }

    // TODO: Programatically add autolayout constraints
    override func updateConstraints() {
        if miniMapNeedsConstraints {
            miniMapNeedsConstraints = false
            miniMap.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 0.5).isActive = true


        }
        super.updateConstraints()
    }


    // MARK: MKMapViewDelegate

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolygon {
            let renderer = MKPolygonRenderer(overlay: overlay)
            renderer.strokeColor = #colorLiteral(red: 0.9240344167, green: 0.3190495968, blue: 0.9256045818, alpha: 1)
            renderer.fillColor = #colorLiteral(red: 0.9240344167, green: 0.3190495968, blue: 0.9256045818, alpha: 0.5483197774)
            return renderer
        }

        return MKOverlayRenderer(overlay: overlay)
    }


    // MARK: Helpers

    private func updateMiniMapPosition() {
        var origin = self.frame.origin
//        switch miniMapPosition {
//        case .nw:
//            origin.x += Constants.margins
//            origin.y += self.frame.size.height - miniMap.frame.size.height - Constants.margins
//        case .ne:
//            origin.x += self.frame.size.width - miniMap.frame.size.width - Constants.margins
//            origin.y += self.frame.size.height - miniMap.frame.size.height - Constants.margins
//        case .se:
//            origin.x += self.frame.size.width - miniMap.frame.size.width - Constants.margins
//            origin.y += Constants.margins
//        case .sw:
//            origin.x += Constants.margins
//            origin.y += Constants.margins
//        }
        //miniMap.setFrameOrigin(origin)
    }

    func updateMiniMap(with mapRect: MKMapRect) {
        let mapPoints = mapRect.corners()
        let arrayOfPoints = [mapPoints.nw, mapPoints.ne, mapPoints.se, mapPoints.sw]
        let polygon = MKPolygon(points: arrayOfPoints, count: arrayOfPoints.count)
        miniMap.removeOverlays(miniMap.overlays)
        miniMap.add(polygon)
    }


    // MARK: Temp
    func updateMiniMap() {
        let mapPoints = self.visibleMapRect.corners()
        let arrayOfPoints = [mapPoints.nw, mapPoints.ne, mapPoints.se, mapPoints.sw]
        let polygon = MKPolygon(points: arrayOfPoints, count: arrayOfPoints.count)
        miniMap.removeOverlays(miniMap.overlays)
        miniMap.add(polygon)
    }
}

enum CompassDirection {
    case nw, ne, se, sw
}
