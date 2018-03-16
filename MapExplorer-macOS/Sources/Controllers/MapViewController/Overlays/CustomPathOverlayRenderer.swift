//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


class CustomPathOverlayRenderer: MKOverlayRenderer {

    override init(overlay: MKOverlay) {
        super.init(overlay: overlay)
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let rect1 = CGRect(x: -150000, y: -150000, width: 300000, height: 300000)
        let path1 = CGPath(ellipseIn: rect1, transform: nil)
        context.addPath(path1)
        context.setFillColor(#colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 0.35))
        context.fillPath()

        let rect2 = CGRect(x: -100000, y: -100000, width: 200000, height: 200000)
        let path2 = CGPath(ellipseIn: rect2, transform: nil)
        context.addPath(path2)
        context.setFillColor(#colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 0.6))
        context.fillPath()

        let rect3 = CGRect(x: -60000, y: -60000, width: 120000, height: 120000)
        let path3 = CGPath(ellipseIn: rect3, transform: nil)
        context.addPath(path3)
        context.setFillColor(#colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1))
        context.fillPath()
    }
}
