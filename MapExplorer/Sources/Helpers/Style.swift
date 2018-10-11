//  Copyright © 2018 slant. All rights reserved.

import Foundation
import AppKit


final class Style {


    // MARK: General Colors

    let darkBackground = NSColor.black.withAlphaComponent(0.85)
    let darkBackgroundOpaque = NSColor.black


    // MARK: RecordType Colors

    let artifactColor = NSColor(srgbRed: 205.0/255.0, green: 33.0/255.0, blue: 54.0/255.0, alpha: 1.0)
    let schoolColor = NSColor(srgbRed: 7.0/255.0, green: 61.0/255.0, blue: 224.0/255.0, alpha: 1.0)
    let eventColor = NSColor(srgbRed: 228.0/255.0, green: 54.0/255.0, blue: 188.0/255.0, alpha: 1.0)
    let organizationColor = NSColor(srgbRed: 0.0/255.0, green: 159.0/255.0, blue: 75.0/255.0, alpha: 1.0)
    let collectionColor = NSColor(srgbRed: 229.0/255.0, green: 121.0/255.0, blue: 0.0/255.0, alpha: 1.0)
    let individualColor = NSColor.red
    let themeColor = NSColor(srgbRed: 0.0/255.0, green: 154.0/255.0, blue: 254.0/255.0, alpha: 1.0)


    // MARK: Window Levels

    let masterWindowLevel = NSWindow.Level.normal
    let nodeWindowLevel = NSWindow.Level(27)
    let mapWindowLevel = NSWindow.Level(28)
    let timelineWindowLevel = NSWindow.Level(29)
    let borderWindowLevel = NSWindow.Level(30)
    let recordWindowLevel = NSWindow.Level(31)
    let menuWindowLevel = NSWindow.Level(32)
    let touchIndicatorWindowLevel = NSWindow.Level(33)


    // MARK: Timeline

    let timelineBackgroundColor = NSColor(white: 0.1, alpha: 0.95)
    let timelineBorderColor = NSColor.gray
    let timelineShadingColor = NSColor.black.withAlphaComponent(0.5)
    let timelineHeaderText = NSColor.gray
    let timelineBorderWidth: CGFloat = 2
    let timelineHeaderHeight: CGFloat = 30
    let timelineHeaderOffset: CGFloat = 18
    let timelineFlagBackgroundColor = NSColor.black.withAlphaComponent(0.8)
    let timelineItemWidth: CGFloat = 180
    let timelineFlagPoleWidth: CGFloat = 2
    let timelineTailColor = NSColor(white: 0.2, alpha: 1)
    let timelineTailWidth: CGFloat = 1
    let timelineTailMargin: CGFloat = 9
    lazy var timelineTailGap: CGFloat = timelineTailWidth + timelineTailMargin
    let timelineTailMarkerWidth: CGFloat = 1

    var timelineTitleAttributes: [NSAttributedString.Key: Any] {
        let font = NSFont(name: "Soleil", size: 14) ?? NSFont.systemFont(ofSize: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 1]
    }

    var timelineDateAttributes: [NSAttributedString.Key: Any] {
        let font = NSFont(name: "Soleil", size: 9) ?? NSFont.systemFont(ofSize: 9)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 1]
    }

    var mapLabelAttributes: [NSAttributedString.Key: Any] {
        let fontSize: CGFloat = 26
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.maximumLineHeight = fontSize + 5
        paragraphStyle.lineBreakMode = .byWordWrapping
        let font = NSFont(name: "Soleil", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 0.5
        ]
    }

    var clusterLabelAttributes: [NSAttributedString.Key: Any] {
        let fontSize: CGFloat = 15
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.maximumLineHeight = fontSize + 5
        paragraphStyle.lineBreakMode = .byWordWrapping
        let font = NSFont(name: "Soleil", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.black,
                .kern: 0.5
        ]
    }
}
