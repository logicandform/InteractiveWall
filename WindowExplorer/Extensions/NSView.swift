//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

extension NSView {

    /// Animates the transition of the view's layer contents to a new image
    func transition(to image: NSImage, duration: TimeInterval, type: String = kCATransitionFade) {
        let transition = CATransition()
        transition.duration = duration
        transition.type = type
        layer?.add(transition, forKey: "contents")
        layer?.contents = image
    }
}
