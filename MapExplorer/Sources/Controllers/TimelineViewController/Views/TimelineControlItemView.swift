//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class TimelineControlItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("TimelineControlItemView")

    @IBOutlet private weak var contentView: NSView!
    @IBOutlet private weak var titleTextField: NSTextField!

    override var title: String? {
        didSet {
            set(title: title)
        }
    }

    private struct Constants {
        static let fadePercentage = 0.1
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }


    // MARK: Setup

    func setupView() {
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = .clear
        titleTextField.textColor = style.timelineHeaderText
    }


    // MARK: Helpers

    private func set(title: String?) {
        titleTextField.stringValue = title ?? ""
    }
}
