//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


extension String {
    func componentsSeparatedByStrings(separators: [String]) -> [String] {
//        return separators.reduce([self]) { result, separator in
//            return result.compactMap { $0.componentsSeparatedByString(separator) }
//        }.map { $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) }
        let results = separators.reduce([self]) { initialResult, nextPartialResult in
            initialResult.compo

        }
    }
}
