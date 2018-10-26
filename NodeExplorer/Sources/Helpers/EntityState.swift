//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum EntityState: Equatable {
    case `static`
    case selected
    case seekEntity(RecordEntity)
    case seekLevel(Int)
    case dragging
    case reset
    case remove

    /// Determines if the current state is able to transition into the panning state
    var pannable: Bool {
        switch self {
        case .static, .selected, .dragging, .seekEntity(_):
            return true
        case .seekLevel(_), .reset, .remove:
            return false
        }
    }

    /// Determines if a RecordEntity should recognize a tap when in a given state
    var tappable: Bool {
        switch self {
        case .static, .selected, .seekEntity(_):
            return true
        case .seekLevel(_), .dragging, .reset, .remove:
            return false
        }
    }
}
