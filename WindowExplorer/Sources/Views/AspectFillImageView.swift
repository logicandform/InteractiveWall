//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class AspectFillImageView: NSImageView {
    private var aspectFillImage: NSImage?

    override var image: NSImage? {
        get {
            return aspectFillImage
        }
        set {
            self.layer = CALayer()
            if let image = newValue {
                if image.size.width > image.size.height {
                    self.layer?.contentsGravity = kCAGravityResizeAspectFill
                }
            }
            self.layer?.contents = newValue
            self.wantsLayer = true
            aspectFillImage = image
        }
    }
}
