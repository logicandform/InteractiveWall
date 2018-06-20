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
    @IBOutlet weak var splitScreenButton: NSImageView!
    @IBOutlet weak var mapToggleButton: NSImageView!
    @IBOutlet weak var timelineToggleButton: NSImageView!
    @IBOutlet weak var informationButton: NSImageView!
    @IBOutlet weak var settingsButton: NSImageView!
    @IBOutlet weak var searchButton: NSImageView!

    var gestureManager: GestureManager!
    private var appID: Int!
    private var viewForButtonType = [MenuButtonType: NSView]()
    private var subviewForButtonType = [MenuButtonType: NSView]()
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
        viewForButtonType = [.split: splitScreenButton, .map: mapToggleButton, .timeline: timelineToggleButton, .information: informationButton, .settings: settingsButton, .search: searchButton]

        setupButtons()
        setupGestures()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        settingsMenu = WindowManager.instance.display(.settings, at: position(for: settingsButton, frame: style.settingsWindowSize, margins: false)) as? SettingsMenuViewController
        settingsMenu.view.isHidden = true
    }


    // MARK: API

    func set(appID: Int) {
        self.appID = appID
        settingsMenu.set(appID: appID)
    }

    func toggleMergeLock(on: Bool) {
        if mergeLocked != on {
            let lockImage = on ? MenuButtonType.split.detailImage : nil
            mergeLockIcon?.transition(to: lockImage, duration: Constants.imageTransitionDuration)
            mergeLocked = on
        }
    }

    func toggle(_ type: MenuButtonType, to state: ButtonState) {
        guard let currentState = stateForButton[type], currentState != state || type == .search, let subview = subviewForButtonType[type] else {
            return
        }

        // Set the new state
        stateForButton[type] = state

        // Transition image for the button
        let image = state == .on ? type.selectedImage : type.image
        subview.transition(to: image, duration: Constants.imageTransitionDuration)

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
        case .information, .settings:
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
        guard let view = viewForButtonType[type], let imageIcon = type.image else {
            return
        }

        let image = NSView()
        view.addSubview(image)
        image.wantsLayer = true
        image.layer?.contents = imageIcon
        image.translatesAutoresizingMaskIntoConstraints = false

        if view.frame.width < imageIcon.size.width {
            image.widthAnchor.constraint(equalToConstant: style.menuImageSize.width).isActive = true
        } else {
            image.widthAnchor.constraint(equalToConstant: imageIcon.size.width).isActive = true
        }

        if view.frame.height < imageIcon.size.height {
            image.heightAnchor.constraint(equalToConstant: style.menuImageSize.height).isActive = true
        } else {
            image.heightAnchor.constraint(equalToConstant: imageIcon.size.height).isActive = true
        }

        image.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        image.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        subviewForButtonType[type] = image
        addGesture(for: type)

        switch type {
        case .split:
            guard let secondaryPlaceholder = type.detailImage else {
                return
            }
            view.wantsLayer = true
            view.layer?.backgroundColor = style.menuSelectedColor.cgColor
            let lockIcon = NSView()
            view.addSubview(lockIcon)
            lockIcon.wantsLayer = true
            lockIcon.translatesAutoresizingMaskIntoConstraints = false
            lockIcon.widthAnchor.constraint(equalToConstant: secondaryPlaceholder.size.width).isActive = true
            lockIcon.heightAnchor.constraint(equalToConstant: secondaryPlaceholder.size.height).isActive = true
            lockIcon.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: style.menuLockIconPosition.width).isActive = true
            lockIcon.topAnchor.constraint(equalTo: view.topAnchor, constant: style.menuLockIconPosition.height).isActive = true
            mergeLockIcon = lockIcon
            stateForButton[type] = .off
        case .map:
            image.layer?.contents = type.selectedImage
            stateForButton[type] = .on
        case .timeline, .information, .settings, .search:
            stateForButton[type] = .off
        }
    }

    private func addGesture(for type: MenuButtonType) {
        guard let view = viewForButtonType[type], let subview = subviewForButtonType[type] else {
            return
        }

        let panGesture = PanGestureRecognizer()
        gestureManager.add(panGesture, to: subview)
        gestureManager.add(panGesture, to: view)
        panGesture.gestureUpdated = handleWindowPan(_:)

        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: subview)
        gestureManager.add(tapGesture, to: view)
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

    private func centeredPosition(for button: NSImageView, with frame: CGSize) -> CGPoint {
        guard let buttonWindowPosition = button.window?.frame, let screenBounds = NSScreen.containing(x: buttonWindowPosition.origin.x)?.frame else {
            return CGPoint(x: 0, y: 0)
        }

        var x = screenBounds.minX + ((screenBounds.width / CGFloat(Configuration.appsPerScreen)) / 2) - (frame.width / 2)
        var y = buttonWindowPosition.origin.y + button.frame.origin.y + button.frame.height - frame.height

        if buttonWindowPosition.maxX >= screenBounds.maxX {
            x = screenBounds.maxX - ((screenBounds.width / CGFloat(Configuration.appsPerScreen)) / 2) - (frame.width / 2)
        }

        if y < screenBounds.minY {
            y = screenBounds.minY
        }

        return CGPoint(x: x, y: y)
    }

    private func position(for button: NSImageView, frame: CGSize, margins: Bool = true) -> CGPoint {
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
