//  Copyright © 2018 JABT. All rights reserved.

import Foundation


public enum FrictionLevel {
    case low
    case medium
    case high
    case custom(Double)

    var scale: Double {
        switch self {
        case .low:
            return 0.0003
        case .medium:
            return 0.003
        case .high:
            return 0.03
        case .custom(let scale):
            return scale
        }
    }
}
