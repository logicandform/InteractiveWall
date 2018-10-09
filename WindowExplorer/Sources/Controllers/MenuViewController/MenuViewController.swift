//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa
import MacGestures


protocol MenuDelegate: class {
    func searchChildClosed()
}


class MenuViewController: NSViewController, GestureResponder, MenuDelegate {
    static let storyboard = "Menu"
    static let leftSideIdentifier = "MenuLeft"
    static let rightSideIdentifier = "MenuRight"

    @IBOutlet weak var menuView: NSStackView!
    @IBOutlet weak var infoMenuView: NSView!
    @IBOutlet weak var infoDragArea: NSView!
    @IBOutlet weak var infoCloseArea: NSView!
    @IBOutlet weak var accessibilityButtonArea: NSView!
    @IBOutlet weak var menuToggleButton: ImageView!
    @IBOutlet weak var menuBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuSideConstraint: NSLayoutConstraint!

    var appID: Int!
    var gestureManager: GestureManager!
    private var resetTimer: Foundation.Timer!
    private var buttonForType = [MenuButtonType: MenuButton]()
    private var menuOpened = false
    private var animating = false
    private weak var searchChild: SearchChild?

    private var menuSide: MenuSide {
        return appID.isEven ? .left : .right
    }

    private struct Constants {
        static let imageTransitionDuration = 0.5
        static let fadeAnimationDuration = 0.5
        static let verticalAnimationDuration = 1.2
        static let menuButtonSize = CGSize(width: 200, height: 50)
        static let inactivePriority = NSLayoutConstraint.Priority(150)
        static let activePriority = NSLayoutConstraint.Priority(200)
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
        gestureManager.touchReceived = { [weak self] touch in
            self?.receivedTouch(touch)
        }

        setupMenu()
        setupGestures()
        setupAccessibilityButton()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        centerMenu()
        setupInfoMenu()
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let infoViewController = segue.destinationController as? InfoViewController {
            infoViewController.appID = appID
            infoViewController.gestureManager = gestureManager
        }
    }


    // MARK: API

    func toggleMergeLock(on: Bool) {
        if let button = buttonForType[.split] {
            button.set(locked: on)
        }
    }

    func set(_ type: MenuButtonType, selected: Bool, forced: Bool = false) {
        guard let button = buttonForType[type] else {
            return
        }

        if button.selected == selected && !forced {
            return
        }

        button.set(selected: selected)

        switch type {
        case .map where selected:
            set(.timeline, selected: false)
            set(.nodeNetwork, selected: false)
            set(.information, selected: false)
        case .timeline where selected:
            set(.map, selected: false)
            set(.nodeNetwork, selected: false)
            set(.information, selected: false)
        case .nodeNetwork where selected:
            set(.map, selected: false)
            set(.timeline, selected: false)
            set(.information, selected: false)
        case .information:
            set(infoMenuView.subviews.first, hidden: !selected, animated: true)
        case .search where selected:
            displaySearchChild()
            set(.information, selected: false)
        case .accessibility where selected:
            postAccessibilityNotification()
        default:
            return
        }
    }

    func handleAccessibilityNotification() {
        animateMenu(verticalPosition: Constants.menuButtonSize.height, completion: { [weak self] in
            self?.set(.accessibility, selected: false)
        })
    }


    // MARK: Setup

    private func setupMenu() {
        MenuButtonType.itemsInMenu.map {
            createButton(for: $0)
        }.forEach {
            menuView.addView($0, in: .top)
        }
        menuToggleButton.set(menuSide.arrow)
        set(.map, selected: true)
    }

