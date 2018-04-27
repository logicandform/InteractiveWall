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
    @IBOutlet weak var titleLabelBackgroundHeight: NSLayoutConstraint!
    
    private struct Constants {
        static let fontName = "Soleil"
        static let fontSize: CGFloat = 13
        static let fontColor: NSColor = .white
        static let kern: CGFloat = 0.5
        static let titleBackgroundAdditionalWidth: CGFloat = 80
        static let percentageOfAdditionalWidthForTransitionLocation: CGFloat = 0.9
    }

    var tintColor = style.selectedColor
    var media: Media? {
        didSet {
            load(media)
        }
    }
    private var titleAttributes: [NSAttributedStringKey: Any] {
        let font = NSFont(name: Constants.fontName, size: Constants.fontSize) ?? NSFont.systemFont(ofSize: Constants.fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: Constants.fontColor,
                .kern: Constants.kern]
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
        displayTitle()
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

    private func displayTitle() {
        guard let mediaTitle = media?.title, !mediaTitle.isEmpty else {
            return
        }

        let maxWidth = view.frame.width - Constants.titleBackgroundAdditionalWidth

        // Setting up title label in backgroundView
        let titleLabel = NSTextField(labelWithAttributedString: NSAttributedString(string: mediaTitle, attributes: titleAttributes))
        titleLabel.setFrameSize(NSSize(width: min(maxWidth, titleLabel.frame.width), height: titleLabel.frame.height))
        titleLabel.frame.origin.x = Constants.titleBackgroundAdditionalWidth / 2
        titleLabelBackgroundWidth.constant = titleLabel.frame.size.width + Constants.titleBackgroundAdditionalWidth
        titleLabelBackgroundHeight.constant = titleLabel.frame.height
        titleLabelBackgroundView.addSubview(titleLabel)

        // Adding gradient
        let gradientTransitionLocation = Double(Constants.titleBackgroundAdditionalWidth * Constants.percentageOfAdditionalWidthForTransitionLocation / 2.0 / titleLabelBackgroundWidth.constant)
        let gradient = CAGradientLayer()
        gradient.colors = [CGColor.clear, style.darkBackground.cgColor, style.darkBackground.cgColor, CGColor.clear]
        gradient.locations = [0.0, NSNumber(value: gradientTransitionLocation), NSNumber(value: (1.0 - gradientTransitionLocation)), 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.frame = NSRect(x: 0, y: 0, width: titleLabelBackgroundWidth.constant, height: titleLabelBackgroundHeight.constant)
        titleLabelBackgroundView.wantsLayer = true
        titleLabelBackgroundView.layer?.insertSublayer(gradient, at: 0)

        titleLabelBackgroundView.isHidden = false
    }
}
