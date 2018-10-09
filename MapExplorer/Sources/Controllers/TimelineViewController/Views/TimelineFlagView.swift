//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class TimelineFlagView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "TimelineFlagView")

    @IBOutlet weak var flagView: NSView!
    @IBOutlet weak var mediaImageView: ImageView!
    @IBOutlet weak var flagPoleView: NSView!
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var dateTextField: NSTextField!
    @IBOutlet weak var flagHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mediaImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mediaImageTopConstraint: NSLayoutConstraint!

    private var tintColor = style.timelineFlagBackgroundColor
    var event: TimelineEvent! {
        didSet {
            load(event)
        }
    }

    private struct Constants {
        static let verticalMargin: CGFloat = 4
        static let horizontalMargin: CGFloat = 10
        static let dateFieldHeight: CGFloat = 20
        static let animationDuration = 0.15
        static let mediaImageHeight: CGFloat = 98
        static let mediaImageTopMargin: CGFloat = 2
        static let horizontalTextAlignmentInset: CGFloat = 2
        static let backgroundColorAnimationKey = "backgroundColor"
    }


    // MARK: Init

    override func awakeFromNib() {
        super.awakeFromNib()
        view.wantsLayer = true
        flagView.wantsLayer = true
        flagPoleView.wantsLayer = true
        flagView.layer?.backgroundColor = style.timelineFlagBackgroundColor.cgColor
    }


    // MARK: Overrides

    override func prepareForReuse() {
        super.prepareForReuse()
        mediaImageView.set(nil)
    }


    // MARK: API

    func set(highlighted: Bool, animated: Bool) {
        if animated {
            flagView.layer?.backgroundColor = highlighted ? tintColor.cgColor : style.timelineFlagBackgroundColor.cgColor
            let animateColor = CABasicAnimation(keyPath: Constants.backgroundColorAnimationKey)
            animateColor.fromValue = highlighted ? style.timelineFlagBackgroundColor.cgColor : tintColor.cgColor
            animateColor.toValue = highlighted ? tintColor.cgColor : style.timelineFlagBackgroundColor.cgColor
            animateColor.duration = Constants.animationDuration
            flagView.layer?.add(animateColor, forKey: Constants.backgroundColorAnimationKey)
        } else {
            flagView.layer?.backgroundColor = highlighted ? tintColor.cgColor : style.timelineFlagBackgroundColor.cgColor
        }
    }

    func flagContains(_ point: CGPoint) -> Bool {
        return flagView.frame.transformed(from: view.frame).contains(point)
    }


    // MARK: Helpers

    private func load(_ event: TimelineEvent) {
        flagView.layer?.removeAnimation(forKey: Constants.backgroundColorAnimationKey)
        tintColor = event.type.color
        flagPoleView.layer?.backgroundColor = event.type.color.cgColor
        mediaImageHeightConstraint.constant = event.thumbnail == nil ? 0 : Constants.mediaImageHeight
        mediaImageTopConstraint.constant = event.thumbnail == nil ? 0 : Constants.mediaImageTopMargin
        flagHeightConstraint.constant = TimelineFlagView.flagHeight(for: event)
        titleTextField.attributedStringValue = NSAttributedString(string: event.title, attributes: style.timelineTitleAttributes)
        dateTextField.attributedStringValue = NSAttributedString(string: event.dates.description(small: true), attributes: style.timelineDateAttributes)

        CachingNetwork.getImage(for: event) { [weak self] image in
            if let image = image {
                self?.mediaImageView.set(image)
            }
        }
    }

    static func flagHeight(for event: TimelineEvent) -> CGFloat {
        let flagWidth = style.timelineItemWidth - style.timelineFlagPoleWidth
        let textFieldWidth = flagWidth - Constants.horizontalMargin * 2
        let title = NSAttributedString(string: event.title, attributes: style.timelineTitleAttributes)
        let titleHeight = title.height(containerWidth: textFieldWidth)
        let dateHeight = Constants.dateFieldHeight
        let margins = Constants.verticalMargin * 3
        let imageHeight = event.thumbnail == nil ? 0 : Constants.mediaImageHeight + Constants.mediaImageTopMargin

        return titleHeight + dateHeight + margins + imageHeight
    }
}
