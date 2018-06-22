//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Alamofire
import AlamofireImage


class TestimonyItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "TestimonyItemView")

    @IBOutlet weak var mediaImageView: ImageView!
    @IBOutlet weak var titleTextField: NSTextField!

    var tintColor = style.testimonyColor
    var testimony: Media? {
        didSet {
            load(testimony)
        }
    }

    struct Constants {
        static let testimonyPlaceholderImage = NSImage(named: "testimony-placeholder")
        static let imageTransitionDuration = 0.3
    }


    // MARK: Init

    override func awakeFromNib() {
        super.awakeFromNib()
        view.wantsLayer = true
        set(highlighted: false)
    }


    // MARK: API

    func set(highlighted: Bool) {
        if highlighted {
            view.layer?.backgroundColor = tintColor.cgColor
        } else {
            view.layer?.backgroundColor = style.darkBackground.cgColor
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        mediaImageView.set(nil)
    }


    // MARK: Helpers

    private func load(_ media: Media?) {
        guard let media = media else {
            return
        }

        titleTextField.attributedStringValue = NSAttributedString(string: media.title ?? "", attributes: style.windowTitleAttributes)

        let placeholder = Constants.testimonyPlaceholderImage?.tinted(with: tintColor)
        Alamofire.request(media.thumbnail).responseImage { [weak self] response in
            if let image = response.value {
                self?.setImage(image, scaling: .aspectFill)
            } else {
                self?.setImage(placeholder, scaling: .center)
            }
        }
    }

    private func setImage(_ image: NSImage?, scaling: ImageScaling) {
        mediaImageView.layer?.backgroundColor = style.relatedItemBackgroundColor.cgColor
        mediaImageView.transition(image, duration: Constants.imageTransitionDuration, scaling: scaling)
    }
}
