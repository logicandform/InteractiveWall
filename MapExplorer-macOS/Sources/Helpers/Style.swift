//  Copyright © 2018 slant. All rights reserved.

import Foundation
import AppKit

let style = Style()

final class Style {

    let darkBackground = NSColor.black.withAlphaComponent(0.9)
    let darkBackgroundOpaque = NSColor.black
    let selectedColor = NSColor(calibratedRed: 0, green: 200/255, blue: 1, alpha: 1)
    let clear = NSColor.clear

    // Map Annotation Markers
    let artifactColor = NSColor(calibratedRed: 128/255, green: 1/255, blue: 206/255, alpha: 1)
    let schoolColor = NSColor(calibratedRed: 78/255, green: 106/255, blue: 200/255, alpha: 1)
    let eventColor = NSColor(calibratedRed: 145/255, green: 18/255, blue: 88/255, alpha: 1)
    let organizationColor = NSColor(calibratedRed: 16/255, green: 147/255, blue: 79/255, alpha: 1)

    // Border Style
    let borderColor = NSColor(calibratedRed: 0, green: 0.90, blue: 0.70, alpha: 1)

    // Timeline Controller
    let timelineBackgroundColor = NSColor(white: 0.1, alpha: 0.9)

    var timelineTitleAttributes: [NSAttributedStringKey: Any] {
        let font = NSFont(name: "Soleil", size: 16) ?? NSFont.systemFont(ofSize: 16)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 1]
    }
}
