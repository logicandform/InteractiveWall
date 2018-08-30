//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


extension NSAttributedString {

    func height(containerWidth: CGFloat) -> CGFloat {
        let rect = boundingRect(with: CGSize(width: containerWidth, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return ceil(rect.size.height)
    }
}
