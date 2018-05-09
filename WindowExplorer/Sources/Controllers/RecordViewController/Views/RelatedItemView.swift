//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Alamofire
import AlamofireImage

class RelatedItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "RelatedItemView")

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionView: NSTextView!
    @IBOutlet weak var mediaImageView: ImageView!

    var tintColor = style.selectedColor
    var record: RecordDisplayable? {
        didSet {
            load(record)
        }
    }

    private struct Constants {
        static let imageTransitionDuration = 0.3
        static let numberOfDescriptionLines = 3
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

    private func load(_ record: RecordDisplayable?) {
        guard let record = record else {
            return
        }

        descriptionView.drawsBackground = false
        descriptionView.textContainer?.maximumNumberOfLines = Constants.numberOfDescriptionLines
        titleLabel.attributedStringValue = NSAttributedString(string: record.title, attributes: style.relatedItemViewTitleAttributes)
        descriptionView.textStorage?.setAttributedString(NSAttributedString(string: record.description ?? "", attributes: style.relatedItemViewDescriptionAttributes))
        let placeholder = record.type.placeholder.tinted(with: record.type.color)

        if let media = record.media.first {
            Alamofire.request(media.thumbnail).responseImage { [weak self] response in
                if let image = response.value {
                    self?.setImage(image, scaling: .aspectFill)
                } else {
                    self?.setImage(placeholder, scaling: .resize)
                }
            }
        } else {
            setImage(placeholder, scaling: .resize)
        }
    }

    private func setImage(_ image: NSImage, scaling: ImageScaling) {
        mediaImageView.transition(image, duration: Constants.imageTransitionDuration, scaling: scaling)
    }
}
