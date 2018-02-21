//  Copyright © 2018 JABT. All rights reserved.

import Foundation

class LastThreeStructure<RecentElement> {
    var last: RecentElement? {
        willSet {
            intermediate = last
        }
    }
    var intermediate: RecentElement? {
        willSet {
            secondLast = intermediate
        }
    }
    var secondLast: RecentElement?

    func add(_ element: RecentElement) {
        last = element
    }

    func clear() {
        last = nil
        intermediate = nil
        secondLast = nil
    }
}
