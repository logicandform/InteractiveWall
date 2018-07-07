//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit
import MapKit


enum CompassDirection: Int {
    case nw
    case ne
    case se
    case sw
}


class MapViewWithMiniMap: MKMapView, MKMapViewDelegate {
    fileprivate var removeLegal = true

    private var miniMap: FlippedMapView!
    private var miniMapLocationRect: NSView!
    private var miniMapLeadingConstraint: NSLayoutConstraint!
    private var miniMapTrailingConstraint: NSLayoutConstraint!
    private var miniMapTopConstraint: NSLayoutConstraint!
    private var miniMapBottomConstraint: NSLayoutConstraint!

    struct Constants {
        static let miniMapWidthRatio: CGFloat = 1/4
        static let miniMapAspectRatio: CGFloat = 3/2
        static let miniMapMargin: CGFloat = 10
        static let defaultMiniMapPosition = CompassDirection.ne
        static let miniMapLocationRectBorderColor = NSColor.white
        static let miniMapLocationRectBackgroundColor = style.selectedColor
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

    private func setupMiniMap() {
        miniMap = FlippedMapView(frame: .zero)
        miniMap.mapType = mapType
        miniMap.isScrollEnabled = false
        miniMap.isZoomEnabled = false
        miniMap.isRotateEnabled = false
        miniMap.setVisibleMapRect(MKMapRect(origin: MapConstants.canadaRect.origin, size: MapConstants.canadaRect.size), animated: false)
        miniMap.delegate = self
        miniMap.translatesAutoresizingMaskIntoConstraints = false
        miniMap.isHidden = true
        addSubview(miniMap)
        setupConstraints()
        miniMapPosition = Constants.defaultMiniMapPosition

        miniMapLocationRect = NSView()
        miniMapLocationRect.wantsLayer = true
        miniMapLocationRect.layer?.backgroundColor = Constants.miniMapLocationRectBackgroundColor.cgColor.copy(alpha: 0.5)
        miniMapLocationRect.layer?.borderWidth = 1
        miniMapLocationRect.layer?.borderColor = Constants.miniMapLocationRectBorderColor.cgColor
        miniMap.addSubview(miniMapLocationRect)
    }

    private func setupConstraints() {
        miniMap.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: Constants.miniMapWidthRatio).isActive = true
        miniMap.heightAnchor.constraint(equalTo: miniMap.widthAnchor, multiplier: 1 / Constants.miniMapAspectRatio).isActive = true
        miniMapTopConstraint = miniMap.topAnchor.constraint(equalTo: self.topAnchor, constant: Constants.miniMapMargin)
        miniMapBottomConstraint = miniMap.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -Constants.miniMapMargin)
        miniMapLeadingConstraint = miniMap.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: Constants.miniMapMargin)
        miniMapTrailingConstraint = miniMap.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -Constants.miniMapMargin)
    }


    // MARK: API

    var miniMapIsHidden: Bool = false {
        willSet {
            miniMap.isHidden = newValue
        }
    }

    var miniMapPosition = Constants.defaultMiniMapPosition {
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


    // MARK: MKMapViewDelegate

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let tileOverlay = overlay as? MKTileOverlay {
            return MKTileOverlayRenderer(tileOverlay: tileOverlay)
        }

        return MKOverlayRenderer(overlay: overlay)
    }


    // MARK: Helpers

    /// Changes the position of the miniMap within the main map with autolayout constraints
    private func updateMiniMapPosition() {
        miniMapTopConstraint.isActive = false
        miniMapBottomConstraint.isActive = false
        miniMapTrailingConstraint.isActive = false
        miniMapLeadingConstraint.isActive = false

        switch miniMapPosition {
        case .ne:
            miniMapTopConstraint.isActive = true
            miniMapTrailingConstraint.isActive = true
        case .nw:
            miniMapTopConstraint.isActive = true
            miniMapLeadingConstraint.isActive = true
        case .sw:
            miniMapBottomConstraint.isActive = true
            miniMapLeadingConstraint.isActive = true
        case .se:
            miniMapBottomConstraint.isActive = true
            miniMapTrailingConstraint.isActive = true
        }
    }

    /// Update the location rect on the miniMap to track the current location of the main map
    private func updateMiniMap(with mapRect: MKMapRect) {
        let mapPoints = mapRect.corners()
        let nw = miniMap.convert(MKCoordinateForMapPoint(mapPoints.nw), toPointTo: miniMap)
        let se = miniMap.convert(MKCoordinateForMapPoint(mapPoints.se), toPointTo: miniMap)
        let width = se.x - nw.x
        let height = nw.y - se.y
        let frame = NSRect(x: nw.x, y: nw.y, width: width, height: height)
        miniMapLocationRect.frame = frame
    }
}
