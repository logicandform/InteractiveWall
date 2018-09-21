//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

extension NSView {

    /// Animates the transition of the view's layer contents to a new image
    func transition(to image: NSImage?, duration: TimeInterval, type: CATransitionType = .fade) {
        let transition = CATransition()
        transition.duration = duration
        transition.type = type
        layer?.add(transition, forKey: "contents")
        layer?.contents = image
    }

    /// Calculates the screen index based off the x-position of the view
    func calculateScreenIndex() -> Int? {
        guard let window = window, let screen = NSScreen.containing(x: window.frame.midX), let screenIndex = screen.orderedIndex else {
            return nil
        }

        return screenIndex
    }
}

extension NSCollectionView {

    func item(at row: Int, section: Int = 0) -> NSCollectionViewItem? {
        return item(at: IndexPath(item: row, section: section))
    }
}

extension NSScrollView {

    var canScroll: Bool {
        let contentViewHeight = contentView.documentRect.size.height
        let scrollViewHeight = bounds.size.height
        return contentViewHeight > scrollViewHeight
    }

    func canScroll(contentHeight: CGFloat? = nil) -> Bool {
        let scrollViewHeight = bounds.size.height
        if let contentHeight = contentHeight {
            return contentHeight > scrollViewHeight
        }

        let contentViewHeight = contentView.documentRect.size.height
        return contentViewHeight > scrollViewHeight
    }

    func hasReachedBottom(with delta: CGFloat = 0) -> Bool {
        let contentOffsetY = contentView.bounds.origin.y + delta
        return contentOffsetY >= verticalOffsetForBottom
    }

    func hasReachedTop(with delta: CGFloat = 0) -> Bool {
        let contentOffsetY = contentView.bounds.origin.y + delta
        return contentOffsetY <= 0
    }

    private var verticalOffsetForBottom: CGFloat {
        let scrollViewHeight = bounds.size.height
        let scrollViewContentSizeHeight = contentView.documentRect.size.height
        return scrollViewContentSizeHeight - scrollViewHeight
    }
}
