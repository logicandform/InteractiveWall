//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


extension String {
    func componentsSeparatedBy(separators: String) -> [String] {
        let separatorSet = CharacterSet(charactersIn: separators)
        let result = self.components(separatedBy: separatorSet).filter({ !$0.isEmpty })
        return result
    }
}
