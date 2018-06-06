//  Copyright © 2018 JABT. All rights reserved.

//  Copyright © 2016-2017 RichAppz Limited. All rights reserved.
//  richappz.com - (rich@richappz.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.

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

    var backgroundColor: NSColor? {
        get {
            guard let layer = layer, let backgroundColor = layer.backgroundColor else { return nil }
            return NSColor(cgColor: backgroundColor)
        }
        set {
            wantsLayer = true
            layer?.backgroundColor = newValue?.cgColor
        }
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
