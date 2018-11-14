//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class InfoCollectionItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "InfoCollectionItemView")

    @IBOutlet private weak var dateTextField: NSTextField!
    @IBOutlet private weak var descriptionTextField: NSTextField!
    @IBOutlet private weak var dateHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var dateTopConstraint: NSLayoutConstraint!

    var tintColor = style.collectionColor
    var record: Record? {
        didSet {
            load(record)
        }
    }

    private struct Constants {
        static let textFieldVerticalMargin: CGFloat = 20
    }


    // MARK: API

    static func height(for record: Record, width: CGFloat) -> CGFloat {
        let hasDate = record.dates != nil
        let dateText = NSAttributedString(string: record.dates?.description(small: false) ?? "", attributes: style.recordDateAttributes)
        let dateHeight = hasDate ? dateText.height(containerWidth: width) : 0
        let dateMargins = hasDate ? Constants.textFieldVerticalMargin : 0
        let descriptionText = NSAttributedString(string: record.description ?? "", attributes: style.recordDescriptionAttributes)
        let descriptionHeight = descriptionText.height(containerWidth: width)
        let descriptionMargins = Constants.textFieldVerticalMargin * 2

        return dateHeight + dateMargins + descriptionHeight + descriptionMargins
    }


    // MARK: Helpers

    private func load(_ record: Record?) {
        guard let record = record else {
            return
        }

        let hasDate = record.dates != nil
        var dateAttributes = style.recordDateAttributes
        dateAttributes[.foregroundColor] = record.type.color
        let dateText = NSAttributedString(string: record.dates?.description(small: false) ?? "", attributes: dateAttributes)
        dateTextField.attributedStringValue = dateText
        descriptionTextField.attributedStringValue = NSAttributedString(string: record.description ?? "", attributes: style.recordDescriptionAttributes)
        let dateHeight = dateText.height(containerWidth: view.frame.width)
        dateHeightConstraint.constant = hasDate ? dateHeight : 0
        dateTopConstraint.constant = hasDate ? Constants.textFieldVerticalMargin : 0
    }
}
