//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import QuartzCore


extension CATransaction {
    static func suppressAnimations(actions: () -> Void) {
        begin()
        setAnimationDuration(0)
        actions()
        commit()
    }
}