    private func setupGestures() {
        let infoPanGesture  = PanGestureRecognizer()
        gestureManager.add(infoPanGesture, to: infoDragArea)
        infoPanGesture.gestureUpdated = { [weak self] gesture in
            self?.handleInfoPan(gesture)
        }

        let infoCloseButtonTap = TapGestureRecognizer()
        gestureManager.add(infoCloseButtonTap, to: infoCloseArea)
        infoCloseButtonTap.gestureUpdated = { [weak self] gesture in
            if gesture.state == .ended {
                self?.set(.information, selected: false)
            }
        }

        let toggleMenuTap = TapGestureRecognizer()
        gestureManager.add(toggleMenuTap, to: menuToggleButton)
        toggleMenuTap.gestureUpdated = { [weak self] gesture in
            if gesture.state == .ended, let opened = self?.menuOpened {
                self?.toggleSideMenu(open: !opened)
            }
        }
    }

    private func setupAccessibilityButton() {
        let button = MenuButton(frame: .zero, side: menuSide)
        button.set(type: .accessibility)
        buttonForType[.accessibility] = button
        addGestures(to: button, tap: true, pan: false)
        accessibilityButtonArea.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.leadingAnchor.constraint(equalTo: accessibilityButtonArea.leadingAnchor).isActive = true
        button.topAnchor.constraint(equalTo: accessibilityButtonArea.topAnchor).isActive = true
        button.trailingAnchor.constraint(equalTo: accessibilityButtonArea.trailingAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: accessibilityButtonArea.bottomAnchor).isActive = true
    }

    private func centerMenu() {
        menuBottomConstraint.constant = view.frame.midY - menuView.frame.height / 2
        infoBottomConstraint.constant = view.frame.midY - menuView.frame.height / 2
    }

    private func setupInfoMenu() {
        set(infoMenuView.subviews.first, hidden: true, animated: false)
    }


    // MARK: Gesture Handling

    private func didSelect(type: MenuButtonType) {
        guard let button = buttonForType[type] else {
            return
        }

        switch type {
        case .split:
            if !button.selected {
                postSplitNotification()
            } else if !button.locked {
                postMergeNotification()
            }
        case .map, .timeline, .nodeNetwork:
            if !button.selected {
                postTransitionNotification(for: type)
                set(.information, selected: false)
            }
        case .information, .settings:
            set(type, selected: !button.selected)
        case .search, .accessibility:
            set(type, selected: true, forced: true)
        }
    }

    func handleInfoPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, !animating else {
            return
        }

