//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


let style = Style()


struct Configuration {
    static let serverIP = "localhost"
    static let serverURL = "http://\(serverIP):3000"
    static let appsPerScreen = 2
    static let numberOfScreens = 1
    static let localMediaURLs = true
    static let touchScreen = TouchScreen.ur9851
    static let ungroupTimoutDuration = 90.0
//    static let mbtilesPath = "/Users/irshdc/dev/CanadaShoreIceRoad.mbtiles"
    static let mbtilesPath = "/Users/Tim/Xcode/UBC/CanadaShoreIceRoad.mbtiles"
}


var screenID = 0
var appID = 0


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        RecordManager.instance.initialize { [weak self] in
            self?.setupApplication()
        }
    }


    // MARK: Helpers

    private func setupApplication() {
        let screenIndex = Int(CommandLine.arguments[1]) ?? 0
        let appIndex = Int(CommandLine.arguments[2]) ?? 0
        screenID = screenIndex
        appID = appIndex + ((screenIndex - 1) * Configuration.appsPerScreen)
        let screen = NSScreen.at(position: screenIndex)
        let appWidth = screen.frame.width / CGFloat(Configuration.appsPerScreen)
        let frame = NSRect(x: screen.frame.minX + appWidth * CGFloat(appIndex), y: screen.frame.minY, width: appWidth, height: screen.frame.height)

        // Setup Map Window
        let mapController = MapViewController.instance()
        let mapWindow = BorderlessWindow(frame: frame, controller: mapController, level: style.mapWindowLevel)
        mapWindow.setFrame(frame, display: true)
        mapWindow.makeKeyAndOrderFront(self)

        // Setup Timeline Window
        let timelineController = TimelineViewController.instance()
        let timelineWindow = BorderlessWindow(frame: frame, controller: timelineController, level: style.timelineWindowLevel)
        timelineWindow.setFrame(frame, display: true)
        timelineWindow.makeKeyAndOrderFront(self)

        // Setup Managers
        TouchManager.instance.setupPort()
        ConnectionManager.instance.registerForNotifications()
        SelectionManager.instance.registerForNotifications()
    }
}
