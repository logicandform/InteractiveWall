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


class MenuViewController: NSViewController, GestureResponder, SearchViewDelegate, TestimonyDelegate, SettingsDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Menu")

    @IBOutlet weak var menuView: NSView!
    @IBOutlet weak var menuBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var accessibilityButton: MenuButton!
    @IBOutlet weak var splitScreenButton: MenuButton!
    @IBOutlet weak var mapToggleButton: MenuButton!
    @IBOutlet weak var timelineToggleButton: MenuButton!
    @IBOutlet weak var informationButton: MenuButton!
    @IBOutlet weak var settingsButton: MenuButton!
    @IBOutlet weak var testimonyButton: MenuButton!
    @IBOutlet weak var searchButton: MenuButton!

    var gestureManager: GestureManager!
    private var appID: Int!
    private var positionResetTimer: Foundation.Timer!
    private var viewForButtonType = [MenuButtonType: MenuButton]()
    private var stateForButton = [MenuButtonType: ButtonState]()
    private var mergeLockIcon: NSView?
    private var mergeLocked = false
    private var scrollThresholdAchieved = false
    private var settingsMenu: SettingsMenuViewController!
    private var searchMenu: SearchViewController?
    private var testimonyController: TestimonyViewController?

    private struct Constants {
        static let minimumScrollThreshold: CGFloat = 4
        static let imageTransitionDuration = 0.5
        static let animationDuration = 0.5
        static let positionResetInterval: TimeInterval = 180
    }

    private struct Keys {
        static let id = "id"
        static let type = "type"
        static let group = "group"
        static let oldType = "oldType"
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        gestureManager.touchReceived = receivedTouch(_:)
        viewForButtonType = [.split: splitScreenButton, .map: mapToggleButton, .timeline: timelineToggleButton, .information: informationButton, .settings: settingsButton, .testimony: testimonyButton, .search: searchButton, .accessibility: accessibilityButton]

        setupMenu()
        setupButtons()
        setupGestures()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        setupSettings()
    }


    // MARK: API

    func set(appID: Int) {
        self.appID = appID
        settingsMenu?.set(appID: appID)
    }

    func toggleMergeLock(on: Bool) {
        if mergeLocked != on, let splitButton = viewForButtonType[.split] {
            splitButton.toggleLockIcon(on: on)
            mergeLocked = on
        }
    }

    func toggle(_ type: MenuButtonType, to state: ButtonState, forced: Bool = false) {
        if let currentState = stateForButton[type], currentState == state, !forced {
            return
        }

        // Set the new state & transition image
        stateForButton[type] = state
        if let button = viewForButtonType[type] {
            button.toggle(to: state)
        }

        switch type {
        case .map where state == .on:
            toggle(.timeline, to: .off)
            toggle(.settings, to: .off)
            toggle(.information, to: .off)
        case .timeline where state == .on:
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
        case .testimony where state == .on:
            displayTestimonyController()
        case .search where state == .on:
            displaySearchController()
            toggle(.settings, to: .off)
            toggle(.information, to: .off)
        case .accessibility where state == .on:
            toggleMenuAccessibility()
        default:
            return
        }
    }


    // MARK: Setup

    private func setupGestures() {
        let viewPanGesture = PanGestureRecognizer()
        gestureManager.add(viewPanGesture, to: menuView)
        viewPanGesture.gestureUpdated = { [weak self] gesture in
            self?.handleMenuPan(gesture)
        }
    }

    private func setupButtons() {
        MenuButtonType.allValues.forEach { setupButton(for: $0) }
        toggle(.map, to: .on)
    }

    private func setupMenu() {
        menuView.wantsLayer = true
        menuBottomConstraint.constant = (view.frame.height / 2) - (menuView.frame.height / 2)
    }

    private func setupSettings() {
        settingsMenu = WindowManager.instance.display(.settings, at: position(for: settingsButton, frame: style.settingsWindowSize, margins: false)) as? SettingsMenuViewController
        settingsMenu.view.isHidden = true
        settingsMenu.settingsParent = self

        if let appID = appID {
            settingsMenu.set(appID: appID)
        }
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
                postTransitionNotification(for: type)
            }
        case .information, .settings:
            toggle(type, to: state.toggled)
        case .search, .testimony, .accessibility:
            toggle(type, to: .on, forced: true)
        }
    }

    func handleMenuPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized where abs(pan.delta.dy) > Constants.minimumScrollThreshold || scrollThresholdAchieved, .momentum where scrollThresholdAchieved:
            scrollThresholdAchieved = true
            menuBottomConstraint.constant = menuOffset(given: pan.delta)
            settingsMenu.updateOrigin(relativeTo: menuBottomConstraint.constant, with: settingsButton.frame)
        case .possible:
            scrollThresholdAchieved = false
        default:
            return
        }
    }


    // MARK: GestureResponder

    /// Determines if the bounds of the draggable area is inside a given rect
    func draggableInside(bounds: CGRect) -> Bool {
        guard let window = menuView.window else {
            return false
        }

        return bounds.contains(menuView.frame.transformed(from: window.frame))
    }

    func subview(contains position: CGPoint) -> Bool {
        return menuView.frame.contains(position) || accessibilityButton.frame.contains(position)
    }


    // MARK: SearchViewDelegate

    func searchDidClose() {
        toggle(.search, to: .off)
        searchMenu = nil
    }


    // MARK: TestimonyDelegate

    func testimonyDidClose() {
        toggle(.testimony, to: .off)
        testimonyController = nil
    }


    // MARK: SettingsDelegate

    func settingsTimeoutFired() {
        toggle(.settings, to: .off)
    }


    // MARK: Helpers

    private func setupButton(for type: MenuButtonType) {
        guard let button = viewForButtonType[type] else {
            return
        }

        button.wantsLayer = true
        button.layer?.backgroundColor = style.darkBackground.cgColor
        button.buttonType = type
        addGesture(for: type)

        switch type {
        case .split:
            stateForButton[type] = .off
        case .map, .timeline, .information, .settings, .testimony, .search, .accessibility:
            stateForButton[type] = .off
        }
    }

    private func addGesture(for type: MenuButtonType) {
        guard let button = viewForButtonType[type] else {
            return
        }

        if type != .accessibility {
            let panGesture = PanGestureRecognizer()
            gestureManager.add(panGesture, to: button)
            panGesture.gestureUpdated = { [weak self] gesture in
                self?.handleMenuPan(gesture)
            }
        }

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
            searchMenu.updateOrigin(to: centeredPosition(for: style.searchWindowFrame), animating: true)
        } else {
            searchMenu = WindowManager.instance.display(.search, at: centeredPosition(for: style.searchWindowFrame)) as? SearchViewController
            searchMenu?.searchViewDelegate = self
        }
    }

    /// Presents a testimony controller at the same height as the button, if one is already displayed; animates into position
    private func displayTestimonyController() {
        if let testimonyController = testimonyController {
            testimonyController.updateOrigin(to: centeredPosition(for: style.testimonyWindowSize), animating: true)
        } else {
            testimonyController = WindowManager.instance.display(.testimony, at: centeredPosition(for: style.testimonyWindowSize)) as? TestimonyViewController
            testimonyController?.testimonyDelegate = self
        }
    }

    private func toggleMenuAccessibility() {
        guard let window = view.window else {
            return
        }

        let x = window.frame.minX
        let y = accessibilityButton.frame.height
        animateMenu(to: CGPoint(x: x, y: y))
    }

    private func menuOffset(given vector: CGVector) -> CGFloat {
        guard let screen = menuView.window?.screen else {
            return CGPoint.zero.y
        }

        var newOrigin = menuView.frame.origin
        newOrigin.y += vector.dy

        if vector.dy < 0 && newOrigin.y < screen.frame.minY + accessibilityButton.frame.height {
            newOrigin.y = screen.frame.minY + accessibilityButton.frame.height
        } else if vector.dy > 0 && newOrigin.y + menuView.frame.height > screen.frame.maxY {
            newOrigin.y = screen.frame.maxY - menuView.frame.height
        }

        return newOrigin.y
    }

    private func centeredPosition(for frame: CGSize) -> CGPoint {
        guard let menuWindowPosition = menuView.window?.frame else {
            return CGPoint.zero
        }

        let menuOrigin = menuWindowPosition.transformed(from: menuView.frame).origin
        let screenBounds = NSScreen.at(appID: appID).frame
        let windowBottom = menuOrigin.y + menuView.frame.height - frame.height

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
        let buttonOrigin = windowPosition.transformed(from: button.frame).transformed(from: menuView.frame).origin
        let x = windowPosition.minX <= screenBounds.minX ? windowPosition.maxX + windowMargin : windowPosition.origin.x - frame.width - windowMargin
        let y = buttonOrigin.y + style.menuImageSize.height - frame.height

        return CGPoint(x: x, y: y)
    }

    private func postSplitNotification() {
        let type = ConnectionManager.instance.typeForApp(id: appID)
        var info: JSON = [Keys.id: appID, Keys.type: type.rawValue]
        if let group = ConnectionManager.instance.groupForApp(id: appID) {
            info[Keys.group] = group
        }
        DistributedNotificationCenter.default().postNotificationName(SettingsNotification.split.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    private func postMergeNotification() {
        let type = ConnectionManager.instance.typeForApp(id: appID)
        var info: JSON = [Keys.id: appID, Keys.type: type.rawValue]
        if let group = ConnectionManager.instance.groupForApp(id: appID) {
            info[Keys.group] = group
        }
        DistributedNotificationCenter.default().postNotificationName(SettingsNotification.merge.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    private func postTransitionNotification(for type: MenuButtonType) {
        guard let newType = type.applicationType else {
            return
        }
        let oldType = ConnectionManager.instance.typeForApp(id: appID)
        var info: JSON = [Keys.id: appID, Keys.type: newType.rawValue, Keys.oldType: oldType.rawValue]
        if let group = ConnectionManager.instance.groupForApp(id: appID) {
            info[Keys.group] = group
        }
        DistributedNotificationCenter.default().postNotificationName(SettingsNotification.transition.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    /// Animates the menu to a new origin
    private func animateMenu(to origin: NSPoint) {
        guard let window = view.window, let screen = window.screen, !gestureManager.isActive() else {
            return
        }

        gestureManager.invalidateAllGestures()
        window.makeKeyAndOrderFront(self)
        toggle(.settings, to: .off)
        let originalHeight = menuBottomConstraint.constant
        let offset = abs(originalHeight - origin.y) / screen.frame.height
        let duration = max(Double(offset), Constants.animationDuration)

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = duration
            NSAnimationContext.current.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            menuBottomConstraint.animator().constant = origin.y
        }, completionHandler: { [weak self] in
            self?.toggle(.accessibility, to: .off)
            if let settingsButton = self?.settingsButton {
                self?.settingsMenu.updateOrigin(relativeTo: origin.y, with: settingsButton.frame)
            }
        })
    }

    private func receivedTouch(_ touch: Touch) {
        resetPositionResetTimer()
        settingsMenu.resetSettingsTimeout()
    }

    private func resetPositionResetTimer() {
        guard let window = view.window else {
            return
        }

        let verticalPosition = NSScreen.at(appID: appID).frame.midY - (menuView.frame.height / 2)
        positionResetTimer?.invalidate()
        positionResetTimer = Timer.scheduledTimer(withTimeInterval: Constants.positionResetInterval, repeats: false) { [weak self] _ in
            self?.animateMenu(to: CGPoint(x: window.frame.minX, y: verticalPosition))
        }
    }
}
