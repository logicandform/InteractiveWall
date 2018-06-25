//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum ButtonState {
    case on
    case off

    var toggled: ButtonState {
        switch self {
        case .on:
            return .off
        case .off:
            return .on
        }
    }
}


class MenuViewController: NSViewController, GestureResponder, SearchViewDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Menu")

    @IBOutlet weak var menuView: NSView!
    @IBOutlet weak var splitScreenButton: MenuButton!
    @IBOutlet weak var mapToggleButton: MenuButton!
    @IBOutlet weak var timelineToggleButton: MenuButton!
    @IBOutlet weak var informationButton: MenuButton!
    @IBOutlet weak var settingsButton: MenuButton!
    @IBOutlet weak var testimonyButton: MenuButton!
    @IBOutlet weak var searchButton: MenuButton!

    var gestureManager: GestureManager!
    private var appID: Int!
    private var viewForButtonType = [MenuButtonType: MenuButton]()
    private var stateForButton = [MenuButtonType: ButtonState]()
    private var mergeLockIcon: NSView?
    private var mergeLocked = false
    private var scrollThresholdAchieved = false
    private var settingsMenu: SettingsMenuViewController!
    private var searchMenu: SearchViewController?

    private struct Constants {
        static let minimumScrollThreshold: CGFloat = 4
        static let imageTransitionDuration = 0.5
        static let animationDuration = 0.5
    }

    private struct Keys {
        static let id = "id"
        static let group = "group"
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        gestureManager = GestureManager(responder: self)
        viewForButtonType = [.split: splitScreenButton, .map: mapToggleButton, .timeline: timelineToggleButton, .information: informationButton, .settings: settingsButton, .testimony: testimonyButton, .search: searchButton]

        setupButtons()
        setupGestures()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        settingsMenu = WindowManager.instance.display(.settings, at: position(for: settingsButton, frame: style.settingsWindowSize, margins: false)) as? SettingsMenuViewController
        settingsMenu.view.isHidden = true
        if let appID = appID {
            settingsMenu.set(appID: appID)
        }
    }


    // MARK: API

    func set(appID: Int) {
        self.appID = appID
        settingsMenu?.set(appID: appID)
    }

    func toggleMergeLock(on: Bool) {
        if mergeLocked != on, let splitButton = viewForButtonType[MenuButtonType.split] {
            mergeLocked = splitButton.toggleLockIcon(on: on)
        }
    }

    func toggle(_ type: MenuButtonType, to state: ButtonState) {
        guard let currentState = stateForButton[type], currentState != state || type == .search, let button = viewForButtonType[type] else {
            return
        }

        // Set the new state
        stateForButton[type] = state

        // Transition image for the button
        button.toggle(to: state)

        switch type {
        case .map where state == .on:
            // Send notification for switch
            // TODO: UBC-440
            toggle(.timeline, to: .off)
            toggle(.settings, to: .off)
            toggle(.information, to: .off)
        case .timeline where state == .on:
            // Send notification for switch
            // TODO: UBC-440
            toggle(.map, to: .off)
            toggle(.settings, to: .off)
            toggle(.information, to: .off)
        case .information:
            toggleInfoPanel(to: state)
            if state == .on {
                toggle(.settings, to: .off)
            }
        case .settings:
            toggleSettingsPanel(to: state)
            if state == .on {
                toggle(.information, to: .off)
            }
        case .search where state == .on:
            displaySearchController()
            toggle(.settings, to: .off)
            toggle(.information, to: .off)
        default:
            return
        }
    }


    // MARK: Setup

    private func setupGestures() {
        let viewPanGesture = PanGestureRecognizer()
        gestureManager.add(viewPanGesture, to: view)
        viewPanGesture.gestureUpdated = handleWindowPan(_:)
    }

    private func setupButtons() {
        setupButton(for: .split)
        setupButton(for: .map)
        setupButton(for: .timeline)
        setupButton(for: .information)
        setupButton(for: .settings)
        setupButton(for: .testimony)
        setupButton(for: .search)
    }


    // MARK: Gesture Handling

    private func didSelect(type: MenuButtonType) {
        guard let state = stateForButton[type] else {
            return
        }

        switch type {
        case .split:
            if state == .off {
                postSplitNotification()
            } else if !mergeLocked {
                postMergeNotification()
            }
        case .map, .timeline:
            if state == .off {
                toggle(type, to: state.toggled)
            }
        case .information, .settings, .testimony:
            toggle(type, to: state.toggled)
        case .search:
            toggle(type, to: .on)
        }
    }

    func handleWindowPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let window = view.window else {
            return
        }

        switch pan.state {
        case .recognized where abs(pan.delta.dy) > Constants.minimumScrollThreshold || scrollThresholdAchieved, .momentum where scrollThresholdAchieved:
            scrollThresholdAchieved = true
            let origin = originAppending(delta: pan.delta, to: window)
            let settingsButtonFrame = settingsButton.frame
            settingsMenu.updateOrigin(relativeTo: origin, with: settingsButtonFrame)
            window.setFrameOrigin(origin)
        case .possible:
            scrollThresholdAchieved = false
        default:
            return
        }
    }


    // MARK: GestureResponder

    /// Determines if the bounds of the draggable area is inside a given rect
    func draggableInside(bounds: CGRect) -> Bool {
        guard let window = view.window else {
            return false
        }

        return bounds.contains(view.frame.transformed(from: window.frame))
    }

    func subview(contains position: CGPoint) -> Bool {
        return view.frame.contains(position)
    }


    // MARK: SearchViewDelegate

    func searchDidClose() {
        toggle(.search, to: .off)
        searchMenu = nil
    }


    // MARK: Helpers

    private func setupButton(for type: MenuButtonType) {
        guard let button = viewForButtonType[type] else {
            return
        }

        button.buttonType = type
        addGesture(for: type)

        switch type {
        case .split:
            stateForButton[type] = .off
        case .map:
            button.toggle(to: .on)
            stateForButton[type] = .on
        case .timeline, .information, .settings, .search, .testimony:
            stateForButton[type] = .off
        }
    }

    private func addGesture(for type: MenuButtonType) {
        guard let button = viewForButtonType[type] else {
            return
        }

        let panGesture = PanGestureRecognizer()
        gestureManager.add(panGesture, to: button)
        panGesture.gestureUpdated = handleWindowPan(_:)

        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: button)
        tapGesture.gestureUpdated = { [weak self] tap in
            if tap.state == .ended {
                self?.didSelect(type: type)
            }
        }
    }

    private func toggleSettingsPanel(to state: ButtonState) {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            settingsMenu.view.animator().isHidden = state == .off
        })
    }

    private func toggleInfoPanel(to state: ButtonState) {

    }

    /// Presents a search controller at the same height as the button, if one is already displayed; animates into position
    private func displaySearchController() {
        if let searchMenu = searchMenu {
            searchMenu.updateOrigin(to: centeredPosition(for: searchButton, with: style.searchWindowSize), animating: true)
        } else {
            searchMenu = WindowManager.instance.display(.search, at: centeredPosition(for: searchButton, with: style.searchWindowSize)) as? SearchViewController
            searchMenu?.searchViewDelegate = self
        }
    }

    private func originAppending(delta: CGVector, to window: NSWindow) -> CGPoint {
        guard let screen = window.screen else {
            return window.frame.origin
        }

        var origin = window.frame.origin
        origin.y += delta.dy

        if delta.dy < 0 && origin.y < screen.frame.minY {
            origin.y = screen.frame.minY
        } else if delta.dy > 0 && origin.y + window.frame.height > screen.frame.maxY {
            origin.y = screen.frame.maxY - window.frame.height
        }

        return origin
    }

    private func centeredPosition(for button: MenuButton, with frame: CGSize) -> CGPoint {
        guard let buttonWindowPosition = button.window?.frame else {
            return CGPoint.zero
        }

        let screenBounds = NSScreen.at(position: (appID / Configuration.appsPerScreen) + 1).frame
        let windowBottom = buttonWindowPosition.origin.y + button.frame.origin.y + button.frame.height - frame.height

        let screenMin = screenBounds.minX
        let halfAppWidth = screenBounds.width / CGFloat(Configuration.appsPerScreen) / 2
        let halfFrameWidth = frame.width / 2
        let offsetX = appID % Configuration.appsPerScreen == 0 ? halfAppWidth : halfAppWidth * 3

        let x = offsetX + screenMin - halfFrameWidth
        let y = max(windowBottom, screenBounds.minY)

        return CGPoint(x: x, y: y)
    }

    private func position(for button: NSView, frame: CGSize, margins: Bool = true) -> CGPoint {
        guard let windowPosition = button.window?.frame, let screenBounds = NSScreen.containing(x: windowPosition.origin.x)?.frame else {
            return CGPoint(x: 0, y: 0)
        }

        let windowMargin = margins ? style.windowMargins : 0
        let buttonOrigin = windowPosition.transformed(from: button.frame).origin
        var x = windowPosition.maxX + windowMargin
        let y = buttonOrigin.y + style.menuImageSize.height - frame.height

        if windowPosition.maxX >= screenBounds.maxX {
            x = windowPosition.origin.x - frame.width - windowMargin
        }

        return CGPoint(x: x, y: y)
    }

    private func postSplitNotification() {
        var info: JSON = [Keys.id: appID]
        if let group = ConnectionManager.instance.groupForApp(id: appID) {
            info[Keys.group] = group
        }
        DistributedNotificationCenter.default().postNotificationName(SettingsNotification.split.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    private func postMergeNotification() {
        var info: JSON = [Keys.id: appID]
        if let group = ConnectionManager.instance.groupForApp(id: appID) {
            info[Keys.group] = group
        }
        DistributedNotificationCenter.default().postNotificationName(SettingsNotification.merge.name, object: nil, userInfo: info, deliverImmediately: true)
    }
}
