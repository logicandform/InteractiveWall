//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import PromiseKit
import Reachability


let style = Style()


struct Configuration {
    static let touchPort: UInt16 = 13000
    static let serverIP = "localhost"
    static let serverURL = "http://\(serverIP):3000"
    static let appsPerScreen = 2
    static let numberOfScreens = 2
    static let localMediaURLs = true
    static let launchOnLoad = true
    static let touchScreen = TouchScreen.ur9851
    static let resetTimeoutDuration = 150.0
    static let closeWindowTimeoutDuration = 180.0
    static let menuResetTimeoutDuration = 180.0
    static let shutdownHour = 20
}


struct Paths {
    static let mapExplorer = "/Users/irshdc/Library/Developer/Xcode/DerivedData/InteractiveWall-atywugxlwkeqhpauwgaflngywsjq/Build/Products/Debug/MapExplorer.app"
//    static let mapExplorer = "/Users/Tim/Library/Developer/Xcode/DerivedData/InteractiveWall-adiypssigffcldcmakgbwofhzjwu/Build/Products/Debug/MapExplorer.app"
    static let nodeNetwork = "/Users/irshdc/Library/Developer/Xcode/DerivedData/InteractiveWall-atywugxlwkeqhpauwgaflngywsjq/Build/Products/Debug/NodeExplorer.app"
//    static let nodeNetwork = "/Users/Tim/Library/Developer/Xcode/DerivedData/InteractiveWall-adiypssigffcldcmakgbwofhzjwu/Build/Products/Debug/NodeExplorer.app"
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var reachability = Reachability()


    // MARK: Lifecycle

    func applicationWillFinishLaunching(_ notification: Notification) {
        terminateRunningApplications()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        reachability?.whenReachable = { [weak self] _ in
            self?.setupApplication()
        }
        try? reachability?.startNotifier()
    }

    func applicationWillTerminate(_ notification: Notification) {
        MasterViewController.instance?.close(manual: false)
    }


    // MARK: Helpers

    private func setupApplication() {
        WindowManager.instance.registerForNotifications()
        ConnectionManager.instance.registerForNotifications()
        TouchManager.instance.setupTouchSocket()
        MenuManager.instance.createMenusAndBorders()
        MasterViewController.instantiate()
        IndicatorViewController.instantiate()
        scheduleShutdown()
        reachability?.stopNotifier()
        reachability = nil
    }

    /// Terminates all other instances of this application and any instances of MapExplorer or NodeExplorer
    private func terminateRunningApplications() {
        let runningApps = NSWorkspace.shared.runningApplications
        let appsToKill = [ApplicationType.mapExplorer.appName, ApplicationType.nodeNetwork.appName]

        for app in runningApps {
            if app.localizedName == NSRunningApplication.current.localizedName, app != NSRunningApplication.current {
                app.terminate()
            } else if let name = app.localizedName, appsToKill.contains(name) {
                app.terminate()
            }
        }
    }

    /// Schedules the shutdown of the app at a certain hour of the current day
    private func scheduleShutdown() {
        let now = Date()
        if let date = Calendar.current.date(bySettingHour: Configuration.shutdownHour, minute: 0, second: 0, of: now) {
            if date > now {
                let timer = Timer(fireAt: date, interval: 0, target: self, selector: #selector(shutdown), userInfo: nil, repeats: false)
                RunLoop.main.add(timer, forMode: .common)
            }
        }
    }

    @objc
    private func shutdown() {
        MasterViewController.instance?.close(manual: false)
        exit(0)
    }
}
