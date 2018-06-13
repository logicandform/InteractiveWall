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

    /// Calculates the screen index based off the x-position of the view
    func calculateScreenIndex() -> Int? {
        guard let window = window, let screen = NSScreen.containing(x: window.frame.midX), let screenIndex = screen.orderedIndex else {
            return nil
        }

        return screenIndex
    }

    /// Calculates the map index based off the x-position of view
    func calculateMapIndex() -> Int? {
        guard let window = window, let screen = NSScreen.containing(x: window.frame.midX) else {
            return nil
        }

        let mapWidth = screen.frame.width / CGFloat(Configuration.mapsPerScreen)
        let mapIndex = Int((window.frame.origin.x - screen.frame.minX) / mapWidth)
        return mapIndex
    }

    /// Calculates the app ID based off the x-position of the view
    func calculateAppID() -> Int? {
        guard let window = window, let screen = NSScreen.containing(x: window.frame.midX), let screenIndex = screen.orderedIndex else {
            return nil
        }

        let baseMapForScreen = (screenIndex - 1) * Int(Configuration.mapsPerScreen)
        let mapWidth = screen.frame.width / CGFloat(Configuration.mapsPerScreen)
        let mapForScreen = Int((window.frame.origin.x - screen.frame.minX) / mapWidth)
        return mapForScreen + baseMapForScreen
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

    var hasReachedBottom: Bool {
        let contentOffsetY = contentView.bounds.origin.y
        return contentOffsetY >= verticalOffsetForBottom
    }

    var hasReachedTop: Bool {
        let contentOffsetY = contentView.bounds.origin.y
        return contentOffsetY <= 0
    }

    private var verticalOffsetForBottom: CGFloat {
        let scrollViewHeight = bounds.size.height
        let scrollViewContentSizeHeight = contentView.documentRect.size.height

        return scrollViewContentSizeHeight - scrollViewHeight
    }
}
