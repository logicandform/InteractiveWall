//  Copyright © 2018 JABT. All rights reserved.

import Foundation

class LastTwo<Element>: CustomStringConvertible {

    private(set) var last: Element? {
        willSet {
            secondLast = last
        }
    }

    private(set) var secondLast: Element?

    var description: String {
        return "( [LastTwo] last: \(String(describing: last)), secondLast: \(String(describing: secondLast)) )"
    }

    // MARK: API

    func add(_ element: Element) {
        last = element
    }

    func clear() {
        last = nil
        secondLast = nil
    }
}
