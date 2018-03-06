//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class TestViewController: NSViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "Test")

    var gestureManager: GestureManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.red.cgColor
        gestureManager = GestureManager(responder: self)
    }
    
    @IBAction func buttonClicked(_ sender: Any) {
        WindowManager.instance.closeWindow(for: gestureManager)
    }
}
