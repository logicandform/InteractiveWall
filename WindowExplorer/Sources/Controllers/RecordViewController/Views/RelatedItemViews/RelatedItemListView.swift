//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class RelatedItemListView: RelatedItemView {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "RelatedItemListView")

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!


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
        highlightBorders.append(view.addBorder(for: .top, thickness: topThickness, zPosition: style.windowHighlightZPosition))
        highlightBorders.append(view.addBorder(for: .left, thickness: highlightThickness, zPosition: style.windowHighlightZPosition))
        highlightBorders.append(view.addBorder(for: .right, thickness: highlightThickness, zPosition: style.windowHighlightZPosition))
        highlightBorders.append(view.addBorder(for: .bottom, thickness: highlightThickness, zPosition: style.windowHighlightZPosition))
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
        descriptionLabel.attributedStringValue = NSAttributedString(string: record.description ?? "", attributes: style.relatedItemViewDescriptionAttributes)
    }
}
