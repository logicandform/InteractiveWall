//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import PromiseKit


struct Configuration {
    static let mapsPerScreen = 1
    static let touchScreenSize = CGSize(width: 4095, height: 2242.5)
    static let touchScreenRatio: CGFloat = 23.0 / 42.0
    static let loadMapsOnFirstScreen = true
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        WindowManager.instance.registerForNotifications()
        TouchManager.instance.setupTouchSocket()
        WindowManager.instance.displayWindow(for: .record, at: CGPoint(x: 100, y: 500))
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

