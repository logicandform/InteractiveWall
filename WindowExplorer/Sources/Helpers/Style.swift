//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


final class Style {

    // Colors
    let darkBackground = NSColor.black.withAlphaComponent(0.85)
    let darkBackgroundOpaque = NSColor.black
    let selectedColor = NSColor(calibratedRed: 0, green: 200/255, blue: 1, alpha: 1)
    let unselectedRecordIcon = NSColor.gray
    let dragAreaBackground = NSColor.black.withAlphaComponent(0.85)
    let artifactColor = NSColor(calibratedRed: 128/255, green: 1/255, blue: 206/255, alpha: 1)
    let schoolColor = NSColor(calibratedRed: 78/255, green: 106/255, blue: 200/255, alpha: 1)
    let eventColor = NSColor(calibratedRed: 145/255, green: 18/255, blue: 88/255, alpha: 1)
    let organizationColor = NSColor(calibratedRed: 16/255, green: 147/255, blue: 79/255, alpha: 1)
    let collectionColor = NSColor.orange
    let individualColor = NSColor.red
    let menuSelectedColor = NSColor(calibratedRed: 0, green: 0.90, blue: 0.70, alpha: 1)
    let menuUnselectedColor = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 1)
    let menuButtonBackgroundColor = NSColor(deviceWhite: 0.2, alpha: 1)

    // Windows
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

    // Text
    let largeTitleTrailingSpace: CGFloat = 6
    let dateTrailingSpace: CGFloat = 20
    let smallHeaderTrailingSpace: CGFloat = 4
    let descriptionTrailingSpace: CGFloat = 10
    let missingDateTitleTrailingSpace: CGFloat = 47

    // Window displacement
    let windowOffset = CGVector(dx: 25, dy: -40)

    // Record Controller
    let relatedRecordsMaxSize = CGSize(width: 300, height: 565)
    let relatedItemColor = NSColor(calibratedRed: 75/255, green: 91/255, blue: 100/255, alpha: 1)
    let noRelatedItemsColor = NSColor(calibratedRed: 33/255, green: 33/255, blue: 33/255, alpha: 1)
    let relatedItemBackgroundColor = NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.11, alpha: 1)
    let relatedRecordsListItemWidth: CGFloat = 300
    let relatedRecordsListItemHeight: CGFloat = 80
    let relatedRecordsImageItemWidth: CGFloat = 180
    let relatedRecordsImageItemHeight: CGFloat = 180
    let relatedRecordsItemSpacing: CGFloat = 5

    // Menu Controller
    let menuLockIconPosition = CGPoint(x: -3, y: 3)
    let menuSecondarySelectedColor = NSColor(calibratedRed: 0.06, green: 0.28, blue: 0.24, alpha: 1)
    let menuAccessibilityIconColor = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 1)

    // Border Controller
    let borderColor = NSColor(calibratedRed: 0, green: 0.90, blue: 0.70, alpha: 1)

    // Zoom Control
    let zoomControlColor = NSColor(white: 0.2, alpha: 0.8)

    // Window Levels
    let masterWindowLevel = NSWindow.Level.normal
    let nodeWindowLevel = NSWindow.Level(27)
    let mapWindowLevel = NSWindow.Level(28)
    let timelineWindowLevel = NSWindow.Level(29)
    let borderWindowLevel = NSWindow.Level(30)
    let recordWindowLevel = NSWindow.Level(31)
    let menuWindowLevel = NSWindow.Level(32)
    let touchIndicatorWindowLevel = NSWindow.Level(33)

    // Audio
    let audioSyncInterval = 1.0 / 30.0

    // Titles
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
