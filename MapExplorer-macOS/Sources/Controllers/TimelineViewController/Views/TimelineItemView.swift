//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class TimelineItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "TimelineItemView")

    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var contentViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var highlightView: NSView!
    @IBOutlet weak var highlightViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundView: NSView!
    @IBOutlet weak var backgroundViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTextField: NSTextField!

    var tintColor = style.selectedColor
    var event: TimelineEvent! {
        didSet {
            load(event)
        }
    }

    private struct Constants {
        static let unselectedHighlightWidth: CGFloat = 5
        static let animationDuration = 0.3
        static let textOffset: CGFloat = 4
    }


    // MARK: Init

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.wantsLayer = true
        highlightView.wantsLayer = true
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = style.darkBackground.cgColor
        titleTextField.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .light)
    }


    // MARK: API

    func set(highlighted: Bool) {
        if highlighted {
            contentView.layer?.backgroundColor = tintColor.cgColor
        } else {
            contentView.layer?.backgroundColor = style.darkBackground.cgColor
        }
    }

    func animate(to size: CGSize) {
        if size.width > view.frame.size.width {
            expand(to: size)
        } else {
            compress(to: size)
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

    private func expand(to size: CGSize) {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration / 2
            highlightViewWidthConstraint.animator().constant = view.frame.size.width
        }, completionHandler: { [weak self] in
            if let strongSelf = self {
                strongSelf.contentViewTrailingConstraint.constant = size.width - strongSelf.view.frame.width
                strongSelf.view.setFrameSize(size)
            }
            NSAnimationContext.runAnimationGroup({ _ in
                NSAnimationContext.current.duration = Constants.animationDuration / 2
                self?.contentViewTrailingConstraint.animator().constant = Constants.textOffset
                self?.highlightViewWidthConstraint.animator().constant = size.width
            })
        })
    }

    private func compress(to size: CGSize) {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration / 2
            contentViewTrailingConstraint.animator().constant = size.width
            highlightViewWidthConstraint.animator().constant = size.width
        }, completionHandler: { [weak self] in
            self?.contentViewTrailingConstraint.constant = Constants.textOffset
            self?.view.frame.size = size
            NSAnimationContext.runAnimationGroup({ _ in
                NSAnimationContext.current.duration = Constants.animationDuration / 2
                self?.highlightViewWidthConstraint.animator().constant = Constants.unselectedHighlightWidth
            })
        })
    }
}
