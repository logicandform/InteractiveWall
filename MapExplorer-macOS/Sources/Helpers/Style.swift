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
    let clusterColor = #colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 1)

    // Window Levels
    let mapWindowLevel = NSWindow.Level(28)
    let timelineWindowLevel = NSWindow.Level(29)

    // Timeline
    let timelineBackgroundColor = NSColor(white: 0.1, alpha: 0.9)
    let timelineBorderColor = NSColor.gray
    let timelineHeaderText = NSColor.gray
    let timelineBorderWidth: CGFloat = 2
    let flagWidth: CGFloat = 180
    let timelineTailWidth: CGFloat = 2
    let timelineTailMargin: CGFloat = 3

    var timelineTitleAttributes: [NSAttributedStringKey: Any] {
        let font = NSFont(name: "Soleil", size: 14) ?? NSFont.systemFont(ofSize: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 1]
    }

    var timelineDateAttributes: [NSAttributedStringKey: Any] {
        let font = NSFont(name: "Soleil", size: 9) ?? NSFont.systemFont(ofSize: 9)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 1]
    }
}
