//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Alamofire
import AlamofireImage

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
        view.wantsLayer = true
        view.layer?.borderWidth = 1
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


    // MARK: Helpers

    private func load(_ url: Media?) {
        guard let media = media else {
            return
        }

        if let thumbnail = media.thumbnail {
            Alamofire.request(thumbnail).responseImage { [weak self] response in
                if let image = response.value {
                    self?.mediaImageView.set(image)
                }
            }
        }

        displayIconIfNecessary(for: media)
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
}
