//  Copyright © 2018 JABT. All rights reserved.

import Foundation


extension Int {

    var isZero: Bool {
        return self == 0 ? true : false
    }

    var isEven: Bool {
        return self % 2 == 0
    }
}


public func clamp<T: Comparable>(_ val: T, min: T, max: T) -> T {
    assert(min < max, "min has to be less than max")
    if val < min { return min }
    if val > max { return max }
    return val
}
