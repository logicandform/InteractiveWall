//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

final class Style {

    let darkBackground = NSColor.black.withAlphaComponent(0.85)
    let darkBackgroundOpaque = NSColor.black
    let selectedColor = NSColor(calibratedRed: 0, green: 200/255, blue: 1, alpha: 1)
    let unselectedRecordIcon = NSColor.gray
    let dragAreaBackground = NSColor.black.withAlphaComponent(0.85)
    let artifactColor = NSColor(calibratedRed: 128/255, green: 1/255, blue: 206/255, alpha: 1)
    let schoolColor = NSColor(calibratedRed: 78/255, green: 106/255, blue: 200/255, alpha: 1)
    let eventColor = NSColor(calibratedRed: 145/255, green: 18/255, blue: 88/255, alpha: 1)
    let organizationColor = NSColor(calibratedRed: 16/255, green: 147/255, blue: 79/255, alpha: 1)
    let testimonyColor = NSColor(calibratedRed: 0.96, green: 0.51, blue: 0.07, alpha: 1)

    // Windows
    let recordWindowSize = CGSize(width: 416, height: 650)
    let imageWindowSize = CGSize(width: 640, height: 410)
    let pdfWindowSize = CGSize(width: 600, height: 640)
    let playerWindowSize = CGSize(width: 640, height: 440)
    let searchWindowSize = CGSize(width: 350, height: 655)
    let searchScrollViewSize = CGSize(width: 350, height: 600)
    let borderWindowSize = NSSize(width: 4, height: 2160)
    let testimonyWindowSize = CGSize(width: 416, height: 645)
    let minMediaWindowWidth: CGFloat = 550
    let maxMediaWindowWidth: CGFloat = 700
    let minMediaWindowHeight: CGFloat = 275
    let maxMediaWindowHeight: CGFloat = 1500
    let windowMargins: CGFloat = 20

    // Controllers
    let controllerOffset = 50

    // Record Controller
    let imageFilterTypeColor = NSColor.red
    let relatedRecordsMaxSize = CGSize(width: 300, height: 534)
    let relatedItemColor = NSColor(calibratedRed: 75/255, green: 91/255, blue: 100/255, alpha: 1)
    let noRelatedItemsColor = NSColor(calibratedRed: 33/255, green: 33/255, blue: 33/255, alpha: 1)
    let relatedItemBackgroundColor = NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.11, alpha: 1)

    // Menu Controller
    let menuWindowSize = CGSize(width: 50, height: 300)
    let menuImageSize = CGSize(width: 50, height: 50)
    let menuSelectedColor = NSColor(calibratedRed: 0, green: 0.90, blue: 0.70, alpha: 1)
    let menuLockIconPosition = CGPoint(x: -3, y: 3)
    let menuSecondarySelectedColor = NSColor(calibratedRed: 0.06, green: 0.28, blue: 0.24, alpha: 1)

    // Settings Controller
    let settingsWindowSize = CGSize(width: 275, height: 245)
    let artifactSecondarySelectedColor = NSColor(calibratedRed: 0.17, green: 0, blue: 0.27, alpha: 1)
    let schoolSecondarySelectedColor = NSColor(calibratedRed: 0, green: 0.19, blue: 0.32, alpha: 1)
    let organizationSecondarySelectedColor = NSColor(calibratedRed: 0, green: 0.25, blue: 0.16, alpha: 1)
    let eventSecondarySelectedColor = NSColor(calibratedRed: 0.29, green: 0.07, blue: 0.16, alpha: 1)
    let toggleUnselectedColor = NSColor(calibratedRed: 0.51, green: 0.62, blue: 0.65, alpha: 1)
    let toggleSecondaryUnselectedColor = NSColor(calibratedRed: 0.16, green: 0.18, blue: 0.19, alpha: 1)
    let toggleSwitchFrame = NSRect(x: 0, y: 0, width: 32, height: 16)
    let toggleSwitchOffset: CGFloat = -30

    // Border Controller
    let borderColor = NSColor(calibratedRed: 0, green: 0.90, blue: 0.70, alpha: 1)


    // Titles
    var windowTitleAttributes: [NSAttributedStringKey: Any] {
        let font = NSFont(name: "Soleil", size: 16) ?? NSFont.systemFont(ofSize: 16)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 1.5]
    }

    var relatedItemsTitleAttributes: [NSAttributedStringKey: Any] {
        let font = NSFont(name: "Soleil", size: 13) ?? NSFont.systemFont(ofSize: 13)

        return [.font: font,
                .foregroundColor: NSColor.white,
                .kern: 0.5,
                .baselineOffset: font.fontName == "Soleil" ? 1 : 0]
    }

    var mediaItemTitleAttributes: [NSAttributedStringKey: Any] {
        let font = NSFont(name: "Soleil", size: 13) ?? NSFont.systemFont(ofSize: 13)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 0.5]
    }

    var relatedItemViewTitleAttributes: [NSAttributedStringKey: Any] {
        let font = NSFont(name: "Soleil-Bold", size: 11) ?? NSFont.systemFont(ofSize: 11)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [.paragraphStyle: paragraphStyle,
                .kern: 1,
                .foregroundColor: NSColor.white,
                .font: font]
    }

    var relatedItemViewDescriptionAttributes: [NSAttributedStringKey: Any] {
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
}
