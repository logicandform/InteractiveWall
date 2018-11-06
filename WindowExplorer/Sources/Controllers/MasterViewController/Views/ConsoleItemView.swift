//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class ConsoleItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("ConsoleItemView")

    @IBOutlet weak var dateTextField: NSTextField!
    @IBOutlet weak var typeTextField: NSTextField!
    @IBOutlet weak var messageTextField: NSTextField!

    private struct Constants {
        static let consoleOutputSideWidth: CGFloat = 480
        static let textFieldMargins: CGFloat = 12
    }

    var log: ConsoleLog! {
        didSet {
            load(log)
        }
    }


    // MARK: API

    static func height(for log: ConsoleLog) -> CGFloat {
        let width = Constants.consoleOutputSideWidth - Constants.textFieldMargins * 2
        let titleString = log.action == nil ? log.type.title : "\(log.type.title) - \(log.action!.title)"
        let typeString = NSAttributedString(string: titleString, attributes: style.consoleLogAttributes)
        let typeHeight = typeString.height(containerWidth: width)
        let dateString = NSAttributedString(string: log.message, attributes: style.consoleLogAttributes)
        let dateHeight = dateString.height(containerWidth: width)
        let margins = Constants.textFieldMargins * 3

        return typeHeight + dateHeight + margins
    }


    // MARK: Setup

    private func load(_ log: ConsoleLog) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d 'at' h:mm:ss a"
        let dateString = formatter.string(from: log.date)
        dateTextField.attributedStringValue = NSAttributedString(string: dateString, attributes: style.consoleLogAttributes)
        var titleAttributes = style.consoleLogAttributes
        titleAttributes[.foregroundColor] = log.type.color
        let titleString = log.action == nil ? log.type.title : "\(log.type.title) - \(log.action!.title)"
        typeTextField.attributedStringValue = NSAttributedString(string: titleString, attributes: titleAttributes)
        messageTextField.attributedStringValue = NSAttributedString(string: log.message, attributes: style.consoleLogAttributes)
    }
}
