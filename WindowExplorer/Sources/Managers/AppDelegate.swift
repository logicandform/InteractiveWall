//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import PromiseKit

let style = Style()


struct Configuration {
    static let mapsPerScreen = 4
    static let numberOfScreens = 1
    static let touchScreenSize = CGSize(width: 4095, height: 2242.5)
    static let touchScreenRatio: CGFloat = 23.0 / 42.0
    static let loadMapsOnFirstScreen = false
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        WindowManager.instance.registerForNotifications()
        TouchManager.instance.setupTouchSocket()
        launchMapExplorer()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

private func launchMapExplorer() {
    let firstScreen = loadMapsOnFirstScreen ? 0 : 1

    for screen in firstScreen ... numberOfScreen {
        for map in 0 ..< mapPerScreen {
            shell(screen, map)
        }
    }
}

private func shell(_ screen: Int, _ map: Int) {
    let task = Process()
    task.launchPath = "/usr/bin/open"
    task.arguments = ["-n", "-a", "/Users/spencerperkins/Library/Developer/Xcode/DerivedData/MapExplorer-dttmkubbxpmqnkgcnmtskfqjhfbq/Build/Products/Debug/MapExplorer-macOS.app", "--args", screen, map]
    task.launch()
    task.waitUntilExit()
}


