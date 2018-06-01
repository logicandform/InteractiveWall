//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

final class Style {

    let darkBackground = NSColor.black.withAlphaComponent(0.85)
    let selectedColor = NSColor(calibratedRed: 0, green: 200/255, blue: 1, alpha: 1)
    let unselectedRecordIcon = NSColor.gray
    let dragAreaBackground = NSColor.black.withAlphaComponent(0.85)

    // Records
    let artifactColor = NSColor(calibratedRed: 128/255, green: 1/255, blue: 206/255, alpha: 1)
    let schoolColor = NSColor(calibratedRed: 78/255, green: 106/255, blue: 200/255, alpha: 1)
    let eventColor = NSColor(calibratedRed: 145/255, green: 18/255, blue: 88/255, alpha: 1)
    let organizationColor = NSColor(calibratedRed: 16/255, green: 147/255, blue: 79/255, alpha: 1)
    let imageFilterTypeColor = NSColor.red

    // Related Items
    let relatedItemColor = NSColor(calibratedRed: 75/255, green: 91/255, blue: 100/255, alpha: 1)
    let noRelatedItemsColor = NSColor(calibratedRed: 33/255, green: 33/255, blue: 33/255, alpha: 1)

    // Windows
    let recordWindowSize = CGSize(width: 416, height: 640)
    let imageWindowSize = CGSize(width: 640, height: 410)
    let pdfWindowSize = CGSize(width: 600, height: 640)
    let playerWindowSize = CGSize(width: 640, height: 440)
    let searchWindowSize = CGSize(width: 350, height: 655)
    let searchScrollViewSize = CGSize(width: 350, height: 610)
    let minMediaWindowWidth: CGFloat = 550
    let maxMediaWindowWidth: CGFloat = 700
    let minMediaWindowHeight: CGFloat = 275
    let maxMediaWindowHeight: CGFloat = 1500
    let windowMargins: CGFloat = 20

    // Controllers
    let controllerOffset = 50

    // Menu
    let menuWindowSize = CGSize(width: 50, height: 300)
    let menuImageSize = CGSize(width: 50, height: 50)
    let menuSelectedColor = NSColor(calibratedRed: 0, green: 0.90, blue: 0.70, alpha: 1)

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
