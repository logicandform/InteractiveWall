//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


private struct Constants {
    static let itemSpacing: CGFloat = 5
    static let listItemsPerRow: CGFloat = 1
    static let listItemWidth: CGFloat = 300
    static let listItemHeight: CGFloat = 80
    static let imageItemsPerRow: CGFloat = 3
    static let imageItemWidth: CGFloat = 180
    static let imageItemHeight: CGFloat = 180
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
            return CGSize(width: Constants.listItemWidth, height: Constants.listItemHeight)
        case .grid:
            return CGSize(width: Constants.imageItemWidth, height: Constants.imageItemHeight)
        }
    }

    var rowWidth: CGFloat {
        switch self {
        case .list:
            let itemsPerRow = Constants.listItemsPerRow
            return Constants.listItemWidth * itemsPerRow + Constants.itemSpacing * (itemsPerRow - 1)
        case .grid:
            let itemsPerRow = Constants.imageItemsPerRow
            return Constants.imageItemWidth * itemsPerRow + Constants.itemSpacing * (itemsPerRow - 1)
        }
    }
}
