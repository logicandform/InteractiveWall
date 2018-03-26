//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MONode

enum TouchState: Int {
    case down
    case up
    case moved

    init?(from type: PacketType) {
        switch type {
        case .touchDown:
            self = .down
        case .touchUp:
            self = .up
        case .touchMove:
            self = .moved
        default:
            return nil
        }
    }
}
