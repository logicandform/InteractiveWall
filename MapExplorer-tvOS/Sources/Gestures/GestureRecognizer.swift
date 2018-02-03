//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import UIKit
import C4

protocol GestureRecognizer: class {

    var gestureUpdated: ((GestureRecognizer) -> Void)? { get set }

    var gestureRecognized: ((GestureRecognizer) -> Void)? { get set }

    var state: UIGestureRecognizerState { get set }

    func start(_ touch: Touch, with properties: TouchProperties)

    func move(_ touch: Touch, with properties: TouchProperties)

    func end(_ touch: Touch, with properties: TouchProperties)

    func reset()

    func invalidate()
}
