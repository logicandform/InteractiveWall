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

    private struct Constants {
        static let fadePercentage = 0.1
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = .clear
        set(highlighted: false)
    }


    // MARK: API

    func set(highlighted: Bool) {
        if highlighted {
            contentView.layer?.backgroundColor = style.selectedColor.cgColor
            titleTextField.textColor = .black
            gradient(on: true)
        } else {
            contentView.layer?.backgroundColor = .clear
            titleTextField.textColor = .white
            gradient(on: false)
        }
    }


    // MARK: Helpers

    private func set(title: String?) {
        titleTextField.stringValue = title ?? ""
    }

    private func gradient(on: Bool) {
        switch on {
        case true:
            let transparent = NSColor.clear.cgColor
            let opaque = style.darkBackgroundOpaque.cgColor
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = view.bounds
            gradientLayer.colors = [transparent, opaque, opaque, transparent]
            gradientLayer.locations = [0.0, NSNumber(value: Constants.fadePercentage), NSNumber(value: 1.0 - Constants.fadePercentage), 1.0]
            gradientLayer.transform = CATransform3DMakeRotation(CGFloat.pi / 2, 0, 0, 1)
            view.layer?.mask = gradientLayer
        case false:
            view.layer?.mask = nil
        }
    }
}
