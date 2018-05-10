//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import PromiseKit


let style = Style()


struct Configuration {
    static let mapsPerScreen = 2
    static let numberOfScreens = 1
    static let touchScreenSize = CGSize(width: 21564, height: 12116)
    static let refreshRate = 1.0 / 60.0
    static let loadMapsOnFirstScreen = false
}


struct Paths {
    static let mapExplorer = "/Users/Tim/Library/Developer/Xcode/DerivedData/MapExplorer-btnxiobgycwlwddqfdkwxqhmpeum/Build/Products/Debug/MapExplorer-macOS.app"
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        WindowManager.instance.registerForNotifications()
        TouchManager.instance.setupTouchSocket()
        MasterViewController.instantiate()
        MenuViewController.instantiate()
    }

    func applicationWillTerminate(_ notification: Notification) {
        MasterViewController.instance?.close()
    }
}
