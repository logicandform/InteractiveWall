//  Copyright © 2018 JABT. All rights reserved.


import Foundation
import MapKit

class CircleAnnotationView: MKAnnotationView {
    static let identifier = "CircleAnnotationView"

    private let circle1 = NSView(frame: CGRect(origin: CGPoint(x: -18, y: -18), size: CGSize(width: 36, height: 36)))
    private let circle2 = NSView(frame: CGRect(origin: CGPoint(x: -13, y: -13), size: CGSize(width: 26, height: 26)))
    private let circle3 = NSView(frame: CGRect(origin: CGPoint(x: -8, y: -8), size: CGSize(width: 16, height: 16)))
    private let center = NSView(frame: CGRect(origin: CGPoint(x: -7, y: -7), size: CGSize(width: 14, height: 14)))

    override var annotation: MKAnnotation? {
        willSet {
            guard let annotation = newValue as? CircleAnnotation else {
                return
            }

            setupAnnotations(annotation: annotation)
        }
    }


    // MARK: API

    func runAnimation() {
        animateCenter()
        animateInnerCircle()
        animateMiddleCircle()
        animateOuterCircle()
    }


    // MARK: Setup

    private func setupAnnotations(annotation: CircleAnnotation) {
        circle1.wantsLayer = true
        circle2.wantsLayer = true
        circle3.wantsLayer = true
        center.wantsLayer = true
        circle3.layer?.backgroundColor = annotation.record.colors[0].cgColor
        circle2.layer?.backgroundColor = annotation.record.colors[1].cgColor
        circle1.layer?.backgroundColor = style.outerAnnotationColor.cgColor
        center.layer?.backgroundColor = CGColor.white
        circle1.layer?.cornerRadius = 18
        circle2.layer?.cornerRadius = 13
        circle3.layer?.cornerRadius = 8
        center.layer?.cornerRadius = 7
        center.alphaValue = 0
        addSubview(circle1)
        addSubview(circle2)
        addSubview(circle3)
        addSubview(center)
    }


    // MARK: Helpers

    private func animateCenter() {
        let animateScale = CABasicAnimation(keyPath: "transform.scale")
        animateScale.autoreverses = true
        animateScale.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateScale.fromValue = 0
        animateScale.toValue = 1
        animateScale.duration = 0.3
        center.layer?.add(animateScale, forKey: "transform.scale")

        let animateCenter = CABasicAnimation(keyPath: "position")
        animateCenter.autoreverses = true
        animateCenter.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateCenter.fromValue = [-0, -0]
        animateCenter.toValue = [-7, -7]
        animateCenter.duration = 0.3
        center.layer?.add(animateCenter, forKey: "position")

        let animateAlpha = CABasicAnimation(keyPath: "opacity")
        animateAlpha.autoreverses = true
        animateAlpha.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateAlpha.fromValue = 0
        animateAlpha.toValue = 0.8
        animateAlpha.duration = 0.3
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
        animateCenter.fromValue = [-8, -8]
        animateCenter.toValue = [-10, -10]
        animateCenter.duration = 0.1
        circle3.layer?.add(animateCenter, forKey: "position")
    }

    private func animateMiddleCircle() {
        let animateScale = CABasicAnimation(keyPath: "transform.scale")
        animateScale.autoreverses = true
        animateScale.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateScale.fromValue = 1
        animateScale.toValue = 1.3
        animateScale.duration = 0.2
        circle2.layer?.add(animateScale, forKey: "transform.scale")

        let animateCenter = CABasicAnimation(keyPath: "position")
        animateCenter.autoreverses = true
        animateCenter.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateCenter.fromValue = [-13, -13]
        animateCenter.toValue = [-16.9, -16.9]
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
        animateCenter.fromValue = [-18, -18]
        animateCenter.toValue = [-22.5, -22.5]
        animateCenter.duration = 0.3
        circle1.layer?.add(animateCenter, forKey: "position")
    }
}
