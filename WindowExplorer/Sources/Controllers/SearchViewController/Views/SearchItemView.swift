//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class SearchItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("SearchItemView")

    @IBOutlet weak var titleTextField: NSTextField!


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        set(highlighted: false)
    }


    // MARK: API

    func set(highlighted: Bool) {
        if highlighted {
            view.layer?.backgroundColor = style.selectedColor.cgColor
        } else {
            view.layer?.backgroundColor = style.darkBackground.cgColor
        }
    }
}
