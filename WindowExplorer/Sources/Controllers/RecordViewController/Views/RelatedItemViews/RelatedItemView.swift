//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class RelatedItemView: NSCollectionViewItem {

    @IBOutlet weak var mediaImageView: ImageView!

    var tintColor = NSColor.white
    var filterType = RecordFilterType.all
    var defaultBorders = [CALayer]()
    var highlightBorders = [CALayer]()

    var record: Record! {
        didSet {
            load(record)
        }
    }

    struct Constants {
        static let imageTransitionDuration = 0.3
        static let numberOfDescriptionLines = 3
    }


    // MARK: Life-Cycle

    override func awakeFromNib() {
        super.awakeFromNib()

        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        set(highlighted: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        mediaImageView.layer?.backgroundColor = .black
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        mediaImageView.set(nil)
        removeBorders()
    }


    // MARK: API

    /// Updates the borders for a given index
    func setupBorders(index: Int) {
        removeBorders()
    }

    /// Sets the highlighted state of the cell, should be called after `setupBorders`
    func set(highlighted: Bool) {

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

    private func removeBorders() {
        let borders = defaultBorders + highlightBorders
        defaultBorders.removeAll()
        highlightBorders.removeAll()

        for border in borders {
            border.removeFromSuperlayer()
        }
    }
}
