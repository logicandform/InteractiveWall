//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

protocol GestureRecognizer: class {

    var gestureUpdated: ((GestureRecognizer) -> Void)? { get set }

    var state: GestureState { get }

    func start(_ touch: Touch, with properties: TouchProperties)

    func move(_ touch: Touch, with properties: TouchProperties)

    func end(_ touch: Touch, with properties: TouchProperties)

    func reset()

    func invalidate()
}

extension GestureRecognizer {

    var state: GestureState {
        return .possible
    }

    func invalidate() {}
}

enum GestureState: String {
    case possible
    case began
    case changed
    case ended
    case cancelled
    case failed
    case momentum
    case recognized
    case system
}
