//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class SearchItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("SearchItemView")

    @IBOutlet weak var titleTextField: NSTextField!

    var tintColor = style.selectedColor

    var type: RecordType? {
        didSet {
            tintColor = type?.color ?? style.selectedColor
        }
    }

    var text: String? {
        didSet {
            titleTextField.stringValue = text ?? ""
        }
    }

    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        set(highlighted: false)
    }


    // MARK: API

    func set(highlighted: Bool) {
        if highlighted {
            view.layer?.backgroundColor = tintColor.cgColor
        } else {
            view.layer?.backgroundColor = style.darkBackground.cgColor
        }
    }
}
