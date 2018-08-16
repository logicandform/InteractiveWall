//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import MapKit


class ClusterAnnotationView: MKAnnotationView {
    static let identifier = "ClusterView"

    private let circle = NSView(frame: CGRect(origin: CGPoint(x: -Constants.radius, y: -Constants.radius), size: CGSize(width: Constants.radius * 2.0, height: Constants.radius * 2.0)))

    private struct Constants {
        static let radius: CGFloat = 12
        static let borderWidth: CGFloat = 2
    }

    override var annotation: MKAnnotation? {
        willSet {
            if newValue is MKClusterAnnotation {
                setupAnnotation()
            }
        }
    }


    // MARK: API

    func runAnimation() {
        let scale: CGFloat = 0.25
        let animateScale = CABasicAnimation(keyPath: "transform.scale")
        animateScale.autoreverses = true
        animateScale.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateScale.fromValue = 1
        animateScale.toValue = 1 + scale
        animateScale.duration = 0.1
        circle.layer?.add(animateScale, forKey: "transform.scale")

        let animateCenter = CABasicAnimation(keyPath: "position")
        animateCenter.autoreverses = true
        animateCenter.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateCenter.fromValue = [-Constants.radius, -Constants.radius]
        animateCenter.toValue = [-Constants.radius-Constants.radius*scale, -Constants.radius-Constants.radius*scale]
        animateCenter.duration = 0.1
        circle.layer?.add(animateCenter, forKey: "position")
    }


    // MARK: Setup

    func setupAnnotation() {
        displayPriority = .defaultHigh
        collisionMode = .circle
        circle.wantsLayer = true
        circle.layer?.backgroundColor = style.clusterColor.withAlphaComponent(0.25).cgColor
        circle.layer?.cornerRadius = Constants.radius
        circle.layer?.borderColor = style.clusterColor.cgColor
        circle.layer?.borderWidth = Constants.borderWidth
        addSubview(circle)
    }
}
