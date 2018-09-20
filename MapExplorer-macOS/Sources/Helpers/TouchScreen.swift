//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum TouchScreen {
    case ur9851
    case pct2485

    var frameSize: CGSize {
        switch self {
        case .ur9851:
            return CGSize(width: 3840, height: 2160)
        case .pct2485:
            return CGSize(width: 1920, height: 1080)
        }
    }

    var touchSize: CGSize {
        switch self {
        case .ur9851:
            return CGSize(width: 21564, height: 12116)
        case .pct2485:
            return CGSize(width: 4095, height: 4095)
        }
    }
}
