//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class SettingsMenuViewController: NSViewController {
    static let storyboard = NSStoryboard.Name(rawValue: "SettingsMenu")


    override func viewDidLoad() {
        super.viewDidLoad()

        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
    }
}
