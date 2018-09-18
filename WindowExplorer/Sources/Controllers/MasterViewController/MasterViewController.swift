//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class MasterViewController: NSViewController {
    static var instance: MasterViewController?
    static let storyboard = NSStoryboard.Name(rawValue: "Master")

    @IBOutlet weak var actionSelectionButton: NSPopUpButton!
    @IBOutlet weak var consoleOutputTextView: NSTextView!

    // Stores the map / timeline app for its associated id
    private var applicationForID = [Int: NSRunningApplication]()

    // The node application that runs behind all other apps
    private var nodeApplication: NSRunningApplication?

    private struct Constants {
        static let windowTitle = "Control Center"
    }

    private struct Commands {
        static let datePath = "/bin/date"
        static let restartAll = "restart all"
        static let dateArgs = "+%H:%M:%S   %d/%m/%y"
        static let mapExplorerScript = "map-explorer"
        static let supervisorctlPath = "/usr/local/bin/supervisorctl"
    }


    // MARK: Init

    /// Used to lazy load static singleton instance
    static func instantiate() {
        guard MasterViewController.instance == nil else {
            return
        }

        let storyboard = NSStoryboard(name: MasterViewController.storyboard, bundle: .main)
        let controller = storyboard.instantiateInitialController() as! MasterViewController
        let screen = NSScreen.mainScreen
        let window = NSWindow()
        let origin = CGPoint(x: screen.frame.midX - controller.view.frame.width/2, y: screen.frame.midY - controller.view.frame.height/2)
        window.contentViewController = controller
        window.title = Constants.windowTitle
        window.setFrame(CGRect(origin: origin, size: controller.view.frame.size), display: true)
        window.makeKeyAndOrderFront(self)
        MasterViewController.instance = controller
        if Configuration.launchOnLoad {
            controller.launchMaps()
            controller.launchNodeNetwork()
        }
    }

    deinit {
        close()
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupActions()
    }


    // MARK: API

    func launchMaps() {
        for screenID in (1 ... Configuration.numberOfScreens) {
            for appIndex in (0 ..< Configuration.appsPerScreen) {
                let appID = (screenID - 1) * Configuration.appsPerScreen + appIndex

                if applicationForID[appID] == nil, let application = open(.mapExplorer, screenID: screenID, appID: appID) {
                    applicationForID[appID] = application
                }
            }
        }
    }

    func launchNodeNetwork() {
        if nodeApplication == nil {
            nodeApplication = open(.nodeNetwork, screenID: nil, appID: nil)
        }
    }

    func close() {
        for (id, app) in applicationForID {
            app.terminate()
            applicationForID.removeValue(forKey: id)
        }
        nodeApplication?.terminate()
        nodeApplication = nil
    }


    // MARK: Setup

    private func setupActions() {
        actionSelectionButton.removeAllItems()
        ControlAction.menuSelectionActions.forEach { action in
            actionSelectionButton.addItem(withTitle: action.title)
        }
    }


    // MARK: IB-Actions

    @IBAction func applyButtonClicked(_ sender: NSButton) {
        guard let selectedAction = actionSelectionButton.selectedItem, let action = ControlAction(title: selectedAction.title) else {
            return
        }

        switch action {
        case .launchEverything:
            launchMaps()
            launchNodeNetwork()
        case .launchMaps:
            launchMaps()
        case .launchNodeNetwork:
            launchNodeNetwork()
        case .closeApplication:
            close()
        case .restartServers:
            runSupervisorRestart()
        }
    }


    // MARK: Helpers

    private func runSupervisorRestart() {
        var outputString = ""
        let time = runCommand(cmd: Commands.datePath, args: Commands.dateArgs)
        let supervisorResponse = runCommand(cmd: Commands.supervisorctlPath, args: Commands.restartAll)

        time.output.forEach({ currentOutput in
            outputString += currentOutput
            outputString += "\n"
        })
        supervisorResponse.output.forEach({ currentOutput in
            if !currentOutput.contains(Commands.mapExplorerScript) {
                outputString += currentOutput
                outputString += "\n"
            }
        })
        supervisorResponse.error.forEach({ currentOutput in
            outputString += currentOutput
            outputString += "\n"
        })

        consoleOutputTextView.string = outputString.components(separatedBy: NSCharacterSet.newlines).filter({ !$0.isEmpty }).joined(separator: "\n")
    }


    /// Open a known application type with the required parameters
    @discardableResult
    private func open(_ application: ApplicationType, screenID: Int?, appID: Int?) -> NSRunningApplication? {
        var args = [String]()

        if let screen = screenID, let app = appID {
            args.append(String(screen))
            args.append(String(app))
        }

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

    private func runCommand(cmd: String, args: String...) -> (output: [String], error: [String], exitCode: Int32) {
        guard FileManager.default.fileExists(atPath: cmd) else {
            return (["Failed: Command \(cmd) does not exist"], [""], -1)
        }

        var output = [String]()
        var error = [String]()

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
