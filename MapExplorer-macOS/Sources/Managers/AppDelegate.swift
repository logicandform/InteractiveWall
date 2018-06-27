//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


struct Configuration {
    static let serverIP = "10.58.73.211"
    static let serverURL = "http://\(serverIP):3000"
    static let initialType = ApplicationType.timeline
    static let appsPerScreen = 2
    static let numberOfScreens = 1
    static let touchScreenSize = CGSize(width: 21564, height: 12116)
    static let refreshRate = 1.0 / 60.0
}


var screenID = 0
var appID = 0


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let screenIndex = Int(CommandLine.arguments[1]) ?? 0
        let appIndex = Int(CommandLine.arguments[2]) ?? 0
        screenID = screenIndex
        appID = appIndex + ((screenIndex - 1) * Configuration.appsPerScreen)
        let screen = NSScreen.at(position: screenIndex)
        let controller = Configuration.initialType.controller()
        let screenWidth = screen.frame.width / CGFloat(Configuration.appsPerScreen)
        let frame = NSRect(x: screen.frame.minX + screenWidth * CGFloat(appIndex), y: screen.frame.minY, width: screenWidth, height: screen.frame.height)
        let window = BorderlessWindow(frame: frame, controller: controller)
        window.setFrame(frame, display: true)
        window.makeKeyAndOrderFront(self)

        TouchManager.instance.setupPort()
        ConnectionManager.instance.registerForNotifications()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
