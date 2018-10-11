//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


final class Style {


    // MARK: General colors

    let darkBackground = NSColor.black.withAlphaComponent(0.85)
    let darkBackgroundOpaque = NSColor.black
    let dragAreaBackground = NSColor.black.withAlphaComponent(0.85)
    let unselectedRecordIcon = NSColor.gray
    let menuSelectedColor = NSColor(calibratedRed: 0, green: 0.90, blue: 0.70, alpha: 1)
    let menuUnselectedColor = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 1)
    let menuButtonBackgroundColor = NSColor(srgbRed: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 0.32)
    let relatedItemBackgroundColor = NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.11, alpha: 1)
    let touchIndicatorColor = NSColor(calibratedRed: 0, green: 200/255, blue: 1, alpha: 1)
    let zoomControlColor = NSColor(white: 0.2, alpha: 0.8)


    // MARK: RecordType Colors

    let artifactColor = NSColor(srgbRed: 205.0/255.0, green: 33.0/255.0, blue: 54.0/255.0, alpha: 1.0)
    let schoolColor = NSColor(srgbRed: 7.0/255.0, green: 61.0/255.0, blue: 224.0/255.0, alpha: 1.0)
    let eventColor = NSColor(srgbRed: 228.0/255.0, green: 54.0/255.0, blue: 188.0/255.0, alpha: 1.0)
    let organizationColor = NSColor(srgbRed: 0.0/255.0, green: 159.0/255.0, blue: 75.0/255.0, alpha: 1.0)
    let collectionColor = NSColor(srgbRed: 229.0/255.0, green: 121.0/255.0, blue: 0.0/255.0, alpha: 1.0)
    let individualColor = NSColor.red
    let themeColor = NSColor(srgbRed: 0.0/255.0, green: 154.0/255.0, blue: 254.0/255.0, alpha: 1.0)


    // MARK: Windows Properties

    let recordWindowSize = CGSize(width: 416, height: 650)
    let collectionRecordWindowSize = CGSize(width: 416, height: 650)
    let imageWindowSize = CGSize(width: 640, height: 410)
    let pdfWindowSize = CGSize(width: 600, height: 640)
    let playerWindowSize = CGSize(width: 1013, height: 650)
    let searchWindowFrame = CGSize(width: 350, height: 655)
    let menuWindowWidth: CGFloat = 700
    let borderWindowWidth: CGFloat = 4
    let infoWindowSize = CGSize(width: 500, height: 800)
    let masterWindowSize = CGSize(width: 740, height: 500)
    let minMediaWindowWidth: CGFloat = 416
    let maxMediaWindowWidth: CGFloat = 650
    let minMediaWindowHeight: CGFloat = 416
    let maxMediaWindowHeight: CGFloat = 650
    let windowMargins: CGFloat = 20
    let windowStackOffset = CGVector(dx: 25, dy: -40)


    // MARK: Window Levels

    let masterWindowLevel = NSWindow.Level.normal
    let nodeWindowLevel = NSWindow.Level(27)
    let mapWindowLevel = NSWindow.Level(28)
    let timelineWindowLevel = NSWindow.Level(29)
    let borderWindowLevel = NSWindow.Level(30)
    let recordWindowLevel = NSWindow.Level(31)
    let menuWindowLevel = NSWindow.Level(32)
    let touchIndicatorWindowLevel = NSWindow.Level(33)


    // MARK: Text Properties

    let largeTitleTrailingSpace: CGFloat = 6
    let dateTrailingSpace: CGFloat = 20
    let smallHeaderTrailingSpace: CGFloat = 4
    let descriptionTrailingSpace: CGFloat = 10
    let missingDateTitleTrailingSpace: CGFloat = 47


    // MARK: Text Attributes

    var windowTitleAttributes: [NSAttributedString.Key: Any] {
        let font = NSFont(name: "Soleil", size: 16) ?? NSFont.systemFont(ofSize: 16)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 1.0]
    }

    var relatedItemsTitleAttributes: [NSAttributedString.Key: Any] {
        let font = NSFont(name: "Soleil", size: 13) ?? NSFont.systemFont(ofSize: 13)

        return [.font: font,
                .foregroundColor: NSColor.white,
                .kern: 1.0,
                .baselineOffset: font.fontName == "Soleil" ? 1 : 0]
    }

    var mediaItemTitleAttributes: [NSAttributedString.Key: Any] {
        let font = NSFont(name: "Soleil", size: 13) ?? NSFont.systemFont(ofSize: 13)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 0.5]
    }

    var relatedItemViewTitleAttributes: [NSAttributedString.Key: Any] {
        let font = NSFont(name: "Soleil-Bold", size: 11) ?? NSFont.systemFont(ofSize: 11)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [.paragraphStyle: paragraphStyle,
                .kern: 1,
                .foregroundColor: NSColor.white,
                .font: font]
    }

    var relatedItemViewDescriptionAttributes: [NSAttributedString.Key: Any] {
        let font = NSFont(name: "Soleil", size: 10) ?? NSFont.systemFont(ofSize: 10)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.paragraphSpacingBefore = 0

        return [.paragraphStyle: paragraphStyle,
                .kern: 1,
                .foregroundColor: NSColor.white,
                .font: font,
                .baselineOffset: 0]
    }

    var recordLargeTitleAttributes: [NSAttributedString.Key: Any] {
        let fontSize: CGFloat = 28
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.maximumLineHeight = fontSize + 5
        let font = NSFont(name: "Soleil", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 0.5
        ]
    }

    var recordDateAttributes: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.paragraphSpacingBefore = 0
        let font = NSFont(name: "Soleil", size: 14) ?? NSFont.systemFont(ofSize: 14)
        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 0.5
        ]
    }

    var recordSmallHeaderAttributes: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.paragraphSpacingBefore = 20
        let font = NSFont(name: "Soleil", size: 12) ?? NSFont.systemFont(ofSize: 12)
        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 0.5
        ]
    }

    var recordDescriptionAttributes: [NSAttributedString.Key: Any] {
        let fontSize: CGFloat = 16
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

    var consoleLogAttributes: [NSAttributedString.Key: Any] {
        let fontSize: CGFloat = 14
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.paragraphSpacing = 0
        let font = NSFont(name: "Soleil", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 0.5
        ]
    }
}
