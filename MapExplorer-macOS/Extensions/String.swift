//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


extension String {
    func componentsSeparatedBy(separators: String) -> [String] {
//        return separators.reduce([self]) { result, separator in
//            return result.compactMap { $0.componentsSeparatedByString(separator) }
//        }.map { $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) }

//        let results = self.reduce([self]) { result, next in
//            self.compactMap { $0.componentsSeparatedByString(next) }
//        }

//        let results = separators.reduce([self], { result, next in
//            result.components(separatedBy: next)
//        })

        let separatorSet = CharacterSet(charactersIn: separators)
        let result = self.components(separatedBy: separatorSet).filter({ !$0.isEmpty })
        return result
    }
}
