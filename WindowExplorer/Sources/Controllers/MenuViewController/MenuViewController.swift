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
    private var scrollMinimumSpeedAchieved = false
    private var buttonTypeView = [MenuButtonType: NSView]()
    private var buttonTypeSubview = [MenuButtonType: NSView]()

    private struct Constants {
        static let minimumScrollSpeed: CGFloat = 4
    }


    // MARK: Init

    static func instantiate() {
        for screen in NSScreen.screens.sorted(by: { $0.frame.minX < $1.frame.minX }).dropFirst() {
            let screenFrame = screen.frame

            for menuNumber in 1...(Configuration.mapsPerScreen) {
                let x: CGFloat

                if menuNumber % 2 == 1 {
                    x = screenFrame.maxX - style.menuWindowSize.width
                } else {
                    x = screenFrame.minX
                }

                let y = screenFrame.midY - style.menuWindowSize.height / 2
                WindowManager.instance.display(.menu, at: CGPoint(x: x, y: y))
            }
        }
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)

        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor

        buttonTypeView = [MenuButtonType.splitScreen: splitScreenButton, MenuButtonType.mapToggle: mapToggleButton, MenuButtonType.timelineToggle: timelineToggleButton, MenuButtonType.information: informationButton, MenuButtonType.settings: settingsButton, MenuButtonType.search: searchButton]

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
        setupButton(with: MenuButtonType.splitScreen)
        setupButton(with: MenuButtonType.mapToggle)
        setupButton(with: MenuButtonType.timelineToggle)
        setupButton(with: MenuButtonType.information)
        setupButton(with: MenuButtonType.settings)
        setupButton(with: MenuButtonType.search)
    }

    private func setupButton(with type: MenuButtonType) {
        guard let view = buttonTypeView[type] else {
            return
        }

        let image = NSView()
        view.addSubview(image)
        image.wantsLayer = true
        image.layer?.contents = type.placeholder?.tinted(with: style.unselectedRecordIcon)
        image.translatesAutoresizingMaskIntoConstraints = false
        image.widthAnchor.constraint(equalToConstant: 40).isActive = true
        image.heightAnchor.constraint(equalToConstant: 40).isActive = true
        image.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        image.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        buttonTypeSubview[type] = image
        addGesture(withButtonType: type)
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
        case .recognized where abs(pan.delta.dy) > Constants.minimumScrollSpeed || scrollMinimumSpeedAchieved, .momentum:
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

    private func addGesture(withButtonType type: MenuButtonType) {
        guard let view = buttonTypeView[type], let subview = buttonTypeSubview[type] else {
            return
        }

        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: subview)

        let panGesture = PanGestureRecognizer()
        gestureManager.add(panGesture, to: subview)
        panGesture.gestureUpdated = handleWindowPan(_:)

        tapGesture.gestureUpdated = { [weak self] tap in
            if tap.state == .ended {
                self?.didSelect(view: view, image: subview, type: type)
            }
        }
    }

    private func didSelect(view: NSView, image: NSView, type: MenuButtonType) {
        image.transition(to: type.placeholder?.tinted(with: type.color), duration: 0.5)
    }

    private func updateSpeedAtBoundary(for velocity: CGFloat, with window: NSWindow) -> CGPoint {
        var updatedOrigin = window.frame.origin
        guard let applicationFrame = NSScreen.containing(x: updatedOrigin.x)?.frame else {
            return updatedOrigin
        }

        updatedOrigin.y = updatedOrigin.y + velocity

        if velocity < 0 && updatedOrigin.y < applicationFrame.minY {
            updatedOrigin.y = applicationFrame.minY
        } else if velocity > 0 && updatedOrigin.y + window.frame.height > applicationFrame.maxY {
            updatedOrigin.y = applicationFrame.maxY - window.frame.height
        }

        return updatedOrigin
    }
}
