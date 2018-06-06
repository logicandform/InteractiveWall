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
    private var scrollMinimumSpeedAchieved = false
    private var buttonTypeView = [MenuButtonType: NSView]()
    private var buttonTypeSubview = [MenuButtonType: NSView]()
    private var selectedButtons = [MenuButtonType]()
    private var lockIcon: NSView?

    private struct Constants {
        static let minimumScrollSpeed: CGFloat = 4
        static let imageTransitionDuration = 0.5
    }


    // MARK: Init

    static func instantiate() {
        for screen in NSScreen.screens.sorted(by: { $0.frame.minX < $1.frame.minX }).dropFirst() {
            let screenFrame = screen.frame
            let menuStateHelper = MenuStateHelper()

            for menuNumber in 1...(Configuration.mapsPerScreen) {
                let x: CGFloat

                if menuNumber % 2 == 1 {
                    x = screenFrame.maxX - style.menuWindowSize.width
                } else {
                    x = screenFrame.minX
                }

                let y = screenFrame.midY - style.menuWindowSize.height / 2
                let menu = WindowManager.instance.display(.menu, at: CGPoint(x: x, y: y))

                if let menu = menu as? MenuViewController {
                    menuStateHelper.add(menu)
                    menu.menuStateHelper = menuStateHelper
                }
            }
        }
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)

        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor

        buttonTypeView = [.splitScreen: splitScreenButton, .mapToggle: mapToggleButton, .timelineToggle: timelineToggleButton, .information: informationButton, .settings: settingsButton, .search: searchButton]

        setupButtons()
        setupGestures()
    }


    // MARK: Setup

    private func setupGestures() {
        let viewPanGesture = PanGestureRecognizer()
        gestureManager.add(viewPanGesture, to: view)
        viewPanGesture.gestureUpdated = handleWindowPan(_:)
    }

    private func setupButtons() {
        setupButton(with: .splitScreen)
        setupButton(with: .mapToggle)
        setupButton(with: .timelineToggle)
        setupButton(with: .information)
        setupButton(with: .settings)
        setupButton(with: .search)
    }

    private func setupButton(with type: MenuButtonType) {
        guard let view = buttonTypeView[type], let imageIcon = type.primaryPlaceholder else {
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
        buttonTypeSubview[type] = image
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
        guard let image = buttonTypeSubview[type] else {
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
        guard let pan = gesture as? PanGestureRecognizer, let window = view.window else {
            return
        }

        switch pan.state {
        case .recognized where abs(pan.delta.dy) > Constants.minimumScrollSpeed || scrollMinimumSpeedAchieved, .momentum where scrollMinimumSpeedAchieved:
            scrollMinimumSpeedAchieved = true
            var origin = window.frame.origin
            origin = updateSpeedAtBoundary(for: pan.delta.dy, with: window)
            window.setFrameOrigin(origin)
        case .possible:
            scrollMinimumSpeedAchieved = false
        default:
            return
        }
    }


    // MARK: Helpers

    private func addGesture(for type: MenuButtonType) {
        guard let view = buttonTypeView[type], let subview = buttonTypeSubview[type] else {
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
            if type == .splitScreen {
                menuStateHelper?.splitButtonToggled(by: self, to: .on)
            } else if type == .search {
                searchSelected()
            }

            buttonToggled(type: type, selection: .on)
            return
        }

        if type == .splitScreen {
            menuStateHelper?.splitButtonToggled(by: self, to: .off)
        }

        buttonToggled(type: type, selection: .off)
    }

    private func updateSpeedAtBoundary(for velocity: CGFloat, with window: NSWindow) -> CGPoint {
        var updatedOrigin = window.frame.origin
        guard let applicationFrame = NSScreen.containing(x: updatedOrigin.x)?.frame else {
            return updatedOrigin
        }

        updatedOrigin.y += velocity

        if velocity < 0 && updatedOrigin.y < applicationFrame.minY {
            updatedOrigin.y = applicationFrame.minY
        } else if velocity > 0 && updatedOrigin.y + window.frame.height > applicationFrame.maxY {
            updatedOrigin.y = applicationFrame.maxY - window.frame.height
        }

        return updatedOrigin
    }

    private func searchSelected() {
        guard let windowPosition = searchButton.window?.frame, let screenBounds = NSScreen.containing(x: windowPosition.origin.x)?.frame else {
            return
        }

        let buttonOrigin = windowPosition.transformed(from: searchButton.frame).origin
        var x = windowPosition.maxX + style.windowMargins
        let y = buttonOrigin.y + style.menuImageSize.height - style.searchWindowSize.height

        if windowPosition.maxX >= screenBounds.maxX {
            x = windowPosition.origin.x - style.searchWindowSize.width - style.windowMargins
        }

        WindowManager.instance.display(.search, at: CGPoint(x: x, y: y))
    }
}
