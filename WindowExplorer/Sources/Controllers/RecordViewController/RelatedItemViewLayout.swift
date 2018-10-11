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

    var itemSpacing: CGFloat {
        return 5
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
            return CGSize(width: 300, height: 80)
        case .images:
            return CGSize(width: 180, height: 180)
        case .videos:
            let width = RelatedItemViewLayout.list.itemSize.width
            let aspectRatio: CGFloat = 9 / 16
            return CGSize(width: width, height: width * aspectRatio)
        }
    }

    var rowWidth: CGFloat {
        switch self {
        case .list:
            return itemSize.width * itemsPerRow + itemSpacing * (itemsPerRow - 1)
        case .images:
            return itemSize.width * itemsPerRow + itemSpacing * (itemsPerRow - 1)
        case .videos:
            return itemSize.width * itemsPerRow + itemSpacing * (itemsPerRow - 1)
        }
    }
}
