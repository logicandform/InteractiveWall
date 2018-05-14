//
//  Created by Florian Schliep on 21.01.16.
//  Copyright © 2016 Florian Schliep. All rights reserved.
//

import Cocoa

public class ArrowControl: NSControl {

    private var mouseDown = false {
        didSet {
            needsDisplay = true
        }
    }


    // MARK: Properties

    public enum Direction {
        case left
        case right
    }

    public var direction = Direction.left {
        didSet {
            needsDisplay = true
        }
    }

    public var color = NSColor.black {
        didSet {
            needsDisplay = true
        }
    }


    // MARK: Drawing

    public override func draw(_ dirtyRect: NSRect) {
        let drawRightArrow = self.direction == .right
        let lineWidth: CGFloat = 4

        let bezierPath = NSBezierPath()
        bezierPath.move(to: NSPoint(x: drawRightArrow ? bounds.minX : bounds.maxX, y: bounds.maxY))
        bezierPath.line(to: NSPoint(x: drawRightArrow ? bounds.maxX-lineWidth*0.5 : bounds.minX+lineWidth*0.5, y: bounds.midY))
        bezierPath.line(to: NSPoint(x: drawRightArrow ? bounds.minX : bounds.maxX, y: bounds.minY))
        bezierPath.lineWidth = lineWidth
        bezierPath.lineCapStyle = .roundLineCapStyle
        bezierPath.lineJoinStyle = .roundLineJoinStyle
        (self.mouseDown ? self.color : self.color.withAlphaComponent(0.33)).setStroke()
        bezierPath.stroke()
    }


    // MARK: Mouse

    public override func mouseDown(with theEvent: NSEvent) {
        super.mouseDown(with: theEvent)
        self.mouseDown = true
    }

    public override func mouseUp(with theEvent: NSEvent) {
        super.mouseUp(with: theEvent)
        mouseDown = false

        guard let target = self.target, let action = self.action else { return }
        NSApp.sendAction(action, to: target, from: self)
    }
}
