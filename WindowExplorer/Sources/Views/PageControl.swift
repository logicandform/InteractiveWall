//
//  Created by Florian Schliep on 21.01.16.
//  Copyright © 2016 Florian Schliep. All rights reserved.
//

import Foundation
import AppKit

public class PageControl: NSControl {

    private var needsToRedrawIndicators = false


    // MARK: Appearance

    public var color = NSColor.black {
        didSet {
            redrawIndicators()
        }
    }

    public var indicatorSize: CGFloat = 7 {
        didSet {
            redrawIndicators()
        }
    }

    public enum Style: Int {
        case dot
        case circle
    }

    public var style = Style.dot {
        didSet {
            redrawIndicators()
        }
    }


    // MARK: Pages

    public var numberOfPages: UInt = 0 {
        didSet {
            redrawIndicators()
        }
    }

    public var selectedPage: UInt = 0 {
        didSet {
            redrawIndicators()
        }
    }


    // MARK: NSControl

    public override var frame: NSRect {
        willSet {
            needsToRedrawIndicators = true
        }
    }


    // MARK: Drawing

    public override func draw(_ dirtyRect: NSRect) {
        guard needsToRedrawIndicators else {
            return
        }

        if numberOfPages > 1 {
            for index in 0 ... numberOfPages-1 {
                var fill = true
                let frame = frameOfIndicator(at: index)
                let lineWidth: CGFloat = 1

                switch (self.style, index == selectedPage) {
                case (.dot, true), (.circle, true):
                    color.setFill()
                case (.dot, false):
                    color.withAlphaComponent(0.33).setFill()
                case (.circle, false):
                    color.setStroke()
                    fill = false
                    frame.insetBy(dx: lineWidth*0.5, dy: lineWidth*0.5)
                }

                let path = NSBezierPath(ovalIn: frame)
                if fill {
                    path.fill()
                } else {
                    path.lineWidth = lineWidth
                    path.stroke()
                }
            }
        }

        needsToRedrawIndicators = false
    }


    // MARK: Mouse

    public override func mouseDown(with theEvent: NSEvent) {
        let location = convert(theEvent.locationInWindow, from: nil)
        highlightIndicator(at: location)
    }

    public override func mouseDragged(with theEvent: NSEvent) {
        let location = convert(theEvent.locationInWindow, from: nil)
        highlightIndicator(at: location)
    }

    public override func mouseUp(with theEvent: NSEvent) {
        let location = convert(theEvent.locationInWindow, from: nil)
        highlightIndicator(at: location, sendAction: true)
    }


    // MARK: Helpers

    private func highlightIndicator(at location: NSPoint, sendAction: Bool = false) {
        var newPage = selectedPage
        for index in 0...numberOfPages-1 {
            if frameOfIndicator(at: index).contains(location) {
                newPage = index
                break
            }
        }
        if selectedPage != newPage {
            selectedPage = newPage
        }

        guard sendAction, let target = target, let action = action else { return }
        NSApp.sendAction(action, to: target, from: self)
    }

    private func frameOfIndicator(at index: UInt) -> NSRect {
        let centerDrawingAroundSpace = (numberOfPages % 2 == 0)
        let centeredIndex = numberOfPages/2
        let centeredFrame = NSRect(x: bounds.midX - (centerDrawingAroundSpace ? -indicatorSize/2 : indicatorSize/2), y: bounds.midY - indicatorSize/2, width: indicatorSize, height: indicatorSize)
        let distanceToCenteredIndex = CGFloat(centeredIndex)-CGFloat(index)

        return NSRect(x: centeredFrame.minX - distanceToCenteredIndex*indicatorSize*2, y: bounds.midY - indicatorSize/2, width: indicatorSize, height: indicatorSize)
    }

    private func redrawIndicators() {
        needsToRedrawIndicators = true
        needsDisplay = true
    }
}
