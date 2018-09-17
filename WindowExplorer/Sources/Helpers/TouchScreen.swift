//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum TouchScreen {
    case ur9850
    case small

    var size: CGSize {
        switch self {
        case .ur9850:
            return CGSize(width: 21564, height: 12116)
        case .small:
            return CGSize(width: 4095, height: 2242.5)
        }
    }
}
