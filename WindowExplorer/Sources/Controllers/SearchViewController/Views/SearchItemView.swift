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

    var item: SearchItemDisplayable? {
        didSet {
            apply(item)
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


    // MARK: Helpers

    private func apply(_ item: SearchItemDisplayable?) {
        titleTextField.stringValue = item?.title ?? ""

        if let recordType = item as? RecordType {
            type = recordType
        }
    }
}
