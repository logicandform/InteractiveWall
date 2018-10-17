//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class RelatedItemListView: RelatedItemView {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "RelatedItemListView")

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionView: NSTextView!


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionView.drawsBackground = false
        descriptionView.textContainer?.maximumNumberOfLines = Constants.numberOfDescriptionLines
    }


    // MARK: Overrides

    override func set(highlighted: Bool) {
        for border in highlightBorders {
            border.backgroundColor = tintColor.cgColor
            border.isHidden = !highlighted
        }
    }

    override func setupBorders(index: Int) {
        super.setupBorders(index: index)
        let highlightThickness = style.windowHighlightWidth + style.defaultBorderWidth
        let topThickness = index.isZero ? highlightThickness : highlightThickness - style.defaultBorderWidth
        highlightBorders.append(view.addBorder(for: .top, thickness: topThickness, zPosition: 5))
        highlightBorders.append(view.addBorder(for: .left, thickness: highlightThickness, zPosition: 5))
        highlightBorders.append(view.addBorder(for: .right, thickness: highlightThickness, zPosition: 5))
        highlightBorders.append(view.addBorder(for: .bottom, thickness: highlightThickness, zPosition: 5))
        defaultBorders.append(view.addBorder(for: .left))
        defaultBorders.append(view.addBorder(for: .right))
        defaultBorders.append(view.addBorder(for: .bottom))
        if index.isZero {
            defaultBorders.append(view.addBorder(for: .top))
        }
        set(highlighted: false)
    }

    override func load(_ record: Record) {
        super.load(record)

        titleLabel.attributedStringValue = NSAttributedString(string: record.title, attributes: style.relatedItemViewTitleAttributes)
        let description = NSAttributedString(string: record.description ?? "", attributes: style.relatedItemViewDescriptionAttributes)
        descriptionView.textStorage?.setAttributedString(description)
    }
}
