//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


struct InfoLabel {
    let title: String
    let description: String
}


struct InfoItem {
    let title: String
    let labels: [InfoLabel]
    let media: Media


    // MARK: Init

    init(title: String, labels: [InfoLabel], media: Media) {
        self.title = title
        self.labels = labels
        self.media = media
    }
}
