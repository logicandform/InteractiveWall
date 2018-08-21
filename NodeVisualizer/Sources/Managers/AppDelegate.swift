//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


let style = Style()


enum Environment {
    case testing
    case production
}


struct Configuration {
    static let env = Environment.testing
    static let appsPerScreen = 2
    static let numberOfScreens = 1
    static let touchScreenSize = CGSize(width: 21564, height: 12116)
    static let refreshRate = 1.0 / 60.0
    static let loadMapsOnFirstScreen = false
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let screen = NSScreen.at(position: 1)
        let controller = MainViewController.instance()
        let frame = NSRect(x: screen.frame.minX, y: screen.frame.minY, width: screen.frame.width, height: screen.frame.height)
        let window = NSWindow(contentViewController: controller)
        window.setFrame(frame, display: true)
        window.makeKeyAndOrderFront(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
