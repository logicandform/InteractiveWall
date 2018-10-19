//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


let style = Style()


struct Configuration {
    static let env = Environment.production
    static let serverIP = "localhost"
    static let serverURL = "http://\(serverIP):3000"
    static let appsPerScreen = 2
    static let numberOfScreens = 1
    static let ungroupTimeoutDuration = 60.0
    static let clusterTimeoutDuration = 60.0
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        prepareApplication()
    }


    // MARK: Helpers

    private func prepareApplication() {
        if Configuration.env == .production {
            RecordManager.instance.initialize { [weak self] in
                self?.setupApplication()
            }
        } else {
            setupApplication()
        }
    }

    private func setupApplication() {
        let controller = MainViewController.instance()
        let startScreen = NSScreen.at(position: 1)
        let endScreen = NSScreen.at(position: Configuration.numberOfScreens)
        let width = endScreen.frame.maxX - startScreen.frame.minX
        let frame = NSRect(x: startScreen.frame.minX, y: startScreen.frame.minY, width: width, height: startScreen.frame.height)
        let window = BorderlessWindow(frame: frame, controller: controller, level: style.nodeWindowLevel)
        window.setFrame(frame, display: true)
        window.makeKeyAndOrderFront(self)

        ConnectionManager.instance.registerForNotifications()
    }
}
