//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Alamofire
import AlamofireImage

class MediaItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("MediaItemView")

    @IBOutlet weak var mediaImageView: ImageView!
    @IBOutlet weak var videoIconImageView: NSImageView!
    @IBOutlet weak var titleLabelBackgroundView: NSView!
    @IBOutlet weak var titleLabelBackgroundWidth: NSLayoutConstraint!

    private struct Constants {
        static let fontName = "Soleil"
        static let fontSize: CGFloat = 13
        static let fontColor: NSColor = .white
        static let kern: CGFloat = 0.5
    }

    var tintColor = style.selectedColor
    var media: Media? {
        didSet {
            load(media)
        }
    }
    var displaysTitle: Bool!
    private var titleAttributes : [NSAttributedStringKey : Any] {
        let font = NSFont(name: Constants.fontName, size: Constants.fontSize) ?? NSFont.systemFont(ofSize: Constants.fontSize)

        return [.font : font,
                .foregroundColor : Constants.fontColor,
                .kern : Constants.kern]
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.borderWidth = 1
        set(highlighted: false)
    }


    // MARK: API

    func set(highlighted: Bool) {
        if highlighted {
            view.layer?.borderColor = tintColor.cgColor
        } else {
            view.layer?.borderColor = style.clear.cgColor
        }
    }


    // MARK: Helpers

    private func load(_ url: Media?) {
        guard let media = media else {
            return
        }

        Alamofire.request(media.thumbnail).responseImage { [weak self] response in
            if let image = response.value {
                self?.mediaImageView.set(image)
            }
        }

        displayIconIfNecessary(for: media)
        displayTitleIfNecessary()
    }

    /// Displays the play icon over video media items
    private func displayIconIfNecessary(for media: Media) {
        if media.type == .video {
            videoIconImageView.wantsLayer = true
            videoIconImageView.layer?.cornerRadius = videoIconImageView.frame.width / 2
            videoIconImageView.layer?.backgroundColor = style.darkBackground.cgColor
            videoIconImageView.isHidden = false
        }
    }

    private func displayTitleIfNecessary() {
        guard displaysTitle == true, let mediaTitle = media?.title else {
            return
        }

        let additionBackgroundWidth: CGFloat = 75

        let titleLabel = NSTextField(labelWithAttributedString: NSAttributedString(string: mediaTitle, attributes: titleAttributes))
        titleLabelBackgroundWidth.constant = titleLabel.attributedStringValue.size().width + additionBackgroundWidth
        titleLabel.frame.origin.x = additionBackgroundWidth / 2 - 3.0
        titleLabelBackgroundView.wantsLayer = true
        titleLabelBackgroundView.addSubview(titleLabel)

        let transitionLocation = Double(additionBackgroundWidth * 0.9 / 2.0 / titleLabelBackgroundWidth.constant)

        let gradient = CAGradientLayer()
        gradient.colors = [CGColor.clear, style.darkBackground.cgColor, style.darkBackground.cgColor, CGColor.clear]
        gradient.locations = [0.0, NSNumber(value: transitionLocation), NSNumber(value: (1.0 - transitionLocation)), 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.frame = NSRect(x: 0, y: 0, width: titleLabel.attributedStringValue.size().width + additionBackgroundWidth, height: titleLabelBackgroundView.frame.height)
        titleLabelBackgroundView.layer?.insertSublayer(gradient, at: 0)

        titleLabelBackgroundView.isHidden = false
    }
}
