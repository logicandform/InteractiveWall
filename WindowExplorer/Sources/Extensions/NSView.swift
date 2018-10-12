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

    func addCustomBorders() {
        for position in BorderPosition.allCases {
            let borderLayer = border(for: position)
            layer?.addSublayer(borderLayer)
        }
    }

    private enum BorderPosition: CaseIterable {
        case left
        case bottom
        case right
    }

    private func border(for position: BorderPosition) -> CALayer {
        let layer = CALayer()
        layer.frame = CGRect(origin: .zero, size: CGSize(width: style.defaultBorderWidth, height: frame.height - style.windowHighlightWidth))
        layer.backgroundColor = style.defaultBorderColor.cgColor
        layer.zPosition = style.windowHighlightZPosition

        switch position {
        case .bottom:
            layer.frame = CGRect(origin: .zero, size: CGSize(width: frame.width, height: style.defaultBorderWidth))
            layer.autoresizingMask = .layerWidthSizable
        case .left:
            layer.frame = CGRect(origin: .zero, size: CGSize(width: style.defaultBorderWidth, height: frame.height - style.windowHighlightWidth))
            layer.autoresizingMask = .layerHeightSizable
        case .right:
            layer.frame = CGRect(origin: CGPoint(x: frame.width - style.defaultBorderWidth, y: 0), size: CGSize(width: style.defaultBorderWidth, height: frame.height - style.windowHighlightWidth))
            layer.autoresizingMask = [.layerHeightSizable, .layerMinXMargin]
        }

        return layer
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
