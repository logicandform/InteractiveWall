//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


struct Configuration {
    static let serverIP = "10.58.73.211"
    static let serverURL = "http://\(serverIP):3000"
    static let appsPerScreen = 2
    static let numberOfScreens = 3
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
        let mapController = MapViewController.instance()
        let timelineController = TimelineViewController.instance()
        let screenWidth = screen.frame.width / CGFloat(Configuration.appsPerScreen)
        let frame = NSRect(x: screen.frame.minX + screenWidth * CGFloat(appIndex), y: screen.frame.minY, width: screenWidth, height: screen.frame.height)
        let mapWindow = BorderlessWindow(frame: frame, controller: mapController, level: style.mapWindowLevel)
        let timelineWindow = BorderlessWindow(frame: frame, controller: timelineController, level: style.timelineWindowLevel)
        mapWindow.setFrame(frame, display: true)
        mapWindow.makeKeyAndOrderFront(self)
        timelineWindow.setFrame(frame, display: true)
        timelineWindow.makeKeyAndOrderFront(self)

        TouchManager.instance.setupPort()
        ConnectionManager.instance.registerForNotifications()
    }
}
