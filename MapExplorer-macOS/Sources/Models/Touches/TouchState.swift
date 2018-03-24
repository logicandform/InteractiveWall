//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MONode

enum TouchState: Int {
    case down
    case up
    case moved

    private struct Keys {
        static let rawValue = "rawValue"
    }

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

    init?(json: JSON) {
        guard let rawValue = json[Keys.rawValue] as? Int, let type = TouchState(rawValue: rawValue) else {
            return nil
        }

        self = type
    }

    func toJSON() -> JSON {
        return [Keys.rawValue: rawValue]
    }
}
