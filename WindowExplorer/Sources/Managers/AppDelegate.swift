//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import PromiseKit


let style = Style()


struct Configuration {
    static let mapsPerScreen = 2
    static let numberOfScreens = 3
    static let touchScreenSize = CGSize(width: 21564, height: 12116)
    static let refreshRate: Double = 1 / 60
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
    }

    func applicationWillTerminate(_ notification: Notification) {
        MasterViewController.instance?.close()
    }
}
