//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class RelatedItemView: NSCollectionViewItem {

    @IBOutlet weak var mediaImageView: ImageView!

    var tintColor = NSColor.white
    var filterType = RecordFilterType.all
    var record: Record! {
        didSet {
            load(record)
        }
    }

    struct Constants {
        static let imageTransitionDuration = 0.3
        static let numberOfDescriptionLines = 3
        static let borderWidth: CGFloat = 3
    }


    // MARK: API

    func set(highlighted: Bool) {
        if highlighted {
            view.layer?.borderColor = tintColor.cgColor
        } else {
            view.layer?.borderColor = style.darkBackground.cgColor
        }
    }


    // MARK: Life-Cycle

    override func awakeFromNib() {
        super.awakeFromNib()

        view.wantsLayer = true
        set(highlighted: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.layer?.borderWidth = Constants.borderWidth
        view.layer?.borderColor = style.darkBackground.cgColor
        view.layer?.backgroundColor = style.darkBackground.cgColor
        mediaImageView.layer?.backgroundColor = style.relatedItemBackgroundColor.cgColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        mediaImageView.set(nil)
    }


    // MARK: Helpers

    func load(_ record: Record) {
        let placeholder = record.type.placeholder.tinted(with: record.type.color)

        if let media = record.media.first {
            CachingNetwork.getThumbnail(for: media) { [weak self] thumbnail in
                if let thumbnail = thumbnail {
                    self?.mediaImageView.set(thumbnail, scaling: .aspectFill)
                } else {
                    self?.mediaImageView.set(placeholder, scaling: .center)
                }
            }
        } else {
            mediaImageView.set(placeholder, scaling: .center)
        }
    }
}
