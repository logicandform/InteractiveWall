//
//  AspectFillImageView.swift
//  WindowExplorer
//
//  Created by Travis on 2018-03-28.
//  Copyright © 2018 JABT. All rights reserved.
//

import Cocoa

class AspectFillImageView: NSImageView {
    var _image: NSImage?
    override var image: NSImage? {
        set {
            self.layer = CALayer()
            if let image = newValue {
                if image.size.width > image.size.height {
                    self.layer?.contentsGravity = kCAGravityResizeAspectFill
                }
            }
            self.layer?.contents = newValue
            self.wantsLayer = true
            _image = image
        }

        get {
            return _image
        }
    }
}
