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


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

    }


    // MARK: API

    static func height(for log: ConsoleLog) -> CGFloat {
        let width = Constants.consoleOutputSideWidth - Constants.textFieldMargins * 2
        let typeString = NSAttributedString(string: log.type.title, attributes: style.consoleLogAttributes)
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
        var typeAttributes = style.consoleLogAttributes
        typeAttributes[.foregroundColor] = log.type.color
        typeTextField.attributedStringValue = NSAttributedString(string: log.type.title, attributes: typeAttributes)
        messageTextField.attributedStringValue = NSAttributedString(string: log.message, attributes: style.consoleLogAttributes)
    }
}
