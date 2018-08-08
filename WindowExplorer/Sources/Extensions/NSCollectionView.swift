//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


extension NSCollectionView {

    func animate(to point: NSPoint, duration: CGFloat, completion: (() -> Void)? = nil) {
        guard let clipView = self.superview else {
            return
        }

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = TimeInterval(duration)
            clipView.animator().setBoundsOrigin(point)
        }, completionHandler: completion)
    }
}
