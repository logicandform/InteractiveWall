//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


private struct ApplicationInfo {
    let action: ControlAction
    let applications: [NSRunningApplication]
}


class MasterViewController: NSViewController {
    static var instance: MasterViewController?

    @IBOutlet weak var leftScreen: NSView!
    @IBOutlet weak var middleScreen: NSView!
    @IBOutlet weak var rightScreen: NSView!
    @IBOutlet weak var leftScreenCheckbox: NSButton!
    @IBOutlet weak var middleScreenCheckbox: NSButton!
    @IBOutlet weak var rightScreenCheckbox: NSButton!
    @IBOutlet weak var actionSelectionButton: NSPopUpButton!

    private var infoForScreen = [Int: ApplicationInfo]()

    private var screens: [NSView] {
        return [leftScreen, middleScreen, rightScreen]
    }

    private var checkboxes: [NSButton] {
        return [leftScreenCheckbox, middleScreenCheckbox, rightScreenCheckbox]
    }

    private struct Constants {
        static let storyboard = NSStoryboard.Name(rawValue: "Master")
        static let windowTitle = "Control Center"
        static let screenBorderWidth: CGFloat = 12
        static let imageTransitionDuration = 2.0
        static let screenBackgroundColor = CGColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)
    }


    // MARK: Init

    /// Used to lazy load static singleton instance
    static func instantiate() {
        guard MasterViewController.instance == nil else {
            return
        }

        let storyboard = NSStoryboard(name: Constants.storyboard, bundle: .main)
        let controller = storyboard.instantiateInitialController() as! MasterViewController
        let screen = NSScreen.main!
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
        setupActionButton()
    }


    // MARK: API

    /// Terminates all currently running applications
    func close() {
        screens.enumerated().forEach { screen, _ in
            terminate(screen: screen)
        }
    }


    // MARK: Setup

    private func setupScreens() {
        leftScreen.layer?.backgroundColor = Constants.screenBackgroundColor
        leftScreen.layer?.borderWidth = Constants.screenBorderWidth
        leftScreen.layer?.borderColor = CGColor.black
        leftScreen.layer?.contents = ControlAction.closeApplication.image

        middleScreen.layer?.backgroundColor = Constants.screenBackgroundColor
        middleScreen.layer?.borderWidth = Constants.screenBorderWidth
        middleScreen.layer?.borderColor = CGColor.black
        middleScreen.layer?.contents = ControlAction.closeApplication.image

        rightScreen.layer?.backgroundColor = Constants.screenBackgroundColor
        rightScreen.layer?.borderWidth = Constants.screenBorderWidth
        rightScreen.layer?.borderColor = CGColor.black
        rightScreen.layer?.contents = ControlAction.closeApplication.image
    }

    private func setupActionButton() {
        actionSelectionButton.removeAllItems()
        ControlAction.allValues.forEach { action in
            actionSelectionButton.addItem(withTitle: action.title)
        }
    }


    // MARK: IB-Actions
    
    @IBAction func applyButtonClicked(_ sender: NSButton) {
        guard let selectedAction = actionSelectionButton.selectedItem, let action = ControlAction(title: selectedAction.title) else {
            return
        }

        checkboxes.enumerated().forEach { index, checkbox in
            if checkbox.state == .on {
                apply(action, toScreen: index)
            }
        }
    }


    // MARK: Helpers

    private func apply(_ action: ControlAction, toScreen screen: Int) {
        // Ignore action if it's already current
        if let currentInfo = infoForScreen[screen], currentInfo.action == action {
            return
        }

        // Clear currently running processes
        terminate(screen: screen)

        // Load new processes
        switch action {
        case .launchMapExplorer:
            launchMaps(screen: screen)
        case .launchTimeline:
            infoForScreen[screen] = ApplicationInfo(action: .launchTimeline, applications: [])
        case .closeApplication:
            break
        }

        transition(screen: screen, to: action)
    }

    /// Execute a shell command, returns the created process
    @discardableResult
    private func execute(path: String, args: [String]) -> NSRunningApplication? {
        do {
            let url = URL(fileURLWithPath: path)
            let config = [NSWorkspace.LaunchConfigurationKey.arguments: args]
            let application = try NSWorkspace.shared.launchApplication(at: url, options: .newInstance, configuration: config)
            return application
        } catch {
            print("Failed to execute: \(path).")
            return nil
        }
    }

    /// Terminate the processes associated with the given screen
    private func terminate(screen: Int) {
        guard let info = infoForScreen[screen] else {
            return
        }

        info.applications.forEach { application in
            application.terminate()
        }

        infoForScreen[screen] = ApplicationInfo(action: .closeApplication, applications: [])
    }

    /// Launch MapExplorer on the given screen
    private func launchMaps(screen: Int) {
        var applications = [NSRunningApplication]()

        for map in 0 ..< Configuration.mapsPerScreen {
            if let application = execute(path: Paths.mapExplorer, args: [String(screen + 1), String(map)]) {
                applications.append(application)
            }
        }

        infoForScreen[screen] = ApplicationInfo(action: .launchMapExplorer, applications: applications)
    }

    private func transition(screen: Int, to action: ControlAction) {
        if let screenView = screens.at(index: screen), let image = action.image {
            screenView.transition(to: image, duration: Constants.imageTransitionDuration)
        }
    }
}
