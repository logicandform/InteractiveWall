//  Copyright © 2018 JABT. All rights reserved.

import Foundation

class LastThreeStructure<Element> {
    var last: Element? {
        willSet {
            intermediate = last
        }
    }
    var intermediate: Element? {
        willSet {
            secondLast = intermediate
        }
    }
    var secondLast: Element?

    func add(_ element: Element) {
        last = element
    }

    func clear() {
        last = nil
        intermediate = nil
        secondLast = nil
    }
}
