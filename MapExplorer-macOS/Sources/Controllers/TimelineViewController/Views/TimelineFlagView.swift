//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Alamofire
import AlamofireImage


class TimelineFlagView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "TimelineFlagView")

    @IBOutlet weak var flagView: NSView!
    @IBOutlet weak var mediaImageView: ImageView!
    @IBOutlet weak var flagPoleView: NSView!
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var dateTextField: NSTextField!
    @IBOutlet weak var flagHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mediaImageHeightConstraint: NSLayoutConstraint!

    private var tintColor = style.timelineFlagBackgroundColor
    var event: TimelineEvent! {
        didSet {
            load(event)
        }
    }

    private struct Constants {
        static let interItemMargin: CGFloat = 4
        static let dateFieldHeight: CGFloat = 20
        static let animationDuration = 0.15
        static let mediaImageHeight: CGFloat = 98
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
            let animateColor = CABasicAnimation(keyPath: "backgroundColor")
            animateColor.fromValue = highlighted ? style.timelineFlagBackgroundColor.cgColor : tintColor.cgColor
            animateColor.toValue = highlighted ? tintColor.cgColor : style.timelineFlagBackgroundColor.cgColor
            animateColor.duration = Constants.animationDuration
            flagView.layer?.add(animateColor, forKey: "backgroundColor")
        } else {
            flagView.layer?.backgroundColor = highlighted ? tintColor.cgColor : style.timelineFlagBackgroundColor.cgColor
        }
    }


    // MARK: Helpers

    private func load(_ event: TimelineEvent) {
        tintColor = event.type.color
        flagPoleView.layer?.backgroundColor = event.type.color.cgColor
        mediaImageHeightConstraint.constant = event.thumbnail == nil ? 0 : Constants.mediaImageHeight
        flagHeightConstraint.constant = TimelineFlagView.flagHeight(for: event)
        titleTextField.attributedStringValue = NSAttributedString(string: event.title, attributes: style.timelineTitleAttributes)
        dateTextField.attributedStringValue = NSAttributedString(string: event.dates.description, attributes: style.timelineDateAttributes)

        if let thumbnail = event.thumbnail {
            Alamofire.request(thumbnail).responseImage { [weak self] response in
                if let image = response.value {
                    self?.mediaImageView.set(image)
                }
            }
        }
    }

    static func flagHeight(for event: TimelineEvent) -> CGFloat {
        let textFieldWidth = style.timelineFlagWidth - Constants.interItemMargin * 2
        let title = NSAttributedString(string: event.title, attributes: style.timelineTitleAttributes)
        let titleHeight = title.height(containerWidth: textFieldWidth)
        let dateHeight = Constants.dateFieldHeight
        let margins = Constants.interItemMargin * 3
        let imageHeight = event.thumbnail == nil ? 0 : Constants.mediaImageHeight

        return titleHeight + dateHeight + margins + imageHeight
    }
}
