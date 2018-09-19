//  Copyright © 2018 JABT. All rights reserved.


import Foundation
import MapKit

class CircleAnnotationView: MKAnnotationView {
    static let identifier = "CircleAnnotationView"

    private let circle1 = NSView(frame: CGRect(origin: CGPoint(x: -Constants.radii.0, y: -Constants.radii.0), size: CGSize(width: Constants.radii.0 * 2.0, height: Constants.radii.0 * 2.0)))
    private let circle2 = NSView(frame: CGRect(origin: CGPoint(x: -Constants.radii.1, y: -Constants.radii.1), size: CGSize(width: Constants.radii.1 * 2.0, height: Constants.radii.1 * 2.0)))
    private let circle3 = NSView(frame: CGRect(origin: CGPoint(x: -Constants.radii.2, y: -Constants.radii.2), size: CGSize(width: Constants.radii.2 * 2.0, height: Constants.radii.2 * 2.0)))
    private let center = NSView(frame: CGRect(origin: CGPoint(x: -Constants.radii.3, y: -Constants.radii.3), size: CGSize(width: Constants.radii.3 * 2.0, height: Constants.radii.3 * 2.0)))
    private let title = CATextLayer()

    private struct Constants {
        static let radii: (CGFloat, CGFloat, CGFloat, CGFloat) = (18, 14, 10, 6)
        static let animationDuration = 1.0
    }

    override var annotation: MKAnnotation? {
        willSet {
            setupCircles(for: annotation)
        }
    }


    // MARK: API

    func runAnimation() {
        animateCenter()
        animateInnerCircle()
        animateMiddleCircle()
        animateOuterCircle()
    }

    func setTitle(scale: CGFloat) {
        let transform = CGAffineTransform.identity
        let scaled = transform.scaledBy(x: scale, y: scale)
        title.setAffineTransform(scaled)
    }


    // MARK: Setup

    private func setupCircles(for annotation: MKAnnotation?) {
        guard let annotation = annotation as? CircleAnnotation else {
            return
        }

        wantsLayer = true
        layer?.shadowOpacity = 0.85
        layer?.shadowRadius = 4
        layer?.shadowOffset = CGSize(width: 0, height: 4)
        layer?.masksToBounds = false
        clusteringIdentifier = CircleAnnotationView.identifier
        title.backgroundColor = CGColor.clear
        title.string = NSMutableAttributedString(string: annotation.title ?? "", attributes: style.mapLabelAttributes)
        title.anchorPoint = CGPoint(x: 0, y: 0.5)
        let titleSize = title.preferredFrameSize()
        title.frame = CGRect(origin: CGPoint(x: 20, y: -titleSize.height/2), size: titleSize)
        circle1.wantsLayer = true
        circle2.wantsLayer = true
        circle3.wantsLayer = true
        circle1.layer?.backgroundColor = annotation.type.color.withAlphaComponent(0.2).cgColor
        circle2.layer?.backgroundColor = annotation.type.color.withAlphaComponent(0.4).cgColor
        circle3.layer?.backgroundColor = annotation.type.color.cgColor
        circle1.layer?.cornerRadius = Constants.radii.0
        circle2.layer?.cornerRadius = Constants.radii.1
        circle3.layer?.cornerRadius = Constants.radii.2
        center.wantsLayer = true
        center.layer?.backgroundColor = CGColor.white
        center.layer?.cornerRadius = Constants.radii.3
        center.alphaValue = 0
        layer?.addSublayer(title)
        addSubview(center)
        addSubview(circle1)
        addSubview(circle2)
        addSubview(circle3)
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
        animateCenter.toValue = [-Constants.radii.3, -Constants.radii.3]
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
        let scale: CGFloat = 0.25
        let animateScale = CABasicAnimation(keyPath: "transform.scale")
        animateScale.autoreverses = true
        animateScale.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateScale.fromValue = 1
        animateScale.toValue = 1 + scale
        animateScale.duration = 0.1
        circle3.layer?.add(animateScale, forKey: "transform.scale")

        let animateCenter = CABasicAnimation(keyPath: "position")
        animateCenter.autoreverses = true
        animateCenter.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateCenter.fromValue = [-Constants.radii.2, -Constants.radii.2]
        animateCenter.toValue = [-Constants.radii.2-Constants.radii.2*scale, -Constants.radii.2-Constants.radii.2*scale]
        animateCenter.duration = 0.1
        circle3.layer?.add(animateCenter, forKey: "position")
    }

    private func animateMiddleCircle() {
        let scale: CGFloat = 0.3
        let animateScale = CABasicAnimation(keyPath: "transform.scale")
        animateScale.autoreverses = true
        animateScale.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateScale.fromValue = 1
        animateScale.toValue = 1.0 + scale
        animateScale.duration = 0.2
        circle2.layer?.add(animateScale, forKey: "transform.scale")

        let animateCenter = CABasicAnimation(keyPath: "position")
        animateCenter.autoreverses = true
        animateCenter.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animateCenter.fromValue = [-Constants.radii.1, -Constants.radii.1]
        animateCenter.toValue = [-Constants.radii.1-(Constants.radii.1*scale), (-Constants.radii.1-(Constants.radii.1*scale))]
        animateCenter.duration = 0.2
        circle2.layer?.add(animateCenter, forKey: "position")
    }

    private func animateOuterCircle() {
        let scale: CGFloat = 0.25
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
        animateCenter.fromValue = [-Constants.radii.0, -Constants.radii.0]
        animateCenter.toValue = [-Constants.radii.0-(Constants.radii.0*scale), -Constants.radii.0-(Constants.radii.0*scale)]
        animateCenter.duration = 0.3
        circle1.layer?.add(animateCenter, forKey: "position")
    }
}
