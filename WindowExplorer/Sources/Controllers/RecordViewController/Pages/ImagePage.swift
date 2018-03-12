//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Alamofire
import AlamofireImage


class ImagePage: NSViewController {
    static let pageIdentifier = NSPageController.ObjectIdentifier("ImagePage")

    @IBOutlet weak var imageView: NSImageView!

    var imageURL: URL? {
        didSet {
            loadImage()
        }
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }


    // MARK: Helpers

    private func loadImage() {
        guard let url = imageURL else {
            return
        }

        Alamofire.request(url).responseImage(completionHandler: { [weak self] response in
            if let image = response.value {
                self?.imageView.image = image
            }
        })
    }
    
}
