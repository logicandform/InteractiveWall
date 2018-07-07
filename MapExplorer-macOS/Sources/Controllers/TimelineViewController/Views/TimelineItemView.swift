//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class TimelineItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "TimelineItemView")

    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var highlightView: NSView!
    @IBOutlet weak var animatedHighlightView: NSView!
    @IBOutlet weak var animatedWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundView: NSView!
    @IBOutlet weak var titleTextField: NSTextField!

    var tintColor = style.selectedColor
    var event: TimelineEvent! {
        didSet {
            load(event)
        }
    }


    // MARK: Init

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.wantsLayer = true
        highlightView.wantsLayer = true
        animatedHighlightView.wantsLayer = true
        backgroundView.wantsLayer = true
        set(highlighted: true)
        contentView.layer?.backgroundColor = style.darkBackground.cgColor
        titleTextField.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .light)
    }


    // MARK: API

    func set(highlighted: Bool) {
        if highlighted {
//            contentView.layer?.backgroundColor = tintColor.cgColor
            animatedHighlightView.layer?.backgroundColor = tintColor.cgColor
        } else {
//            contentView.layer?.backgroundColor = style.darkBackground.cgColor
            animatedHighlightView.layer?.backgroundColor = style.darkBackground.cgColor
        }
    }

    func animate(to size: CGSize) {
        if size.width > view.frame.size.width {
            // Expansion animation
            NSAnimationContext.runAnimationGroup({ _ in
                NSAnimationContext.current.duration = 1.50
                animatedWidthConstraint.animator().constant = view.frame.size.width
            }, completionHandler: { [weak self] in
                NSAnimationContext.runAnimationGroup({ _ in
                    NSAnimationContext.current.duration = 1.50
                    self?.animatedWidthConstraint.constant = size.width
                    self?.view.animator().frame.size.width = size.width
                })
            })
        } else {
            // Compression animation
            let newSize = CGSize(width: size.width - 2, height: size.height - 4)
            NSAnimationContext.runAnimationGroup({ _ in
                NSAnimationContext.current.duration = 1.50
//                animatedWidthConstraint.animator().constant = size.width
                view.animator().frame.size.width = size.width
            }, completionHandler: { [weak self] in
                self?.view.frame.size.width = size.width
                NSAnimationContext.runAnimationGroup({ _ in
                    NSAnimationContext.current.duration = 1.50
                    self?.animatedWidthConstraint.animator().constant = 0
                })
            })
        }
    }


    // MARK: Overrides

    override func prepareForReuse() {
        super.prepareForReuse()
    }


    // MARK: Helpers

    private func load(_ event: TimelineEvent) {
        tintColor = NSColor.color(from: event.title)
        highlightView.layer?.backgroundColor = tintColor.cgColor
        titleTextField.attributedStringValue = NSAttributedString(string: event.title, attributes: style.timelineTitleAttributes)
    }
}
