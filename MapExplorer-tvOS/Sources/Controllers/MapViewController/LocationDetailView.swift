//  Copyright © 2018 slant. All rights reserved.

import UIKit

class LocationDetailView: UIView {

    static let identifier = "LocationDetailView"


    var locationItem: LocationItem? {
        didSet {
            title.text = locationItem?.locationName
            subtitle.text = locationItem?.title
        }
    }
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    var latitude: Double = 0.0
}
