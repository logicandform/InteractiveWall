//  Copyright © 2018 JABT. All rights reserved.

import Foundation

extension Collection {

    /// Returns the element at the specified index location if its within its bounds, else nil.
    func at(index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
