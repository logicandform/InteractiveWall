//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


enum ImageScaling {
    case aspectFill
    case center
    case resize
    case aspectFit

    var contentsGravity: CALayerContentsGravity {
        switch self {
        case .aspectFill:
            return .resizeAspectFill
        case .center:
            return .center
        case .resize:
            return .resize
        case .aspectFit:
            return .resizeAspect
        }
    }
}


class ImageView: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer = CALayer()
        self.layer?.contentsGravity = .resizeAspectFill
        self.layer?.contentsScale = NSScreen.mainScreen.backingScaleFactor
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.wantsLayer = true
        self.layer = CALayer()
        self.layer?.contentsGravity = .resizeAspectFill
        self.layer?.contentsScale = NSScreen.mainScreen.backingScaleFactor
    }


    // MARK: API

    func set(_ image: NSImage?, scaling: ImageScaling = .aspectFill) {
        layer?.contentsGravity = scaling.contentsGravity
        layer?.contents = image
    }

    func transition(_ image: NSImage?, duration: TimeInterval, scaling: ImageScaling = .aspectFill, type: CATransitionType = .fade) {
        let transition = CATransition()
        transition.duration = duration
        transition.type = type
        layer?.add(transition, forKey: "contents")
        layer?.contentsGravity = scaling.contentsGravity
        layer?.contents = image
    }
}
