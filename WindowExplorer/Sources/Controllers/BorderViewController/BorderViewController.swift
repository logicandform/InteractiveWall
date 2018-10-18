//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class BorderViewController: NSViewController {
    static let storyboard = "Border"


    // MARK: Setup

    override func viewDidLoad() {
        super.viewDidLoad()

        view.wantsLayer = true
        view.isHidden = true
        view.layer?.backgroundColor = style.menuTintColor.cgColor
    }


    // MARK: API

    func set(visible: Bool) {
        view.isHidden = !visible
    }
}
