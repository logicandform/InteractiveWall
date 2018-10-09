//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


extension String {

    var isNumerical: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }

    var digitsInString: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }

    func componentsSeparatedBy(separators: String) -> [String] {
        let separatorSet = CharacterSet(charactersIn: separators)
        return components(separatedBy: separatorSet).filter({ !$0.isEmpty })
    }
}


extension NSAttributedString {

    func height(containerWidth: CGFloat) -> CGFloat {
        let rect = boundingRect(with: CGSize(width: containerWidth, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return ceil(rect.size.height)
    }
}
