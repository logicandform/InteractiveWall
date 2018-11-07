//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import PromiseKit
import Reachability


let style = Style()


struct Configuration {
    static let touchPort: UInt16 = 13001
    static let serverIP = "localhost"
    static let serverURL = "http://\(serverIP):3000"
    static let appsPerScreen = 2
    static let numberOfScreens = 1
    static let localMediaURLs = true
    static let launchOnLoad = true
    static let touchScreen = TouchScreen.pct2485
    static let resetTimeoutDuration = 150.0
    static let closeWindowTimeoutDuration = 180.0
    static let menuResetTimeoutDuration = 180.0
    static let shutdownHour = 20
}


struct Paths {
//    static let mapExplorer = "/Users/irshdc/Library/Developer/Xcode/DerivedData/InteractiveWall-atywugxlwkeqhpauwgaflngywsjq/Build/Products/Debug/MapExplorer.app"
    static let mapExplorer = "/Users/Tim/Library/Developer/Xcode/DerivedData/InteractiveWall-adiypssigffcldcmakgbwofhzjwu/Build/Products/Debug/MapExplorer.app"
//    static let nodeNetwork = "/Users/irshdc/Library/Developer/Xcode/DerivedData/InteractiveWall-atywugxlwkeqhpauwgaflngywsjq/Build/Products/Debug/NodeExplorer.app"
    static let nodeNetwork = "/Users/Tim/Library/Developer/Xcode/DerivedData/InteractiveWall-adiypssigffcldcmakgbwofhzjwu/Build/Products/Debug/NodeExplorer.app"
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var reachability = Reachability()

    private struct Constants {
        static let killAllPath = "/usr/bin/killall"
    }


    // MARK: Lifecycle

    func applicationWillFinishLaunching(_ notification: Notification) {
        terminateOtherInstances()
        run(command: Constants.killAllPath, args: ApplicationType.mapExplorer.appName)
        run(command: Constants.killAllPath, args: ApplicationType.nodeNetwork.appName)
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

    // Terminates all other instances of this application
    private func terminateOtherInstances() {
        let runningApps = NSWorkspace.shared.runningApplications

        for app in runningApps {
            if app.localizedName == NSRunningApplication.current.localizedName, app != NSRunningApplication.current {
                app.terminate()
            }
        }
    }

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

    private func run(command: String, args: String...) {
        guard FileManager.default.fileExists(atPath: command) else {
            print("Failed: Command \(command) does not exist")
            return
        }

        let task = Process()
        task.launchPath = command
        task.arguments = args
        let outpipe = Pipe()
        task.standardOutput = outpipe
        let errpipe = Pipe()
        task.standardError = errpipe

        task.launch()
        task.waitUntilExit()
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
