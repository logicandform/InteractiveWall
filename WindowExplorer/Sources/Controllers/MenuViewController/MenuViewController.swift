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
    private var buttonType = [NSView: MenuButtonType]()

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

        buttonType = [splitScreenButton: MenuButtonType.splitScreen, mapToggleButton: MenuButtonType.mapToggle, timelineToggleButton: MenuButtonType.timelineToggle, informationButton: MenuButtonType.information, settingsButton: MenuButtonType.settings, searchButton: MenuButtonType.search]

        setupButtons()
    }


    // MARK: Setup

    private func setupButtons() {
        setupButton(for: splitScreenButton, with: MenuButtonType.splitScreen)
        setupButton(for: mapToggleButton, with: MenuButtonType.mapToggle)
        setupButton(for: timelineToggleButton, with: MenuButtonType.timelineToggle)
        setupButton(for: informationButton, with: MenuButtonType.information)
        setupButton(for: settingsButton, with: MenuButtonType.settings)
        setupButton(for: searchButton, with: MenuButtonType.search)
    }

    private func setupButton(for view: NSView, with type: MenuButtonType) {
        let image = NSView()
        view.addSubview(image)
        image.wantsLayer = true
        image.layer?.contents = type.placeholder?.tinted(with: style.unselectedRecordIcon)
        image.translatesAutoresizingMaskIntoConstraints = false
        image.widthAnchor.constraint(equalToConstant: 40).isActive = true
        image.heightAnchor.constraint(equalToConstant: 40).isActive = true
        image.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        image.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        addGesture(to: view, with: image)
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
        case .recognized, .momentum:
            if !scrollMinimumSpeedAchieved && abs(pan.delta.dy) < Constants.minimumScrollSpeed {
                return
            } else {
                scrollMinimumSpeedAchieved = true
            }

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

    private func addGesture(to view: NSView, with sublayer: NSView) {
        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: sublayer)

        tapGesture.gestureUpdated = { [weak self] tap in
            if tap.state == .ended {
                self?.didSelect(view: view, image: sublayer)
            }
        }
    }

    private func didSelect(view: NSView, image: NSView) {
//        guard let view = view as? NSImageView, let type = buttonType[view] else {
        guard let type = buttonType[view] else {
            return
        }

        image.transition(to: type.placeholder?.tinted(with: type.color), duration: 0.5)
    }

    private func updateSpeedAtBoundary(for velocity: CGFloat, with window: NSWindow) -> CGPoint {
        let applicationFrame = getApplicationFrame()

        var updatedOrigin = window.frame.origin
        updatedOrigin.y = updatedOrigin.y + velocity

        if velocity < 0 && updatedOrigin.y < applicationFrame.minY {
            updatedOrigin.y = applicationFrame.minY
        } else if velocity > 0 && updatedOrigin.y + window.frame.height > applicationFrame.maxY {
            updatedOrigin.y = applicationFrame.maxY - window.frame.height
        }

        return updatedOrigin
    }

    private func getApplicationFrame() -> CGRect {
        let applicationScreens = NSScreen.screens.dropFirst()
        let first = applicationScreens.first?.frame ?? .zero
        return applicationScreens.reduce(first) { $0.union($1.frame) }
    }
}
