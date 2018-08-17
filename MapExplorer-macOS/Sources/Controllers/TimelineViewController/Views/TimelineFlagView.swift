//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class TimelineFlagView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "TimelineFlagView")

    @IBOutlet weak var flagView: NSView!
    @IBOutlet weak var flagPoleView: NSView!
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var dateTextField: NSTextField!
    @IBOutlet weak var flagHeightConstraint: NSLayoutConstraint!

    var event: TimelineEvent! {
        didSet {
            load(event)
        }
    }
    private var tintColor = style.darkBackground

    private struct Constants {
        static let interItemMargin: CGFloat = 4
        static let dateFieldHeight: CGFloat = 20
        static let animationDuration = 0.15
    }


    // MARK: Init

    override func awakeFromNib() {
        super.awakeFromNib()
        view.wantsLayer = true
        flagView.wantsLayer = true
        flagPoleView.wantsLayer = true
        flagView.layer?.backgroundColor = style.darkBackground.cgColor
    }


    // MARK: API

    func animateFlagColor(on: Bool) {
        flagView.layer?.backgroundColor = on ? tintColor.cgColor : style.darkBackground.cgColor
        let animateColor = CABasicAnimation(keyPath: "backgroundColor")
        animateColor.fromValue = flagView.layer?.backgroundColor
        animateColor.toValue = on ? tintColor.cgColor : style.darkBackground.cgColor
        animateColor.duration = Constants.animationDuration
        flagView.layer?.add(animateColor, forKey: "backgroundColor")
    }


    // MARK: Helpers

    private func load(_ event: TimelineEvent) {
        tintColor = event.type.color
        flagPoleView.layer?.backgroundColor = event.type.color.cgColor
        flagHeightConstraint.constant = TimelineFlagView.flagHeight(for: event)
        titleTextField.attributedStringValue = NSAttributedString(string: event.title, attributes: style.timelineTitleAttributes)
        dateTextField.attributedStringValue = NSAttributedString(string: event.dates.description, attributes: style.timelineDateAttributes)
    }

    static func flagHeight(for event: TimelineEvent) -> CGFloat {
        let textFieldWidth = style.timelineFlagWidth - Constants.interItemMargin * 2
        let title = NSAttributedString(string: event.title, attributes: style.timelineTitleAttributes)
        let titleHeight = title.height(containerWidth: textFieldWidth)
        let dateHeight = Constants.dateFieldHeight
        let margins = Constants.interItemMargin * 3

        return titleHeight + dateHeight + margins
    }
}
