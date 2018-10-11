//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import MapKit


class ClusterAnnotationView: MKAnnotationView, AnimatableAnnotation {
    static let identifier = "ClusterView"

    private let rings = [CAShapeLayer(), CAShapeLayer()]
    private let text = CATextLayer()
    private var growing = false
    private var queuedAnimation: (() -> Void)?

    override var annotation: MKAnnotation? {
        willSet {
            if let cluster = annotation as? MKClusterAnnotation {
                load(cluster)
            }
        }
    }

    private struct Constants {
        static let textVerticalOffset: CGFloat = 1
        static let textRadius: CGFloat = 8
        static let steps: [CGFloat] = [11, 8]
        static let opacities: [Float] = [0.3, 1]
        static let animationDuration = 0.2
        static let shadowOpacity: Float = 1
        static let shadowOffset = CGSize(width: 0, height: 4)
    }


    // MARK: Init

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupRings()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupRings()
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
        CATransaction.setCompletionBlock { [weak self] in
            self?.finishedGrowing()
        }
        CATransaction.setAnimationDuration(Constants.animationDuration)
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

    private func setupRings() {
        wantsLayer = true
        layer?.shadowOpacity = Constants.shadowOpacity
        layer?.shadowOffset = Constants.shadowOffset
        displayPriority = .defaultHigh
        clusteringIdentifier = RecordAnnotationView.identifier

        text.frame = CGRect(origin: CGPoint(x: -Constants.textRadius, y: -(Constants.textRadius + Constants.textVerticalOffset)), size: CGSize(width: Constants.textRadius * 2.0, height: Constants.textRadius * 2.0))
        text.alignmentMode = .center

        for (index, ring) in rings.enumerated() {
            ring.frame = CGRect(origin: .zero, size: CGSize(width: Constants.steps[index] * 2.0, height: Constants.steps[index] * 2.0))
            ring.path = CGPath(ellipseIn: ring.frame, transform: nil)
            ring.position = CGPoint(x: 0, y: bounds.midY)
            ring.opacity = Constants.opacities[index]
            ring.transform = CATransform3DIdentity
            ring.fillColor = CGColor.white
            layer?.addSublayer(ring)
        }
    }

    private func load(_ cluster: MKClusterAnnotation) {
        for ring in rings {
            layer?.addSublayer(ring)
        }
        text.string = NSAttributedString(string: cluster.memberAnnotations.count.description, attributes: style.clusterLabelAttributes)
        layer?.addSublayer(text)
    }
}