        switch pan.state {
        case .began:
            menuBottomConstraint.priority = Constants.inactivePriority
            infoBottomConstraint.priority = Constants.activePriority
        case .recognized, .momentum:
            let infoBottomOffset = clamp(infoBottomConstraint.constant + pan.delta.dy, min: 0, max: view.frame.height - infoMenuView.frame.height)
            infoBottomConstraint.constant = infoBottomOffset
            menuBottomConstraint.constant = menuView.frame.minY
        default:
            return
        }
    }

    func handleMenuPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, !animating else {
            return
        }

        switch pan.state {
        case .began:
            infoBottomConstraint.priority = Constants.inactivePriority
            menuBottomConstraint.priority = Constants.activePriority
        case .recognized, .momentum:
            let menuBottomOffset = clamp(menuBottomConstraint.constant + pan.delta.dy, min: Constants.menuButtonSize.height, max: view.frame.height - menuView.frame.height)
            menuBottomConstraint.constant = menuBottomOffset
            infoBottomConstraint.constant = infoMenuView.frame.minY
        default:
            return
        }
    }


    // MARK: MenuDelegate

    func receivedTouch(_ touch: Touch) {
        switch touch.state {
        case .down, .up:
            refreshResetTimer()
        case .moved:
            break
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
        if let infoButton = buttonForType[.information], infoButton.selected && infoMenuView.frame.contains(position) {
            return true
        }

        return menuView.frame.contains(position) || accessibilityButtonArea.frame.contains(position) || menuToggleButton.frame.contains(position)
    }


    // MARK: MenuDelegate

    func searchChildClosed() {
        set(.search, selected: false)
        searchChild = nil
    }


    // MARK: Helpers

    private func createButton(for type: MenuButtonType) -> MenuButton {
        let button = MenuButton(frame: CGRect(origin: .zero, size: Constants.menuButtonSize), side: menuSide)
        button.set(type: type)
        buttonForType[type] = button
        addGestures(to: button, tap: true, pan: true)
        return button
    }

    private func addGestures(to button: MenuButton, tap: Bool, pan: Bool) {
        if pan {
            let panGesture = PanGestureRecognizer()
            gestureManager.add(panGesture, to: button)
            panGesture.gestureUpdated = { [weak self] gesture in
                self?.handleMenuPan(gesture)
            }
        }

        if tap {
            let tapGesture = TapGestureRecognizer()
            gestureManager.add(tapGesture, to: button)
            tapGesture.gestureUpdated = { [weak self] tap in
                if tap.state == .ended {
                    self?.didSelect(type: button.type)
                }
            }
        }
    }

    private func set(_ view: NSView?, hidden: Bool, animated: Bool) {
        if animated {
            NSAnimationContext.runAnimationGroup({ _ in
                NSAnimationContext.current.duration = Constants.fadeAnimationDuration
                view?.animator().alphaValue = hidden ? 0 : 1
            })
        } else {
            view?.alphaValue = hidden ? 0 : 1
        }
    }

    /// Presents a search child at the center of the session for the current menu
    private func displaySearchChild() {
        guard let screen = view.window?.screen else {
            return
        }

        // Calculate the origin for the search controller
        let quarterScreen = screen.frame.width / 4
        let center = appID.isEven ? screen.frame.minX + quarterScreen : screen.frame.maxX - quarterScreen
        let x = center - style.searchWindowFrame.width / 2
        let y = menuView.frame.minY - style.searchWindowFrame.height / 2
        let origin = CGPoint(x: x, y: y)

        if let searchChild = searchChild {
            searchChild.setWindow(origin: origin, animate: true, completion: nil)
        } else {
            searchChild = WindowManager.instance.display(.search, at: origin) as? SearchChild
            searchChild?.delegate = self
        }
    }

    /// Toggles the menus side constraint to increase / decrease its visible size
    private func toggleSideMenu(open: Bool) {
        menuOpened = open

        let image = menuSide.image(toggled: open)
        menuToggleButton.transition(image, duration: Constants.fadeAnimationDuration)

        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = Constants.fadeAnimationDuration
            NSAnimationContext.current.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            self?.menuSideConstraint.animator().constant = open ? Constants.menuButtonSize.width : Constants.menuButtonSize.height
        })
    }

    private func postAccessibilityNotification() {
        var info: JSON = [Keys.id: appID]
        if let group = ConnectionManager.instance.groupForApp(id: appID) {
            info[Keys.group] = group
        }
        DistributedNotificationCenter.default().postNotificationName(SettingsNotification.accessibility.name, object: nil, userInfo: info, deliverImmediately: true)
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

    private func animateMenu(verticalPosition: CGFloat, completion: (() -> Void)? = nil) {
        if animating || gestureManager.isActive() {
            return
        }

        animating = true
        infoBottomConstraint.priority = Constants.inactivePriority
        menuBottomConstraint.priority = Constants.activePriority

        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = Constants.verticalAnimationDuration
            NSAnimationContext.current.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            self?.menuBottomConstraint.animator().constant = verticalPosition
        }, completionHandler: { [weak self] in
            self?.animating = false
            completion?()
        })
    }

    private func refreshResetTimer() {
        resetTimer?.invalidate()
        resetTimer = Timer.scheduledTimer(withTimeInterval: Configuration.menuResetTimeoutDuration, repeats: false) { [weak self] _ in
            self?.resetTimerFired()
        }
    }

    private func resetTimerFired() {
        gestureManager.invalidateAllGestures()
        set(.information, selected: false)
        let center = view.frame.midY - menuView.frame.height / 2
        animateMenu(verticalPosition: center)
        toggleSideMenu(open: false)
    }
}
