//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Alamofire
import AlamofireImage

class MediaItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("MediaItemView")

    @IBOutlet weak var mediaImageView: NSImageView!

    var imageURL: URL? {
        didSet {
            load(imageURL)
        }
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }


    // MARK: Helpers

    private func load(_ url: URL?) {
        guard let url = url else {
            return
        }

        Alamofire.request(url).responseImage { [weak self] response in
            if let image = response.value {
                self?.mediaImageView.image = image
            }
        }
    }

}
