//  Copyright © 2018 JABT. All rights reserved.


import Foundation
import MapKit
import CoreGraphics


protocol AnimatableAnnotation {
    func grow()
    func shrink()
}


class RecordAnnotationView: MKAnnotationView, AnimatableAnnotation {
    static let identifier = "RecordAnnotationView"

    private let rings = [CAShapeLayer(), CAShapeLayer(), CAShapeLayer()]
    private let title = CATextLayer()
    private var growing = false
    private var queuedAnimation: (() -> Void)?

    override var annotation: MKAnnotation? {
        willSet {
            if let annotation = annotation as? RecordAnnotation {
                load(annotation)
            }
        }
    }

    private struct Constants {
        static let widths: [CGFloat] = [22, 16, 4]
        static let opacities: [Float] = [0.3, 1, 1]
        static let animationDuration = 0.2
        static let titleLeftOffset: CGFloat = 14
        static let shadowOpacity: Float = 1
        static let shadowOffset = CGSize(width: 0, height: 4)
    }


    // MARK: Init

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }


    // MARK: API

    func setTitle(scale: CGFloat) {
        let transform = CGAffineTransform.identity
        let scaled = transform.scaledBy(x: scale, y: scale)
        CATransaction.suppressAnimations { [weak self] in
            self?.title.setAffineTransform(scaled)
        }
    }


    // MARK: AnimatableAnnotation

    func grow() {
        growing = true
        performGrow()
    }

    func shrink() {
        if growing {
            queuedAnimation = performShrink
        } else {
            performShrink()
        }
    }


    // MARK: Animations

    private func performGrow() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(Constants.animationDuration)
        CATransaction.setCompletionBlock { [weak self] in
            self?.finishedGrowing()
        }
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut))
        for (index, ring) in rings.enumerated() {
            let scale = 1 + CGFloat(index + 1) * 0.2
            ring.transform = CATransform3DMakeScale(scale, scale, 1)
        }
        CATransaction.commit()
    }

    private func finishedGrowing() {
        growing = false
        queuedAnimation?()
        queuedAnimation = nil
    }

    private func performShrink() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(Constants.animationDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn))
        for ring in rings {
            ring.transform = CATransform3DIdentity
        }
        CATransaction.commit()
    }


    // MARK: Setup

    private func setupView() {
        displayPriority = .required
        clusteringIdentifier = RecordAnnotationView.identifier
        wantsLayer = true
        layer?.shadowOpacity = Constants.shadowOpacity
        layer?.shadowOffset = Constants.shadowOffset
        title.backgroundColor = .clear
        title.anchorPoint = CGPoint(x: 0, y: 0.5)

        for (index, ring) in rings.enumerated() {
            ring.frame = CGRect(origin: .zero, size: CGSize(width: Constants.widths[index], height: Constants.widths[index]))
            ring.path = CGPath(ellipseIn: ring.frame, transform: nil)
            ring.position = .zero
            ring.opacity = Constants.opacities[index]
        }
    }

    private func load(_ annotation: RecordAnnotation) {
        title.string = NSMutableAttributedString(string: annotation.record.shortestTitle(), attributes: style.mapLabelAttributes)
        let titleSize = title.preferredFrameSize()
        title.frame = CGRect(origin: CGPoint(x: Constants.titleLeftOffset, y: -titleSize.height/2), size: titleSize)
        layer?.addSublayer(title)
        for (index, ring) in rings.enumerated() {
            ring.fillColor = index == rings.count - 1 ? .white : annotation.record.type.color.cgColor
            layer?.addSublayer(ring)
        }
    }
}
