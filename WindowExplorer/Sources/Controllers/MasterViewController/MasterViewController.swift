//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class MasterViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    static var instance: MasterViewController?
    static let storyboard = "Master"

    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var windowDragArea: NSView!
    @IBOutlet weak var windowDragAreaHighlight: NSView!
    @IBOutlet weak var actionSelectionButton: NSPopUpButton!
    @IBOutlet weak var statusTextField: NSTextField!
    @IBOutlet weak var screensTextField: NSTextField!
    @IBOutlet weak var databaseTextField: NSTextField!
    @IBOutlet weak var consoleCollectionView: NSCollectionView!
    @IBOutlet weak var consoleClipView: NSClipView!
    @IBOutlet weak var garbageButton: NSButton!

    private var applicationForID = [Int: NSRunningApplication]()
    private var nodeApplication: NSRunningApplication?
    private var applicationState = ApplicationState.stopped
    private var databaseStatus: DatabaseStatus?
    private var consoleLogs = [ConsoleLog]()
    private weak var refreshTimer: Foundation.Timer?

    private struct Constants {
        static let windowTitle = "Control Center"
        static let refreshTimerInterval = 60.0
    }

    private struct Commands {
        static let restartAll = "restart all"
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
        refreshTimer?.invalidate()
        close(manual: false)
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupActions()
        setupGestures()
        updateConnectedScreenCount()
        requestDatabaseStatus(manual: false)
        registerForNotifications()
        if Configuration.launchOnLoad {
            launch(manual: false)
        }
    }


    // MARK: API

    func close(manual: Bool) {
        if applicationState == .stopped {
            log(type: .failed, action: .close, message: "Application is not running.")
            return
        }

        for (id, app) in applicationForID {
            app.terminate()
            applicationForID.removeValue(forKey: id)
        }

        nodeApplication?.terminate()
        nodeApplication = nil
        set(state: .stopped)

        if manual {
            log(type: .success, action: .close, message: "Application has been stopped.")
        }
    }


    // MARK: Actions

    private func launch(manual: Bool) {
        if applicationState == .running {
            log(type: .failed, action: .launch, message: "Application is already running.")
            return
        }

        let screenCount = NSScreen.screens.count - 1
        if screenCount < Configuration.numberOfScreens {
            log(type: .failed, action: .launch, message: "There must be at least \(Configuration.numberOfScreens) screen(s) connected to launch the application.")
            return
        }

        requestDatabaseStatus(manual: false) { [weak self] in
            self?.handleLaunch(manual: manual)
        }
    }

    private func updateConnectedScreenCount() {
        let screenCount = NSScreen.screens.count - 1
        screensTextField.stringValue = String(screenCount)
        screensTextField.textColor = screenCount >= Configuration.numberOfScreens ? .green : .red
    }

    private func restartServers() {
        let (output, error) = runCommand(cmd: Commands.supervisorctlPath, args: Commands.restartAll)

        if !output.isEmpty {
            log(type: .success, action: .restartServers, message: output)
        }
        if !error.isEmpty {
            log(type: .error, action: .restartServers, message: error)
        }
    }

    private func refreshDatabase() {
        guard let status = databaseStatus else {
            log(type: .error, action: .refreshDatabase, message: "Database status has not yet been received.")
            return
        }

        if status.refreshing {
            log(type: .failed, action: .refreshDatabase, message: "Database is currently refreshing, please wait until the task is finished.")
            return
        }

        DatabaseRefreshHelper.refreshDatabase { [weak self] response in
            self?.handleRefresh(status: response)
        }
    }

    private func requestDatabaseStatus(manual: Bool, completion: (() -> Void)? = nil) {
        DatabaseRefreshHelper.getRefreshStatus { [weak self] status in
            self?.handle(status: status, action: .status, manual: manual)
            completion?()
        }
    }


    // MARK: Setup

    private func setupViews() {
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        titleTextField.attributedStringValue = NSAttributedString(string: "Control Center", attributes: style.windowTitleAttributes)
        windowDragArea.wantsLayer = true
        windowDragArea.layer?.backgroundColor = style.dragAreaBackground.cgColor
        windowDragAreaHighlight.wantsLayer = true
        windowDragAreaHighlight.layer?.backgroundColor = style.menuSelectedColor.cgColor
        consoleCollectionView.register(ConsoleItemView.self, forItemWithIdentifier: ConsoleItemView.identifier)
        consoleCollectionView.layer?.backgroundColor = style.darkBackground.cgColor
        garbageButton.isEnabled = !consoleLogs.isEmpty
        set(state: applicationState)
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
            launch(manual: true)
        case .close:
            close(manual: true)
        case .restartServers:
            restartServers()
        case .refreshDatabase:
            requestDatabaseStatus(manual: false) { [weak self] in
                self?.refreshDatabase()
            }
        case .status:
            requestDatabaseStatus(manual: true)
        }
    }

    @IBAction func presentationCheckboxClicked(_ sender: NSButton) {
        let mode: PresentationMode = sender.state == .on ? .lock : .timeout
        WindowManager.instance.set(mode: mode)
    }

    @IBAction func garbageButtonClicked(_ sender: Any) {
        consoleLogs.removeAll()
        consoleCollectionView.reloadData()
        consoleCollectionView.scroll(.zero)
        garbageButton.isEnabled = !consoleLogs.isEmpty
    }


    // MARK: NSCollectionViewDataSource & NSCollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return consoleLogs.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let consoleItemView = collectionView.makeItem(withIdentifier: ConsoleItemView.identifier, for: indexPath) as? ConsoleItemView else {
            return NSCollectionViewItem()
        }

        consoleItemView.log = consoleLogs[indexPath.item]
        return consoleItemView
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let item = consoleLogs[indexPath.item]
        let height = ConsoleItemView.height(for: item)
        return CGSize(width: consoleClipView.frame.width, height: height)
    }


    // MARK: Helpers

    private func handleLaunch(manual: Bool) {
        // Check database status
        if let status = databaseStatus {
            if status.refreshing {
                log(type: .failed, action: .launch, message: "Cannot launch application until database is finished refreshing.")
                return
            } else if status.error {
                log(type: .failed, action: .launch, message: "Cannot launch application until database is running.")
                return
            }
        }

        RecordManager.instance.initialize { [weak self] in
            self?.startApplication(manual: manual)
        }
    }

    private func startApplication(manual: Bool) {
        // Open Maps
        for screenID in (1 ... Configuration.numberOfScreens) {
            for appIndex in (0 ..< Configuration.appsPerScreen) {
                let appID = (screenID - 1) * Configuration.appsPerScreen + appIndex
                if applicationForID[appID] == nil, let application = open(.mapExplorer, screenID: screenID, appID: appIndex) {
                    applicationForID[appID] = application
                }
            }
        }

        // Open Node
        if nodeApplication == nil {
            nodeApplication = open(.nodeNetwork, screenID: nil, appID: nil)
        }

        set(state: .running)

        if manual {
            log(type: .success, action: .launch, message: "Application has been launched.")
            ConnectionManager.instance.postResetNotification()
        }
    }

    private func handleRefresh(status: DatabaseStatus) {
        handle(status: status, action: .refreshDatabase, manual: true)
        if status.refreshing {
            let message = "If the app is open while refreshing the database, some functionality may be limited. The app cannot be restarted until the database is finished refreshing."
            log(type: .warning, action: .refreshDatabase, message: message)
        }
    }

    /// Updates the current refresh status, if manual; logs output to console
    private func handle(status: DatabaseStatus, action: ControlAction, manual: Bool) {
        databaseTextField.textColor = status.error ? .red : status.refreshing ? .orange : .green
        databaseTextField.stringValue = status.error ? "Error" : status.refreshing ? "Refreshing" : "Running"

        // Log to console if user requested status, or database status has changed
        if manual || (databaseStatus != nil && status != databaseStatus) {
            let type = status.error ? LogType.error : LogType.status
            log(type: type, action: action, message: status.description)
        }

        set(status: status)
    }

    /// Creates and inserts a log onto top of console log stack
    private func log(type: LogType, action: ControlAction, message: String) {
        let log = ConsoleLog(type: type, action: action, message: message)
        consoleLogs.insert(log, at: 0)
        consoleCollectionView.reloadData()
        consoleCollectionView.scroll(.zero)
        garbageButton.isEnabled = !consoleLogs.isEmpty
    }

    private func set(state: ApplicationState) {
        applicationState = state
        statusTextField.stringValue = state.title
        statusTextField.textColor = state.color
    }

    @objc
    private func screensDidChange(_ notification: NSNotification) {
        updateConnectedScreenCount()
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

    private func runCommand(cmd: String, args: String...) -> (output: String, error: String) {
        guard FileManager.default.fileExists(atPath: cmd) else {
            return ("", "Command \(cmd) does not exist")
        }

        let task = Process()
        task.launchPath = cmd
        task.arguments = args
        let outpipe = Pipe()
        task.standardOutput = outpipe
        let errpipe = Pipe()
        task.standardError = errpipe
        task.launch()

        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        let outputString = String(data: outdata, encoding: .utf8) ?? ""
        let output = outputString.trimmingCharacters(in: .whitespacesAndNewlines)

        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        let errorString = String(data: errdata, encoding: .utf8) ?? ""
        let error = errorString.trimmingCharacters(in: .whitespacesAndNewlines)

        task.waitUntilExit()
        return (output, error)
    }

    private func set(status: DatabaseStatus) {
        databaseStatus = status
        if status.error || status.refreshing {
            if refreshTimer == nil {
                startRefreshTimer()
            }
        } else {
            refreshTimer?.invalidate()
        }
    }

    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: Constants.refreshTimerInterval, repeats: true) { [weak self] _ in
            self?.requestDatabaseStatus(manual: false)
        }
    }
}
