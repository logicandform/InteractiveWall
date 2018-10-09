//  Copyright © 2018 JABT. All rights reserved.

import Foundation

extension Collection {

    /// Returns the element at the specified index location if its within its bounds, else nil.
    func at(index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension IndexPath {

    static var zero: IndexPath {
        return IndexPath(item: 0, section: 0)
    }
}
