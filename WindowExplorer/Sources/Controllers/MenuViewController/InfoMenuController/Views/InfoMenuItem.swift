//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class InfoMenuItem {
    let title: String
    let description: String
    let video: Media?

    private struct Constants {
        static let titleFontSize: CGFloat = 28
        static let titleLineSpacing: CGFloat = 0
        static let titleMaximumLineheight: CGFloat = titleFontSize + 5
        static let titleForegroundColor = NSColor.white
        static let descriptionFontSize: CGFloat = 16
        static let descriptionLineSpacing: CGFloat = 0
        static let descriptionMaximumLineHeight: CGFloat = descriptionFontSize + 5
        static let descriptionParagraphSpacing: CGFloat = 8
        static let descriptionForegroundColor = NSColor.white
        static let fontName = "Soleil"
        static let kern: CGFloat = 0.5
    }


    // MARK: Init

    init(title: String, description: String, video: Media?) {
        self.title = title
        self.description = description
        self.video = video
    }

    var titleAttributes: [NSAttributedStringKey: Any] {
        let font = NSFont(name: Constants.fontName, size: Constants.titleFontSize) ?? NSFont.systemFont(ofSize: Constants.titleFontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Constants.titleLineSpacing
        paragraphStyle.maximumLineHeight = Constants.titleMaximumLineheight

        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: Constants.titleForegroundColor,
                .kern: Constants.kern
        ]
    }

    var descriptionAttributes: [NSAttributedStringKey: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Constants.descriptionLineSpacing
        paragraphStyle.paragraphSpacing = Constants.descriptionParagraphSpacing
        paragraphStyle.maximumLineHeight = Constants.descriptionMaximumLineHeight
        paragraphStyle.lineBreakMode = .byWordWrapping
        let font = NSFont(name: Constants.fontName, size: Constants.descriptionFontSize) ?? NSFont.systemFont(ofSize: Constants.descriptionFontSize)
        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: Constants.descriptionForegroundColor,
                .kern: Constants.kern
        ]
    }
}
