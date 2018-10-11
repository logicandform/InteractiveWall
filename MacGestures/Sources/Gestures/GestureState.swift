//  Copyright © 2018 JABT. All rights reserved.

import Foundation


public enum GestureState: String {
    case possible
    case began
    case changed
    case ended
    case cancelled
    case failed
    case momentum
    case recognized
    case animated

    public var interruptible: Bool {
        switch self {
        case .momentum, .animated:
            return true
        default:
            return false
        }
    }
}
