//  Copyright © 2018 JABT. All rights reserved.

import Foundation

class LastTwo<Element> {

    private(set) var last: Element? {
        willSet {
            secondLast = last
        }
    }

    private(set) var secondLast: Element?


    // MARK: API

    func add(_ element: Element) {
        last = element
    }

    func clear() {
        last = nil
        secondLast = nil
    }
}
