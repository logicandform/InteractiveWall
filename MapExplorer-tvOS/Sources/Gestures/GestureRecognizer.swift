//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

protocol GestureRecognizer: class {

    var gestureUpdated: ((GestureRecognizer) -> Void)? { get set }

    var gestureRecognized: ((GestureRecognizer) -> Void)? { get set }

    var state: State { get }

    func start(_ properties: TouchProperties, of touch: Touch?)

    func move(_ touch: Touch, with properties: TouchProperties)

    func end(_ touch: Touch, with properties: TouchProperties)

    func reset()

    func invalidate()
}

enum State {
    case possible
    case began
    case changed
    case ended
    case cancelled
    case failed
    case momentum
    case recognized
}
