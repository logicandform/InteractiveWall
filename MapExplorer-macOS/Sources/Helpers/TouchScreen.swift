//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum TouchScreen {
    case ur9851
    case small

    var touchSize: CGSize {
        switch self {
        case .ur9851:
            return CGSize(width: 21564, height: 12116)
        case .small:
            return CGSize(width: 4095, height: 4095)
        }
    }
}
