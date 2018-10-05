//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class MediaItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("MediaItemView")

    @IBOutlet weak var mediaImageView: ImageView!
    @IBOutlet weak var videoIconImageView: NSImageView!

    private struct Constants {
        static let titleBackgroundAdditionalWidth: CGFloat = 80
        static let percentageOfAdditionalWidthForTransitionLocation: CGFloat = 0.9
    }

    var tintColor = style.selectedColor
    var media: Media? {
        didSet {
            load(media)
        }
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        set(highlighted: false)
    }


    // MARK: API

    func set(highlighted: Bool) {
        if highlighted {
            view.layer?.borderColor = tintColor.cgColor
        } else {
            view.layer?.borderColor = CGColor.clear
        }
    }


    // MARK: Setup

    private func setupViews() {
        view.wantsLayer = true
        view.layer?.borderWidth = 1
        videoIconImageView.wantsLayer = true
        videoIconImageView.layer?.cornerRadius = videoIconImageView.frame.width / 2
        videoIconImageView.layer?.backgroundColor = style.darkBackground.cgColor
    }


    // MARK: Helpers

    private func load(_ url: Media?) {
        guard let media = media else {
            return
        }

        videoIconImageView.isHidden = media.type != .video

        CachingNetwork.getThumbnail(for: media) { [weak self] thumbnail in
            if let thumbnail = thumbnail {
                self?.mediaImageView.set(thumbnail)
            }
        }
    }
}
