//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class TimelineControlItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("TimelineControlItemView")

    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var titleTextField: NSTextField!

    override var title: String? {
        didSet {
            set(title: title)
        }
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = .clear
    }


    // MARK: API

    func set(highlighted: Bool) {
        if highlighted {
            contentView.layer?.backgroundColor = style.selectedColor.cgColor
            titleTextField.textColor = .black
        } else {
            contentView.layer?.backgroundColor = .clear
            titleTextField.textColor = .white
        }
    }


    // MARK: Helpers

    private func set(title: String?) {
        titleTextField.stringValue = title ?? ""
    }
}
