//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class TimelineItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "TimelineItemView")

    @IBOutlet private weak var contentView: NSView!
    @IBOutlet private weak var contentViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var highlightView: NSView!
    @IBOutlet private weak var highlightViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var backgroundView: NSView!
    @IBOutlet private weak var titleTextField: NSTextField!

    var tintColor = NSColor.white
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
        view.wantsLayer = true
        contentView.wantsLayer = true
        highlightView.wantsLayer = true
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = style.darkBackground.cgColor
        titleTextField.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .light)
    }


    // MARK: API

    func set(selected: Bool, attributes: NSCollectionViewLayoutAttributes) {
        view.layer?.zPosition = CGFloat(attributes.zIndex)
        if selected {
            view.frame.size.width = CGFloat(attributes.frame.size.width)
        } else {
            view.frame.size.width = CGFloat(attributes.frame.size.width)
            highlightViewWidthConstraint.constant = Constants.unselectedHighlightWidth
        }
        contentViewTrailingConstraint.constant = Constants.textOffset
    }

    func animate(to size: CGSize, with zPosition: CGFloat, containedIn frame: CGRect, layout: NSCollectionViewLayout?) {
        if size.width >= view.frame.size.width {
            view.layer?.zPosition = zPosition
            expand(to: size, with: layout, containedIn: frame)
        } else {
            compress(to: size, at: zPosition, with: layout, containedIn: frame)
        }
    }


    // MARK: Helpers

    private func load(_ event: TimelineEvent) {
        tintColor = NSColor.color(from: event.title)
        highlightView.layer?.backgroundColor = tintColor.cgColor
        titleTextField.attributedStringValue = NSAttributedString(string: event.title, attributes: style.timelineTitleAttributes)
    }

    private func expand(to size: CGSize, with layout: NSCollectionViewLayout?, containedIn frame: CGRect) {
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
            }, completionHandler: {
                if let invalid = layout?.invalidationContext(forBoundsChange: frame) {
                    layout?.invalidateLayout(with: invalid)
                }
            })
        })
    }

    private func compress(to size: CGSize, at zPosition: CGFloat, with layout: NSCollectionViewLayout?, containedIn frame: CGRect) {
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
            }, completionHandler: { [weak self] in
                self?.view.layer?.zPosition = zPosition
                if let invalid = layout?.invalidationContext(forBoundsChange: frame) {
                    layout?.invalidateLayout(with: invalid)
                }
            })
        })
    }
}
