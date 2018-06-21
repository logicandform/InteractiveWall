//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class BorderViewController: NSViewController {
    static let storyboard = NSStoryboard.Name(rawValue: "Border")

    @IBOutlet weak var border: BorderControl!

    var screenID: Int?


    // MARK: API

    func isVisible(_ visible: Bool) {
        border.isVisible = visible
    }
}
