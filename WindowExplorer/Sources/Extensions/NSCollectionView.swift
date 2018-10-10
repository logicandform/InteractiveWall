//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


extension NSCollectionView {

    func animate(to point: NSPoint, duration: TimeInterval, completion: (() -> Void)? = nil) {
        guard let clipView = superview else {
            completion?()
            return
        }

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = duration
            NSAnimationContext.current.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            clipView.animator().setBoundsOrigin(point)
        }, completionHandler: completion)
    }
}
