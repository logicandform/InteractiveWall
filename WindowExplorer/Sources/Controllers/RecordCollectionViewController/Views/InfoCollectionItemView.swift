//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Alamofire
import AlamofireImage


class InfoCollectionItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "InfoCollectionItemView")

    @IBOutlet weak var dateTextField: NSTextField!
    @IBOutlet weak var descriptionTextField: NSTextField!

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
        let dateText = NSAttributedString(string: record.dates?.description(small: false) ?? "", attributes: style.recordDateAttributes)
        let dateHeight = dateText.height(containerWidth: width)
        let descriptionText = NSAttributedString(string: record.description ?? "", attributes: style.recordDescriptionAttributes)
        let descriptionHeight = descriptionText.height(containerWidth: width)
        let margins = Constants.textFieldVerticalMargin * 3

        return dateHeight + descriptionHeight + margins
    }


    // MARK: Helpers

    private func load(_ record: Record?) {
        guard let record = record else {
            return
        }

        var dateAttributes = style.recordDateAttributes
        dateAttributes[.foregroundColor] = record.type.color
        dateTextField.attributedStringValue = NSAttributedString(string: record.dates?.description(small: false) ?? "", attributes: dateAttributes)
        descriptionTextField.attributedStringValue = NSAttributedString(string: record.description ?? "", attributes: style.recordDescriptionAttributes)
    }
}
