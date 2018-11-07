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
        static let textRadius: CGFloat = 8
        static let widths: [CGFloat] = [22, 16]
        static let opacities: [Float] = [0.3, 1]
        static let animationDuration = 0.2
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
        wantsLayer = true
        displayPriority = .required
        clusteringIdentifier = RecordAnnotationView.identifier
        layer?.shadowOpacity = Constants.shadowOpacity
        layer?.shadowOffset = Constants.shadowOffset
        text.alignmentMode = .center

        for (index, ring) in rings.enumerated() {
            ring.frame = CGRect(origin: .zero, size: CGSize(width: Constants.widths[index], height: Constants.widths[index]))
            ring.path = CGPath(ellipseIn: ring.frame, transform: nil)
            ring.position = .zero
            ring.opacity = Constants.opacities[index]
            ring.fillColor = .white
            layer?.addSublayer(ring)
        }
    }

    private func load(_ cluster: MKClusterAnnotation) {
        for ring in rings {
            layer?.addSublayer(ring)
        }

        let textString = NSAttributedString(string: cluster.memberAnnotations.count.description, attributes: style.clusterLabelAttributes)
        let textSize = textString.size()
        text.string = textString
        text.frame = CGRect(origin: CGPoint(x: -(textSize.width / 2), y: -(textSize.height / 2)), size: textSize)
        layer?.addSublayer(text)
    }
}
