//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


extension NSColor {

    static func random() -> NSColor {
        return NSColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
    }

    static func color(from seed: String) -> NSColor {
        let total = seed.unicodeScalars.reduce(0) { $0 + Int(UInt32($1)) }

        srand48(total * 200)
        let r = CGFloat(drand48())

        srand48(total)
        let g = CGFloat(drand48())

        srand48(total / 200)
        let b = CGFloat(drand48())

        return NSColor(red: r, green: g, blue: b, alpha: 1)
    }
}
