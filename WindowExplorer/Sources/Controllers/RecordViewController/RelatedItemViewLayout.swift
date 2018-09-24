//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum RelatedItemViewLayout {
    case list
    case images
    case videos

    var itemsPerRow: CGFloat {
        switch self {
        case .list, .videos:
            return 1
        case .images:
            return 3
        }
    }

    var identifier: NSUserInterfaceItemIdentifier {
        switch self {
        case .list:
            return RelatedItemListView.identifier
        case .images, .videos:
            return RelatedItemImageView.identifier
        }
    }

    var itemSize: CGSize {
        switch self {
        case .list:
            return CGSize(width: style.relatedRecordsListItemWidth, height: style.relatedRecordsListItemHeight)
        case .images:
            return CGSize(width: style.relatedRecordsImageItemWidth, height: style.relatedRecordsImageItemHeight)
        case .videos:
            let width = style.relatedRecordsListItemWidth
            let aspectRatio: CGFloat = 9 / 16
            return CGSize(width: width, height: width * aspectRatio)
        }
    }

    var rowWidth: CGFloat {
        switch self {
        case .list:
            return style.relatedRecordsListItemWidth * itemsPerRow + style.relatedRecordsItemSpacing * (itemsPerRow - 1)
        case .images:
            return style.relatedRecordsImageItemWidth * itemsPerRow + style.relatedRecordsItemSpacing * (itemsPerRow - 1)
        case .videos:
            return style.relatedRecordsListItemWidth * itemsPerRow + style.relatedRecordsItemSpacing * (itemsPerRow - 1)
        }
    }
}
