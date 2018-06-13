//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class MenuViewController: NSViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "Menu")

    @IBOutlet weak var menuView: NSView!
    @IBOutlet weak var splitScreenButton: NSImageView!
    @IBOutlet weak var mapToggleButton: NSImageView!
    @IBOutlet weak var timelineToggleButton: NSImageView!
    @IBOutlet weak var informationButton: NSImageView!
    @IBOutlet weak var settingsButton: NSImageView!
    @IBOutlet weak var searchButton: NSImageView!

    var gestureManager: GestureManager!
    var menuStateHelper: MenuStateHelper?
    private var viewForButtonType = [MenuButtonType: NSView]()
    private var subviewForButtonType = [MenuButtonType: NSView]()
    private var selectedButtons = [MenuButtonType]()
    private var lockIcon: NSView?
    private var scrollThresholdAchieved = false
    private var settingsMenu: SettingsMenuViewController!

    private struct Constants {
        static let minimumScrollThreshold: CGFloat = 4
        static let imageTransitionDuration = 0.5
        static let animationDuration = 0.5
    }


    // MARK: Init

    static func instantiate() {
        for screen in NSScreen.screens.sorted(by: { $0.frame.minX < $1.frame.minX }).dropFirst() {
            let screenFrame = screen.frame
            let menuStateHelper = MenuStateHelper()

            for menuNumber in (1 ... Configuration.mapsPerScreen) {
                let x = menuNumber % 2 == 1 ? screenFrame.maxX - style.menuWindowSize.width : screenFrame.minX
                let y = screenFrame.midY - style.menuWindowSize.height / 2

                if let menu = WindowManager.instance.display(.menu, at: CGPoint(x: x, y: y)) as? MenuViewController {
                    menuStateHelper.add(menu)
                    menu.menuStateHelper = menuStateHelper
                }
            }
        }
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        gestureManager = GestureManager(responder: self)
        viewForButtonType = [.splitScreen: splitScreenButton, .mapToggle: mapToggleButton, .timelineToggle: timelineToggleButton, .information: informationButton, .settings: settingsButton, .search: searchButton]

        setupButtons()
        setupGestures()
    }

    override func viewDidAppear() {
        settingsMenu = WindowManager.instance.display(.settings, at: position(for: settingsButton, frame: style.settingsWindowSize, margins: false)) as? SettingsMenuViewController
        settingsMenu.view.isHidden = true
    }


    // MARK: Setup

    private func setupGestures() {
        let viewPanGesture = PanGestureRecognizer()
        gestureManager.add(viewPanGesture, to: view)
        viewPanGesture.gestureUpdated = handleWindowPan(_:)
    }

    private func setupButtons() {
        setupButton(for: .splitScreen)
        setupButton(for: .mapToggle)
        setupButton(for: .timelineToggle)
        setupButton(for: .information)
        setupButton(for: .settings)
        setupButton(for: .search)
    }

    private func setupButton(for type: MenuButtonType) {
        guard let view = viewForButtonType[type], let imageIcon = type.primaryPlaceholder else {
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

        if type == .splitScreen, let secondaryPlaceholder = type.secondaryPlaceholder {
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
            self.lockIcon = lockIcon
        }
    }


    // MARK: API

    func buttonToggled(type: MenuButtonType, selection: ToggleStatus) {
        guard let image = subviewForButtonType[type] else {
            return
        }

        switch selection {
        case .on:
            if !selectedButtons.contains(type) {
                selectedButtons.append(type)
                if let activeIcon = type.selectedPlaceholder {
                    image.transition(to: activeIcon, duration: Constants.imageTransitionDuration)
                }
                if type == .splitScreen, let lockIcon = lockIcon {
                    lockIcon.transition(to: type.secondaryPlaceholder, duration: Constants.imageTransitionDuration)
                }
            }
        case .off:
            if let selectedButtonIndex = selectedButtons.index(of: type) {
                selectedButtons.remove(at: selectedButtonIndex)
                image.transition(to: type.primaryPlaceholder, duration: Constants.imageTransitionDuration)
            }
            if type == .splitScreen, let lockIcon = lockIcon {
                lockIcon.transition(to: nil, duration: Constants.imageTransitionDuration)
            }
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


    // MARK: Gesture Handling

    func handleWindowPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let window = view.window, let settingsWindow = settingsMenu.view.window, let screen = window.screen else {
            return
        }

        switch pan.state {
        case .recognized where abs(pan.delta.dy) > Constants.minimumScrollThreshold || scrollThresholdAchieved, .momentum where scrollThresholdAchieved:
            scrollThresholdAchieved = true
            let origin = originAppending(delta: pan.delta, to: window)
            let settingsOrigin = originAppending(delta: pan.delta, to: settingsWindow)

            if settingsMenu.view.isVisible {
                if pan.delta.dy < 0 && settingsOrigin.y > screen.frame.minY && origin.y > screen.frame.minY {
                    window.setFrameOrigin(origin)
                    settingsWindow.setFrameOrigin(settingsOrigin)
                } else if pan.delta.dy > 0 && settingsOrigin.y < screen.frame.maxY && origin.y < screen.frame.maxY {
                    window.setFrameOrigin(origin)
                    settingsWindow.setFrameOrigin(settingsOrigin)
                }
            } else {
                window.setFrameOrigin(origin)
            }

//            setOrigin(for: window, and: settingsWindow, menuWindowOrigin: origin, settingsWindowOrigin: settingsOrigin)
        case .possible:
            scrollThresholdAchieved = false
        default:
            return
        }
    }


    // MARK: Helpers

    private func setOrigin(for menuWindow: NSWindow, and settingsWindow: NSWindow, menuWindowOrigin: CGPoint, settingsWindowOrigin: CGPoint) {
        guard let screen = menuWindow.screen else {
            return
        }
        // Need to check if settings is visible, if it is, calculate based on that.  if it's not, caculate based on
//        if settingsWindow.isVisible &&

        if screen.frame.minY < settingsWindowOrigin.y && screen.frame.minY < menuWindowOrigin.y, screen.frame.maxY > settingsWindowOrigin.y + style.settingsWindowSize.height && screen.frame.maxY > menuWindowOrigin.y + style.menuWindowSize.height {
            if settingsWindow.isVisible {
                menuWindow.setFrameOrigin(menuWindowOrigin)
                settingsWindow.setFrameOrigin(settingsWindowOrigin)
            } else if !settingsWindow.isVisible {

            }
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

    private func didSelect(type: MenuButtonType) {
        guard selectedButtons.index(of: type) != nil else {
            // Button is not currently selected
            switch type {
            case .splitScreen:
                menuStateHelper?.splitButtonToggled(by: self, to: .on)
            case .mapToggle:
                if let screenIndex = view.calculateScreenIndex(), let mapIndex = view.calculateMapIndex(), MasterViewController.instance?.infoForScreen[screenIndex - 1]?.applicationTypesForMaps[mapIndex] != .mapExplorer {
                    MasterViewController.instance?.apply(.menuLaunchedMapExplorer, toScreen: screenIndex - 1, on: mapIndex)
                    settingsMenu.reset()
                    buttonToggled(type: .settings, selection: .off)
                    buttonToggled(type: .timelineToggle, selection: .off)
                }
            case .timelineToggle:
                if let screenIndex = view.calculateScreenIndex(), let mapIndex = view.calculateMapIndex(), MasterViewController.instance?.infoForScreen[screenIndex - 1]?.applicationTypesForMaps[mapIndex] != .timeline {
                    MasterViewController.instance?.apply(.menuLaunchedTimeline, toScreen: screenIndex - 1, on: mapIndex)
                    buttonToggled(type: .mapToggle, selection: .off)
                }
            case .settings:
                guard let settingsButtonWindow = settingsButton.window, let settingsMenuWindow = settingsMenu.view.window, let screen = settingsButtonWindow.screen else {
                    return
                }

                let position = selectedPosition(for: settingsButton, frame: style.settingsWindowSize, margins: false)
                if position.y < screen.frame.minY {
                    adjustHeight(for: settingsButton, submenu: settingsMenu.view, on: screen)
                    NSAnimationContext.runAnimationGroup({ _ in
                        NSAnimationContext.current.duration = Constants.animationDuration
                        settingsMenu.view.animator().alphaValue = 1
                    })
                } else {
                    settingsMenu.view.window?.setFrameOrigin(position)
                }

                NSAnimationContext.runAnimationGroup({ _ in
                    NSAnimationContext.current.duration = Constants.animationDuration
                    settingsMenu.view.animator().isHidden = false
                })

            case .search:
                WindowManager.instance.display(.search, at: position(for: searchButton, frame: style.searchWindowSize))
            default:
                break
            }

            buttonToggled(type: type, selection: .on)
            return
        }

        // Button is currently selected
        switch type {
        case .splitScreen:
            menuStateHelper?.splitButtonToggled(by: self, to: .off)
        case .settings:
            NSAnimationContext.runAnimationGroup({ _ in
                NSAnimationContext.current.duration = Constants.animationDuration
                settingsMenu.view.animator().isHidden = true
            })
        default:
            break
        }

        buttonToggled(type: type, selection: .off)
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
}
