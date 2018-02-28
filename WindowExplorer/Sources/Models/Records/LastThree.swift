//  Copyright © 2018 JABT. All rights reserved.

import Foundation

class LastThree<Element> {

    private(set) var last: Element? {
        willSet {
            intermediate = last
        }
    }

    private(set) var intermediate: Element? {
        willSet {
            secondLast = intermediate
        }
    }

    private(set) var secondLast: Element?


    // MARK: API

    func add(_ element: Element) {
        last = element
    }

    func clear() {
        last = nil
        intermediate = nil
        secondLast = nil
    }
}
