//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import MapKit


class ClusterAnnotationView: MKAnnotationView {
    static let identifier = "ClusterView"

    private let circle = CALayer()
    private let text = CATextLayer()

    private struct Constants {
        static let radius: CGFloat = 12
        static let textRadius: CGFloat = 8
        static let borderWidth: CGFloat = 2
        static let textVerticalOffset: CGFloat = 1
    }

    override var annotation: MKAnnotation? {
        willSet {
            if let cluster = annotation as? MKClusterAnnotation {
                load(cluster)
            }
        }
    }


    // MARK: Init

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }


    // MARK: API

    func runAnimation() {
        let scale: CGFloat = 0.25
        let animateScale = CABasicAnimation(keyPath: "transform.scale")
        animateScale.autoreverses = true
        animateScale.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animateScale.fromValue = 1
        animateScale.toValue = 1 + scale
        animateScale.duration = 0.1
        circle.add(animateScale, forKey: "transform.scale")
    }


    // MARK: Setup

    private func setupViews() {
        text.frame = CGRect(origin: CGPoint(x: -Constants.textRadius, y: -(Constants.textRadius + Constants.textVerticalOffset)), size: CGSize(width: Constants.textRadius * 2.0, height: Constants.textRadius * 2.0))
        text.alignmentMode = .center
        circle.frame = CGRect(origin: CGPoint(x: -Constants.radius, y: -Constants.radius), size: CGSize(width: Constants.radius * 2.0, height: Constants.radius * 2.0))
        circle.backgroundColor = style.clusterColor.withAlphaComponent(0.25).cgColor
        circle.cornerRadius = Constants.radius
        circle.borderColor = style.clusterColor.cgColor
        circle.borderWidth = Constants.borderWidth
        displayPriority = .defaultHigh
        collisionMode = .circle
    }

    private func load(_ cluster: MKClusterAnnotation) {
        text.string = NSAttributedString(string: cluster.memberAnnotations.count.description, attributes: style.clusterLabelAttributes)
        layer?.addSublayer(circle)
        layer?.addSublayer(text)
    }
}
