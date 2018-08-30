//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class InfoMenuItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "InfoMenuItemView")

    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var descriptionTextField: NSTextField!


    // MARK: Init

    override func awakeFromNib() {
        super.awakeFromNib()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
    }


    // MARK: Helpers

    static func infoItemHeight(for record: RecordDisplayable) -> CGFloat {
        let width = style.infoWindowSize.width
        let textFieldWidth = CGFloat(width - (style.infoMenuItemEdgeInset * 2))
        let title = NSAttributedString(string: record.title, attributes: record.titleAttributes)
        let titleHeight = title.height(containerWidth: textFieldWidth)

        if let description = record.description {
            let margins = style.infoMenuItemEdgeInset * 2 + style.infoMenuItemBuffer
            let descriptionString = NSAttributedString(string: description, attributes: record.descriptionAttributes)
            let descriptionHeight = descriptionString.height(containerWidth: textFieldWidth)
            return titleHeight + descriptionHeight + margins
        } else {
            return titleHeight + style.infoMenuItemEdgeInset * 2
        }
    }
}
