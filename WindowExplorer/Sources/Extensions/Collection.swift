//  Copyright © 2018 JABT. All rights reserved.

import Foundation

extension Collection {

    /// Returns the element at the specified index location if its within its bounds, else nil.
    func at(index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

func zip<S1: Sequence, S2: Sequence, S3: Sequence, S4: Sequence>(seq1: S1, seq2: S2, seq3: S3, seq4: S4) -> [(S1.Iterator.Element, S2.Iterator.Element, S3.Iterator.Element, S4.Iterator.Element)] {
    return zip(zip(seq1, seq2), zip(seq3, seq4)).map({ ($0.0, $0.1, $1.0, $1.1) })
}

extension IndexPath {

    static var zero: IndexPath {
        return IndexPath(item: 0, section: 0)
    }
}
