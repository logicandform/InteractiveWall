//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum EntityState: Equatable {

    case `static`
    case drift(dx: CGFloat)
    case selected
    case seekEntity(RecordEntity)
    case seekLevel(Int)
    case dragging
    case reset
    case remove

    /// Determines if the current state is able to transition into the panning state
    var pannable: Bool {
        switch self {
        case .static, .drift, .selected, .dragging, .seekEntity:
            return true
        case .seekLevel, .reset, .remove:
            return false
        }
    }

    /// Determines if a RecordEntity should recognize a tap when in a given state
    var tappable: Bool {
        switch self {
        case .static, .drift, .selected, .seekEntity:
            return true
        case .seekLevel, .dragging, .reset, .remove:
            return false
        }
    }
}
