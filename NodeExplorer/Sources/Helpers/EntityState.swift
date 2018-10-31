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

    /// A Boolean value that indicates whether the physics body is moved by the physics simulation.
    var dynamic: Bool {
        switch self {
        case .drift, .seekLevel, .seekEntity:
            return true
        case .static, .selected, .dragging, .remove, .reset:
            return false
        }
    }

    /// Determines how much energy the physics body loses when it bounces off another object.
    var restitution: CGFloat {
        switch self {
        case .drift, .dragging, .static, .selected, .remove, .reset:
            return 0.4
        case .seekLevel, .seekEntity:
            return 0
        }
    }

    /// The roughness of the surface of the physics body.
    var friction: CGFloat {
        switch self {
        case .drift, .dragging, .static, .selected, .remove, .reset:
            return 0
        case .seekLevel, .seekEntity:
            return 1
        }
    }

    /// A property that reduces the body’s linear velocity.
    var linearDamping: CGFloat {
        return 1
    }

    /// A property that reduces the body’s rotational velocity.
    var angularDamping: CGFloat {
        return 0.5
    }
}
