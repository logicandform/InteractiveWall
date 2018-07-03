//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


private struct Constants {
    static let listItemsPerRow: CGFloat = 1
    static let imageItemsPerRow: CGFloat = 3
}


enum RelatedItemViewLayout {
    case list
    case grid

    var identifier: NSUserInterfaceItemIdentifier {
        switch self {
        case .list:
            return RelatedItemListView.identifier
        case .grid:
            return RelatedItemImageView.identifier
        }
    }

    var itemSize: CGSize {
        switch self {
        case .list:
            return CGSize(width: style.listItemWidth, height: style.listItemHeight)
        case .grid:
            return CGSize(width: style.imageItemWidth, height: style.imageItemHeight)
        }
    }

    var rowWidth: CGFloat {
        switch self {
        case .list:
            let itemsPerRow = Constants.listItemsPerRow
            return style.listItemWidth * itemsPerRow + style.itemSpacing * (itemsPerRow - 1)
        case .grid:
            let itemsPerRow = Constants.imageItemsPerRow
            return style.imageItemWidth * itemsPerRow + style.itemSpacing * (itemsPerRow - 1)
        }
    }
}
