//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


enum AnimationType {
    case move(CGPoint)
    case scale(CGSize)
    case fade(out: Bool)

    var duration: TimeInterval {
        switch self {
        case .move:
            return style.moveAnimationDuration
        case .scale:
            return style.scaleAnimationDuration
        case .fade:
            return style.fadeAnimationDuration
        }
    }

    var key: String {
        switch self {
        case .move:
            return "move"
        case .scale:
            return "scale"
        case .fade:
            return "fade"
        }
    }

    func action(duration: TimeInterval) -> SKAction {
        switch self {
        case let .move(point):
            return SKAction.move(to: point, duration: duration)
        case let .scale(size):
            return SKAction.scale(to: size, duration: duration)
        case let .fade(out):
            if out {
                return SKAction.fadeOut(withDuration: duration)
            } else {
                return SKAction.fadeIn(withDuration: duration)
            }
        }
    }
}
