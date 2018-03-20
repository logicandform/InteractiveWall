//  Copyright © 2018 JABT. All rights reserved.


import Foundation
import MapKit

class CustomAnnotationView: MKAnnotationView {
    static let identifier = "CustomAnnotationView"

    private struct Constants {
        static let calloutOffset = CGPoint(x: 0, y: -10)
        static let circleRadius: CGFloat = 10
    }

    let circle1 = NSView(frame: CGRect(origin: CGPoint(x: -20, y: -20), size: CGSize(width: 40, height: 40)))
    let circle2 = NSView(frame: CGRect(origin: CGPoint(x: -15, y: -15), size: CGSize(width: 30, height: 30)))
    let circle3 = NSView(frame: CGRect(origin: CGPoint(x: -10, y: -10), size: CGSize(width: 20, height: 20)))
    let center = NSView(frame: CGRect())



    override var annotation: MKAnnotation? {
        willSet {
            guard (newValue as? CustomAnnotation) != nil else {
                return
            }

            center.wantsLayer = true
            center.layer?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            center.alphaValue = 0.0
            center.layer?.cornerRadius = 8
            addSubview(center)
            NSAnimationContext.runAnimationGroup({_ in
                NSAnimationContext.current.duration = 0.1
                center.animator().frame.origin = CGPoint(x: -8, y: -8)
                center.animator().frame.size = CGSize(width: 16, height: 16)
                center.animator().alphaValue = 1.0
            })

//            clusteringIdentifier = CustomAnnotationView.identifier
//            circle1.wantsLayer = true
//            circle2.wantsLayer = true
//            circle3.wantsLayer = true
//            circle3.layer?.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
//            circle2.layer?.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 0.8)
//            circle1.layer?.backgroundColor = #colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 0.45)
//            circle1.layer?.cornerRadius = 20
//            circle2.layer?.cornerRadius = 15
//            circle3.layer?.cornerRadius = 10
//
//            addSubview(circle1)
//            addSubview(circle2)
//            addSubview(circle3)
        }
    }



    func unclicked() {
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.1
            center.animator().alphaValue = 0.0
            center.animator().frame.origin = CGPoint()
            center.animator().frame.size = CGSize()
        }, completionHandler: {
            self.center.removeFromSuperview()
        })
    }

}
