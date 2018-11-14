//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class RecordCollectionItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "RecordCollectionItemView")

    @IBOutlet private weak var mediaImageView: ImageView!
    @IBOutlet private weak var titleTextField: NSTextField!

    var tintColor = style.collectionColor
    var record: Record? {
        didSet {
            load(record)
        }
    }

    private struct Constants {
        static let imageTransitionDuration = 0.3
        static let screenEdgeMargin: CGFloat = 15
        static let interItemMargin: CGFloat = 5
        static let borderWidth: CGFloat = 3
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
            view.layer?.borderColor = tintColor.cgColor
            view.layer?.borderWidth = Constants.borderWidth
        } else {
            view.layer?.borderWidth = 0
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        mediaImageView.set(nil)
    }


    // MARK: Helpers

    private func load(_ record: Record?) {
        guard let record = record else {
            return
        }

        titleTextField.attributedStringValue = NSAttributedString(string: record.shortestTitle(), attributes: style.recordSmallHeaderAttributes)
        let placeholder = record.type.placeholder.tinted(with: record.type.color)

        if let media = record.media.first {
            CachingNetwork.getThumbnail(for: media) { [weak self] thumbnail in
                if let thumbnail = thumbnail {
                    self?.setImage(thumbnail, scaling: .aspectFill)
                } else {
                    self?.setImage(placeholder, scaling: .center)
                }
            }
        } else {
            setImage(placeholder, scaling: .center)
        }
    }

    private func setImage(_ image: NSImage?, scaling: ImageScaling) {
        mediaImageView.layer?.backgroundColor = .black
        mediaImageView.transition(image, duration: Constants.imageTransitionDuration, scaling: scaling)
    }
}
