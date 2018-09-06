//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class RelatedItemListView: RelatedItemView {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "RelatedItemListView")

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionView: NSTextView!


    // MARK: Overrides

    override func load(_ record: Record?) {
        guard let record = record else {
            return
        }

        super.load(record)
        descriptionView.drawsBackground = false
        descriptionView.textContainer?.maximumNumberOfLines = Constants.numberOfDescriptionLines
        titleLabel.attributedStringValue = NSAttributedString(string: record.title, attributes: style.relatedItemViewTitleAttributes)
        descriptionView.textStorage?.setAttributedString(NSAttributedString(string: record.description ?? "", attributes: style.relatedItemViewDescriptionAttributes))
    }
}
