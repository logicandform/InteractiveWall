//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import PromiseKit
import Reachability


let style = Style()


struct Configuration {
    static let touchPort: UInt16 = 13003
    static let serverIP = "10.58.73.183"
    static let broadcastIP = "10.58.73.255"
    static let serverURL = "http://\(serverIP):3000"
    static let appsPerScreen = 2
    static let numberOfScreens = 1
    static let localMediaURLs = false
    static let launchOnLoad = false
    static let touchScreen = TouchScreen.ur9851
    static let refreshRate = 1.0 / 60.0
    static let resetTimeoutDuration = 180.0
    static let closeWindowTimeoutDuration = 180.0
}


struct Paths {
//    static let mapExplorer = "/Users/irshdc/Library/Developer/Xcode/DerivedData/MapExplorer-cebdevedrroybgdstwjueirgqasq/Build/Products/Debug/MapExplorer-macOS.app"
//    static let mapExplorer = "/Users/juneha/Library/Developer/Xcode/DerivedData/MapExplorer-egvtpmlvcohzalbqgbyfrerzbcdi/Build/Products/Debug/MapExplorer-macOS.app"
    static let mapExplorer = "/Users/Tim/Library/Developer/Xcode/DerivedData/MapExplorer-btnxiobgycwlwddqfdkwxqhmpeum/Build/Products/Debug/MapExplorer-macOS.app"
//    static let nodeNetwork = "/Users/irshdc/Library/Developer/Xcode/DerivedData/MapExplorer-cebdevedrroybgdstwjueirgqasq/Build/Products/Debug/NodeVisualizer.app"
    static let nodeNetwork = "/Users/Tim/Library/Developer/Xcode/DerivedData/MapExplorer-btnxiobgycwlwddqfdkwxqhmpeum/Build/Products/Debug/NodeVisualizer.app"
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var reachability = Reachability()

    private struct ConsoleKeys {
        static let killAllPath = "/usr/bin/killall"
    }


    // MARK: Lifecycle

    func applicationWillFinishLaunching(_ notification: Notification) {
        run(command: ConsoleKeys.killAllPath, args: ApplicationType.mapExplorer.appName)
        run(command: ConsoleKeys.killAllPath, args: ApplicationType.nodeNetwork.appName)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        reachability?.whenReachable = { [weak self] _ in
            self?.prepareApplication()
        }
        try? reachability?.startNotifier()
    }

    func applicationWillTerminate(_ notification: Notification) {
        MasterViewController.instance?.close()
    }


    // MARK: Helpers

    private func prepareApplication() {
        setupApplication()

//        RecordManager.instance.initialize { [weak self] in
//            self?.setupApplication()
//        }
    }

    private func setupApplication() {
//        WindowManager.instance.registerForNotifications()
//        ConnectionManager.instance.registerForNotifications()
//        TouchManager.instance.setupTouchSocket()
//        MenuManager.instance.createMenusAndBorders()
//        GeocodeHelper.instance.associateSchoolsToProvinces()
        MasterViewController.instantiate()
//        IndicatorViewController.instantiate()
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
}
