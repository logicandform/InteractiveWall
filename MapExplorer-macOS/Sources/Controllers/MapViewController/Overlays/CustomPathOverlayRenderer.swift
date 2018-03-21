//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit



class CustomPathOverlayRenderer: MKOverlayRenderer {

    override init(overlay: MKOverlay) {
        super.init(overlay: overlay)
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        var zoom: CGFloat = 0.0001220703125
        if zoomScale > 0.0001220703125 {
            zoom = zoomScale
        }

        let rect1 = CGRect(x: -30 / zoom, y: -30 / zoom, width: 60 / zoom, height: 60 / zoom)
        let path1 = CGPath(ellipseIn: rect1, transform: nil)
        context.addPath(path1)
        context.setFillColor(#colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 0.35))
        context.fillPath()

        let rect2 = CGRect(x: -20 / zoom, y: -20 / zoom, width: 40 / zoom, height: 40 / zoom)
        let path2 = CGPath(ellipseIn: rect2, transform: nil)
        context.addPath(path2)
        context.setFillColor(#colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 0.6))
        context.fillPath()

        let rect3 = CGRect(x: -12 / zoom, y: -12 / zoom, width: 24 / zoom, height: 24 / zoom)
        let path3 = CGPath(ellipseIn: rect3, transform: nil)
        context.addPath(path3)
        context.setFillColor(#colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1))
        context.fillPath()

        let rect4 = CGRect(x: -10 / zoom, y: -10 / zoom, width: 20 / zoom, height: 20 / zoom)
        let path4 = CGPath(ellipseIn: rect4, transform: nil)
        context.addPath(path4)
        context.setFillColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0))
        context.fillPath()
    }

    override func canDraw(_ mapRect: MKMapRect, zoomScale: MKZoomScale) -> Bool {
        return true
    }
}
