//  Copyright © 2018 slant. All rights reserved.

import Foundation


extension Int {

    var isZero: Bool {
        return self == 0 ? true : false
    }

    var array: [Int] {
        return String(self).compactMap { Int(String($0)) }
    }
}
