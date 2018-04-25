//  Copyright © 2018 JABT. All rights reserved.


import Foundation
import MapKit

class CircleAnnotationView: MKAnnotationView {

    private struct Constants {
        static let radii: (CGFloat, CGFloat, CGFloat, CGFloat) = (18, 14, 10, 6)
        static let titleFontSize: CGFloat = 11.0
        static let titleLineSpacing: CGFloat = 0.0
        static let titleMaximumLineHeight: CGFloat = titleFontSize + 5.0
        static let titleParagraphSpacing: CGFloat = 8.0
        static let titleForegroundColor: NSColor = NSColor.white
        static let fontName: String = "Soleil"
        static let kern: CGFloat = 0.5
    }

    static let identifier = "CircleAnnotationView"

    private let circle1 = NSView(frame: CGRect(origin: CGPoint(x: -Constants.radii.0, y: -Constants.radii.0), size: CGSize(width: Constants.radii.0*2.0, height: Constants.radii.0*2.0)))
    private let circle2 = NSView(frame: CGRect(origin: CGPoint(x: -Constants.radii.1, y: -Constants.radii.1), size: CGSize(width: Constants.radii.1*2.0, height: Constants.radii.1*2.0)))
    private let circle3 = NSView(frame: CGRect(origin: CGPoint(x: -Constants.radii.2, y: -Constants.radii.2), size: CGSize(width: Constants.radii.2*2.0, height: Constants.radii.2*2.0)))
    private let center = NSView(frame: CGRect(origin: CGPoint(x: -Constants.radii.3, y: -Constants.radii.3), size: CGSize(width: Constants.radii.3*2.0, height: Constants.radii.3*2.0)))
//    private let title = NSTextView(frame: CGRect(x: 13, y: -7, width: 500, height: 15))
    private let title = NSTextField(frame: NSRect(x: 18, y: -8, width: 500, height: 15))

    var titleAttributes: [NSAttributedStringKey: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Constants.titleLineSpacing
        paragraphStyle.paragraphSpacing = Constants.titleParagraphSpacing
        paragraphStyle.maximumLineHeight = Constants.titleMaximumLineHeight
        paragraphStyle.lineBreakMode = .byWordWrapping
        let font = NSFont(name: Constants.fontName, size: Constants.titleFontSize) ?? NSFont.systemFont(ofSize: Constants.titleFontSize)
        return [.paragraphStyle : paragraphStyle,
                .font : font,
                .foregroundColor : Constants.titleForegroundColor,
                .kern : Constants.kern
        ]
    }

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

    func showTitle() {
        if title.alphaValue == 0.0 {
            let animateAlpha = CABasicAnimation(keyPath: "opacity")
            animateAlpha.isRemovedOnCompletion = true
            animateAlpha.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            animateAlpha.fromValue = 0
            animateAlpha.toValue = 1
            animateAlpha.duration = 1.0
            title.layer?.add(animateAlpha, forKey: "opacity")
            title.alphaValue = 1.0
        }
    }

    func hideTitle() {
        if title.alphaValue == 1.0 {
            let animateAlpha = CABasicAnimation(keyPath: "opacity")
            animateAlpha.isRemovedOnCompletion = true
            animateAlpha.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            animateAlpha.fromValue = 1
            animateAlpha.toValue = 0
            animateAlpha.duration = 1.0
            title.layer?.add(animateAlpha, forKey: "opacity")
            title.alphaValue = 0.0
        }
    }

    // MARK: Setup

    private func setupAnnotations(annotation: CircleAnnotation) {
        circle1.wantsLayer = true
        circle2.wantsLayer = true
        circle3.wantsLayer = true
        center.wantsLayer = true
        title.isEditable = false
        title.isSelectable = false
        title.backgroundColor = NSColor.clear
        title.isBezeled = false
        title.textColor = NSColor.white
        title.font = NSFont(name: "Soleil", size: 11)
        title.alphaValue = 0.0
        title.attributedStringValue = NSMutableAttributedString(string: annotation.title!, attributes: titleAttributes)
        circle3.layer?.backgroundColor = annotation.record.color.cgColor
        circle2.layer?.backgroundColor = annotation.record.color.withAlphaComponent(0.4).cgColor
        circle1.layer?.backgroundColor = annotation.record.color.withAlphaComponent(0.2).cgColor
        center.layer?.backgroundColor = CGColor.white
        circle1.layer?.cornerRadius = Constants.radii.0
        circle2.layer?.cornerRadius = Constants.radii.1
        circle3.layer?.cornerRadius = Constants.radii.2
        center.layer?.cornerRadius = Constants.radii.3
        center.alphaValue = 0
        addSubview(circle1)
        addSubview(circle2)
        addSubview(circle3)
        addSubview(center)
        addSubview(title)

        self.wantsLayer = true
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.85
        layer?.shadowRadius = 4.0
        layer?.shadowOffset = CGSize(width: 0, height: 4)
        layer?.masksToBounds = false
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
