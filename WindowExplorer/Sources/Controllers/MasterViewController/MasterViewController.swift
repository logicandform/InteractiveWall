//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class MasterViewController: NSViewController {
    static var instance: MasterViewController?
    static let storyboard = "Master"

    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var windowDragArea: NSView!
    @IBOutlet weak var windowDragAreaHighlight: NSView!
    @IBOutlet weak var actionSelectionButton: NSPopUpButton!
    @IBOutlet weak var consoleTextView: NSTextView!
    @IBOutlet weak var consoleScrollView: NSScrollView!
    @IBOutlet weak var statusTextField: NSTextField!
    @IBOutlet weak var screensTextField: NSTextField!

    private var applicationForID = [Int: NSRunningApplication]()
    private var nodeApplication: NSRunningApplication?

    private struct Constants {
        static let windowTitle = "Control Center"
        static let consoleOutputFont = NSFont(name: "Menlo", size: 15)
        static let consoleOutputFontColor = style.selectedColor
    }

    private struct Commands {
        static let datePath = "/bin/date"
        static let restartAll = "restart all"
        static let dateArgs = "+%H:%M:%S   %d/%m/%y"
        static let mapExplorerScript = "map-explorer"
        static let supervisorctlPath = "/usr/local/bin/supervisorctl"
    }


    // MARK: Init

    static func instantiate() {
        if MasterViewController.instance == nil {
            let screen = NSScreen.mainScreen
            let origin = CGPoint(x: screen.frame.midX - style.masterWindowSize.width/2, y: screen.frame.midY - style.masterWindowSize.height/2)
            MasterViewController.instance = WindowManager.instance.display(.master, at: origin) as? MasterViewController
        }
    }

    deinit {
        close()
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupActions()
        setupGestures()
        updateConnectedScreens()
        registerForNotifications()
        if Configuration.launchOnLoad {
            launch()
        }
    }


    // MARK: API

    func close() {
        for (id, app) in applicationForID {
            app.terminate()
            applicationForID.removeValue(forKey: id)
        }
        nodeApplication?.terminate()
        nodeApplication = nil
    }


    // MARK: Setup

    private func launch() {
        // Open maps
        for screenID in (1 ... Configuration.numberOfScreens) {
            for appIndex in (0 ..< Configuration.appsPerScreen) {
                let appID = (screenID - 1) * Configuration.appsPerScreen + appIndex

                if applicationForID[appID] == nil, let application = open(.mapExplorer, screenID: screenID, appID: appIndex) {
                    applicationForID[appID] = application
                }
            }
        }
        // Open node network
        if nodeApplication == nil {
            nodeApplication = open(.nodeNetwork, screenID: nil, appID: nil)
        }
    }

    private func setupView() {
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        titleTextField.attributedStringValue = NSAttributedString(string: "Control Center", attributes: style.windowTitleAttributes)
        windowDragAreaHighlight.wantsLayer = true
        windowDragAreaHighlight.layer?.backgroundColor = style.selectedColor.cgColor
        consoleTextView.font = Constants.consoleOutputFont
        consoleTextView.textColor = Constants.consoleOutputFontColor
        let state = Configuration.launchOnLoad ? ApplicationState.running : ApplicationState.stopped
        set(state: state)
    }

    private func setupGestures() {
        let mousePan = NSPanGestureRecognizer(target: self, action: #selector(handleMousePan(_:)))
        windowDragArea.addGestureRecognizer(mousePan)
    }

    private func setupActions() {
        actionSelectionButton.removeAllItems()
        ControlAction.menuSelectionActions.forEach { action in
            actionSelectionButton.addItem(withTitle: action.title)
        }
    }

    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(screensDidChange(_:)), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }


    // MARK: Gesture Handling

    @objc
    private func handleMousePan(_ gesture: NSPanGestureRecognizer) {
        guard let window = view.window, let screen = window.screen else {
            return
        }

        // Constrain to the main screens bounds
        var origin = window.frame.origin
        origin += gesture.translation(in: nil)
        origin.x = clamp(origin.x, min: 0, max: screen.frame.maxX - view.frame.width)
        origin.y = clamp(origin.y, min: 0, max: screen.frame.maxY - view.frame.height)
        window.setFrameOrigin(origin)
    }


    // MARK: IB-Actions

    @IBAction func applyButtonClicked(_ sender: NSButton) {
        guard let selectedAction = actionSelectionButton.selectedItem, let action = ControlAction(title: selectedAction.title) else {
            return
        }

        switch action {
        case .launch:
            launch()
        case .close:
            close()
        case .restartServers:
            runSupervisorRestart()
        }
    }


    // MARK: Helpers

    private func set(state: ApplicationState) {
        statusTextField.stringValue = state.title
        statusTextField.textColor = state.color
    }

    private func updateConnectedScreens() {
        let screenCount = NSScreen.screens.count - 1
        screensTextField.stringValue = String(screenCount)
        screensTextField.textColor = screenCount >= Configuration.numberOfScreens ? .green : .red
    }

    @objc
    private func screensDidChange(_ notification: NSNotification) {
        updateConnectedScreens()
    }

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

        consoleTextView.string = outputString.components(separatedBy: NSCharacterSet.newlines).filter({ !$0.isEmpty }).joined(separator: "\n")
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
