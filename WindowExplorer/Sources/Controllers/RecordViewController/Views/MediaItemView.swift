//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Alamofire
import AlamofireImage

class MediaItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("MediaItemView")

    @IBOutlet weak var mediaImageView: NSImageView!

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
            view.layer?.borderColor = style.selectedColor.cgColor
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
                self?.mediaImageView.image = image
            }
        }

        if media.type == .video, let image = NSImage(named: "play-icon")  {
            let imageView = NSImageView(image: image)
            let radius: CGFloat = 40
            imageView.frame = CGRect(origin: CGPoint(x: view.frame.midX - radius, y: view.frame.midY - radius), size: CGSize(width: radius * 2, height: radius * 2))
            mediaImageView.addSubview(imageView)
        }
    }

}
