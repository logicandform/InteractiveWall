//  Copyright © 2018 JABT. All rights reserved.

import Foundation

extension String {
    
    func removeHtml() -> String {
        guard let arrowLeft = self.index(of: "<"), let arrowRight = self.index(of: ">") else {
            return self
        }
        
        var copy = self
        let range = arrowLeft...arrowRight
        copy.removeSubrange(range)
        return copy.removeHtml()
    }
}
