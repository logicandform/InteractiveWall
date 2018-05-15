//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

extension NSView {

    /// Animates the transition of the view's layer contents to a new image
    func transition(to image: NSImage?, duration: TimeInterval, type: String = kCATransitionFade) {
        let transition = CATransition()
        transition.duration = duration
        transition.type = type
        layer?.add(transition, forKey: "contents")
        layer?.contents = image
    }
}

extension NSCollectionView {

    func item(at row: Int, section: Int = 0) -> NSCollectionViewItem? {
        return item(at: IndexPath(item: row, section: section))
    }
}

extension NSScrollView {
    var hasReachedBottom: Bool {
        let contentOffsetY = self.contentView.bounds.origin.y
        return contentOffsetY >= verticalOffsetForBottom
    }

    private var verticalOffsetForBottom: CGFloat {
        let scrollViewHeight = self.bounds.size.height
        let scrollViewContentSizeHeight = self.contentView.documentRect.size.height

        return scrollViewContentSizeHeight - scrollViewHeight
    }
}
