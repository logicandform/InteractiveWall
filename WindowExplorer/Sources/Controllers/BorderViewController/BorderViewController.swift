//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class BorderViewController: NSViewController {
    static let storyboard = "Border"

    @IBOutlet weak var border: BorderControl!


    // MARK: API

    func set(visible: Bool) {
        border.isVisible = visible
    }
}
