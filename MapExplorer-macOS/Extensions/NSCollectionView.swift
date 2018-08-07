//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


extension NSCollectionView {

    func animate(to point: NSPoint) {
        guard let clipView = self.superview else {
            return
        }

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = TimeInterval(1.0)
            clipView.animator().setBoundsOrigin(point)
        })
    }
}
