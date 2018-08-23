//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


struct ApplicationInfo {
    var action: ControlAction
    var status: ScreenState
    var applications: [Int: NSRunningApplication]
    var applicationTypesForMaps: [Int: ApplicationType]
    var maps: [Int]
}


class MasterViewController: NSViewController {
    static var instance: MasterViewController?

    @IBOutlet weak var leftScreen: NSView!
    @IBOutlet weak var middleScreen: NSView!
    @IBOutlet weak var rightScreen: NSView!
    @IBOutlet weak var actionSelectionButton: NSPopUpButton!
    @IBOutlet weak var consoleOutputTextView: NSTextView!

    var infoForScreen = [Int: ApplicationInfo]()

    private var screens: [NSView] {
        return [leftScreen, middleScreen, rightScreen]
    }

    private struct Constants {
        static let storyboard = NSStoryboard.Name(rawValue: "Master")
        static let windowTitle = "Control Center"
        static let screenBorderWidth: CGFloat = 12
        static let imageTransitionDuration = 2.0
        static let screenBackgroundColor = CGColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)
        static let mapExplorerScriptName = "map-explorer"
    }


    // MARK: Init

    /// Used to lazy load static singleton instance
    static func instantiate() {
        guard MasterViewController.instance == nil else {
            return
        }

        let storyboard = NSStoryboard(name: Constants.storyboard, bundle: .main)
        let controller = storyboard.instantiateInitialController() as! MasterViewController
        let screen = NSScreen.mainScreen
        let window = NSWindow()
        let origin = CGPoint(x: screen.frame.midX - controller.view.frame.width/2, y: screen.frame.midY - controller.view.frame.height/2)
        window.contentViewController = controller
        window.title = Constants.windowTitle
        window.setFrame(CGRect(origin: origin, size: controller.view.frame.size), display: true)
        window.makeKeyAndOrderFront(self)
        MasterViewController.instance = controller
    }

    deinit {
        close()
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupScreens()
        setupConsoleOutputView()
        setupActionButton()
        registerForNotifications()
    }


    // MARK: API

    /// Terminates all currently running applications
    func close() {
        screens.enumerated().forEach { screen, _ in
            terminate(screen: screen)
        }
    }

    func apply(_ action: ControlAction, status: ScreenState, toScreen screen: Int, on map: Int? = nil) {
        // Ignore action if it's current
        if let currentInfo = infoForScreen[screen], currentInfo.action == action && map == nil && status == currentInfo.status {
            return
        }

        // Load new processes
        if status == .connected {
            switch action {
            case .launchApplication:
                guard let currentInfo = infoForScreen[screen] else {
                    return
                }

                launchMaps(info: currentInfo, action: action, status: status, screen: screen, map: map)
            case .closeApplication:
                terminate(screen: screen, map: map)
                infoForScreen[screen] = ApplicationInfo(action: action, status: status, applications: [:], applicationTypesForMaps: [:], maps: [])
            default:
                break
            }
        } else {
            terminate(screen: screen, map: map)
            infoForScreen[screen] = ApplicationInfo(action: action, status: status, applications: [:], applicationTypesForMaps: [:], maps: [])
        }

        transition(screen: screen, to: status)
    }


    // MARK: Setup

    private func setupScreens() {
        screens.enumerated().forEach { screen, screenView in
            screenView.layer?.backgroundColor = Constants.screenBackgroundColor
            screenView.layer?.borderWidth = Constants.screenBorderWidth
            screenView.layer?.borderColor = CGColor.black

            if Configuration.spawnMapsImmediately {
                let action = connected(screen: screen) ? ControlAction.launchApplication : ControlAction.closeApplication
                let state = connected(screen: screen) ? ScreenState.connected : ScreenState.disconnected
                infoForScreen[screen] = ApplicationInfo(action: ControlAction.closeApplication, status: state, applications: [:], applicationTypesForMaps: [:], maps: [])
                apply(action, status: state, toScreen: screen)
            } else {
                let action = ControlAction.closeApplication
                let state = connected(screen: screen) ? ScreenState.connected : ScreenState.disconnected
                apply(action, status: state, toScreen: screen)
            }
        }
    }

    private func setupConsoleOutputView() {
        consoleOutputTextView.backgroundColor = NSColor.black
        consoleOutputTextView.textColor = NSColor.white
        consoleOutputTextView.isEditable = false
//        consoleOutputTextView.string = "test again"
    }

    private func setupActionButton() {
        actionSelectionButton.removeAllItems()
        ControlAction.menuSelectionActions.forEach { action in
            actionSelectionButton.addItem(withTitle: action.title)
        }
    }

    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(screensDidChange(_:)), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }


    // MARK: IB-Actions

    @IBAction func applyButtonClicked(_ sender: NSButton) {
        guard let selectedAction = actionSelectionButton.selectedItem, let action = ControlAction(title: selectedAction.title) else {
            return
        }

        infoForScreen.enumerated().forEach { _, info in
            if info.value.status != ScreenState.disconnected {
                apply(action, status: info.value.status, toScreen: info.key)
            }
        }
    }

    @IBAction func scriptRestartButtonClicked(_ sender: NSButton) {
        sender.isEnabled = false
        consoleOutputTextView.string = ""
        let time = runCommand(cmd: "/bin/date", args: "+%H:%M:%S   %d/%m/%y")
        let supervisorResponse = runCommand(cmd: "/usr/local/bin/supervisorctl", args: "restart all")

        time.output.forEach({ currentOutput in
            consoleOutputTextView.string += currentOutput
            consoleOutputTextView.string += "\n"
        })
        supervisorResponse.output.forEach({ currentOutput in
            if !currentOutput.contains(Constants.mapExplorerScriptName) {
                consoleOutputTextView.string += currentOutput
                consoleOutputTextView.string += "\n"
            }
        })
        supervisorResponse.error.forEach({ currentOutput in
            consoleOutputTextView.string += currentOutput
            consoleOutputTextView.string += "\n"
        })
        sender.isEnabled = true
    }


    // MARK: Helpers

    /// Terminate the processes associated with the given screen
    private func terminate(screen: Int, map: Int? = nil) {
        guard let info = infoForScreen[screen] else {
            return
        }

        if let map = map, info.maps.contains(map) {
            info.applications[map]?.terminate()
            infoForScreen[screen]?.maps = info.maps.filter { $0 != map }
            infoForScreen[screen]?.applications = info.applications.filter { $0.key != map }
            infoForScreen[screen]?.applicationTypesForMaps = info.applicationTypesForMaps.filter { $0.key != map }
            infoForScreen[screen]?.action = .launchApplication
        } else if map == nil {
            info.applications.forEach { application in
                application.value.terminate()
            }
        }
    }

    /// Launch MapExplorer on the given screen
    private func launchMaps(info: ApplicationInfo, action: ControlAction, status: ScreenState, screen: Int, map: Int? = nil) {
        var applications = info.applications
        var applicationTypes = info.applicationTypesForMaps
        var maps = info.maps

        if let map = map, !maps.contains(map), let application = open(.mapExplorer, screenID: screen + 1, appID: map) {
            applications[map] = application
            applicationTypes[map] = .mapExplorer
            maps.append(map)
        } else {
            for map in 0 ..< Configuration.appsPerScreen {
                if !maps.contains(map), let application = open(.mapExplorer, screenID: screen + 1, appID: map) {
                    applications[map] = application
                    applicationTypes[map] = .mapExplorer
                    maps.append(map)
                }
            }
        }

        infoForScreen[screen] = ApplicationInfo(action: action, status: status, applications: applications, applicationTypesForMaps: applicationTypes, maps: maps)
    }

    /// Open a known application type with the required parameters
    @discardableResult
    private func open(_ application: ApplicationType, screenID: Int, appID: Int) -> NSRunningApplication? {
        let args = [String(screenID), String(appID)]

        do {
            let url = URL(fileURLWithPath: application.path)
            let config = [NSWorkspace.LaunchConfigurationKey.arguments: args]
            let application = try NSWorkspace.shared.launchApplication(at: url, options: .newInstance, configuration: config)
            return application
        } catch {
            print("Failed to open application at path: \(application.path).")
            return nil
        }
    }

    private func transition(screen: Int, to status: ScreenState) {
        if let screenView = screens.at(index: screen), let image = status.image {
            screenView.transition(to: image, duration: Constants.imageTransitionDuration)
        }
    }

    /// Returns true of the given screen is currently connected
    private func connected(screen: Int) -> Bool {
        return NSScreen.screens.count > screen + 1
    }

    @objc
    private func screensDidChange(_ notification: NSNotification) {
        infoForScreen.forEach { screen, info in
            if connected(screen: screen) && info.status == .disconnected {
                apply(.closeApplication, status: .connected, toScreen: screen)
            } else if !connected(screen: screen) {
                apply(.closeApplication, status: .disconnected, toScreen: screen)
            }
        }
    }

    private func runCommand(cmd: String, args: String...) -> (output: [String], error: [String], exitCode: Int32) {
        var output: [String] = []
        var error: [String] = []

        let task = Process()
        task.launchPath = cmd
        task.arguments = args

        let outpipe = Pipe()
        task.standardOutput = outpipe
        let errpipe = Pipe()
        task.standardError = errpipe

        task.launch()

        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            output = string.components(separatedBy: "\n")
        }

        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: errdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            error = string.components(separatedBy: "\n")
        }

        task.waitUntilExit()
        let status = task.terminationStatus

        return (output, error, status)
    }
}
