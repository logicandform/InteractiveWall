//  Copyright © 2018 JABT. All rights reserved.


import Foundation
import MapKit

class CircleAnnotationView: MKAnnotationView {
    static let identifier = "CircleAnnotationView"

    private let circle1 = NSView(frame: CGRect(origin: CGPoint(x: -20, y: -20), size: CGSize(width: 40, height: 40)))
    private let circle2 = NSView(frame: CGRect(origin: CGPoint(x: -15, y: -15), size: CGSize(width: 30, height: 30)))
    private let circle3 = NSView(frame: CGRect(origin: CGPoint(x: -10, y: -10), size: CGSize(width: 20, height: 20)))
    private let center = NSView(frame: CGRect(origin: CGPoint(x: -8, y: -8), size: CGSize(width: 16, height: 16)))

    override var annotation: MKAnnotation? {
        willSet {
            guard (newValue as? CircleAnnotation) != nil else {
                return
            }

            setupAnnotations()
        }
    }

    private func setupAnnotations() {
        circle1.wantsLayer = true
        circle2.wantsLayer = true
        circle3.wantsLayer = true
        center.wantsLayer = true
        circle3.layer?.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        circle2.layer?.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 0.8)
        circle1.layer?.backgroundColor = #colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 0.45)
        center.layer?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        circle1.layer?.cornerRadius = 20
        circle2.layer?.cornerRadius = 15
        circle3.layer?.cornerRadius = 10
        center.layer?.cornerRadius = 8
        center.alphaValue = 0

        addSubview(circle1)
        addSubview(circle2)
        addSubview(circle3)
        addSubview(center)
    }

    func runAnimation() {
        animateCenter()
        animateInnerCircle()
        animateMiddleCircle()
        animateOuterCircle()
    }


    // MARK: Helpers

    private func animateCenter() {
        let animateScale = CABasicAnimation(keyPath: "transform.scale")
        animateScale.autoreverses = true
        animateScale.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateScale.fromValue = 0
        animateScale.toValue = 1
        animateScale.duration = 0.8
        center.layer?.add(animateScale, forKey: "transform.scale")

        let animateCenter = CABasicAnimation(keyPath: "position")
        animateCenter.autoreverses = true
        animateCenter.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateCenter.fromValue = [-0, -0]
        animateCenter.toValue = [-8, -8]
        animateCenter.duration = 0.8
        center.layer?.add(animateCenter, forKey: "position")

        let animateAlpha = CABasicAnimation(keyPath: "opacity")
        animateAlpha.autoreverses = true
        animateAlpha.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateAlpha.fromValue = 0
        animateAlpha.toValue = 1
        animateAlpha.duration = 0.8
        center.layer?.add(animateAlpha, forKey: "opacity")
    }

    private func animateInnerCircle() {
        let animateScale = CABasicAnimation(keyPath: "transform.scale")
        animateScale.autoreverses = true
        animateScale.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateScale.fromValue = 1
        animateScale.toValue = 1.25
        animateScale.duration = 0.1
        circle3.layer?.add(animateScale, forKey: "transform.scale")

        let animateCenter = CABasicAnimation(keyPath: "position")
        animateCenter.autoreverses = true
        animateCenter.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateCenter.fromValue = [-10, -10]
        animateCenter.toValue = [-12.5, -12.5]
        animateCenter.duration = 0.1
        circle3.layer?.add(animateCenter, forKey: "position")
    }

    private func animateMiddleCircle() {
        let animateScale = CABasicAnimation(keyPath: "transform.scale")
        animateScale.autoreverses = true
        animateScale.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateScale.fromValue = 1
        animateScale.toValue = 1.333
        animateScale.duration = 0.2
        circle2.layer?.add(animateScale, forKey: "transform.scale")

        let animateCenter = CABasicAnimation(keyPath: "position")
        animateCenter.autoreverses = true
        animateCenter.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateCenter.fromValue = [-15, -15]
        animateCenter.toValue = [-20, -20]
        animateCenter.duration = 0.2
        circle2.layer?.add(animateCenter, forKey: "position")
    }

    private func animateOuterCircle() {
        let animateScale = CABasicAnimation(keyPath: "transform.scale")
        animateScale.autoreverses = true
        animateScale.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateScale.fromValue = 1
        animateScale.toValue = 1.25
        animateScale.duration = 0.3
        circle1.layer?.add(animateScale, forKey: "transform.scale")

        let animateCenter = CABasicAnimation(keyPath: "position")
        animateCenter.autoreverses = true
        animateCenter.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateCenter.fromValue = [-20, -20]
        animateCenter.toValue = [-25, -25]
        animateCenter.duration = 0.3
        circle1.layer?.add(animateCenter, forKey: "position")
    }


}
