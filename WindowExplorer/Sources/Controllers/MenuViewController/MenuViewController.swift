//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class MenuViewController: NSViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "Menu")

    @IBOutlet weak var splitScreen: NSImageView!
    @IBOutlet weak var settings: NSImageView!

    var gestureManager: GestureManager!
    private var scrollMinimumSpeedAchieved = false

    private struct Constants {
        static let minimumScrollSpeed: CGFloat = 10
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

        // Testing whether setting image directly will work (may need to do autoresizing as seen in RecordTypeSelectionView init)

        setupImages()
        setupGestures()
    }


    // MARK: Setup

    private func setupGestures() {
        let viewPanGesture = PanGestureRecognizer()
        gestureManager.add(viewPanGesture, to: view)
        viewPanGesture.gestureUpdated = handleWindowPan(_:)
    }

    private func setupImages() {
        splitScreen.image = NSImage(named: "image-icon")?.tinted(with: style.unselectedRecordIcon)
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
        // Need to make some kind of minimum pan gesture before it starts moving (Try: make a bool that is false default, set to true when abs(dy) is > than some value, then set it to false when possible is reached.
        switch pan.state {
        case .recognized, .momentum:
            /*if !scrollMinimumSpeedAchieved && pan.delta.dy < Constants.minimumScrollSpeed {
                return
            } else {
                scrollMinimumSpeedAchieved = true
            }*/
            var origin = window.frame.origin
//            origin = updateSpeedAtBoundary(for: pan.delta.dy, with: window)
//            window.setFrameOrigin(origin)
            if isInBounds(with: pan.delta.dy) {
                origin.y += pan.delta.dy
                window.setFrameOrigin(origin)
            }

        case .possible:
//            scrollMinimumSpeedAchieved = false
            updatePosition()
        default:
            return
        }
    }


    // MARK: Helpers

    private func updatePosition() {
        guard let window = view.window else {
            return
        }

        var origin = window.frame.origin
        let applicationFrame = getApplicationFrame()
        let transformedMenuFrame = view.frame.transformed(from: window.frame)

        if transformedMenuFrame.origin.y < applicationFrame.minY {
            origin.y = applicationFrame.minY
            window.setFrameOrigin(origin)
        } else if transformedMenuFrame.origin.y + transformedMenuFrame.height > applicationFrame.maxY {
            origin.y = applicationFrame.maxY - transformedMenuFrame.height
            window.setFrameOrigin(origin)
        }
    }

    private func updateSpeedAtBoundary(for velocity: CGFloat, with window: NSWindow) -> CGPoint {
        let applicationFrame = getApplicationFrame()

        var updatedOrigin = window.frame.origin
        updatedOrigin.y = updatedOrigin.y + velocity
        // Idea: If dy negative and dy will put origin past minimum y, set to minimum y. Otherwise, return dy.
        if velocity < 0 && updatedOrigin.y < applicationFrame.minY {
            updatedOrigin.y = applicationFrame.minY
        } else if velocity > 0 && updatedOrigin.y + window.frame.height > applicationFrame.maxY {
            // Need to check this logic, not sure about window frame height
            updatedOrigin.y = applicationFrame.maxY - window.frame.height
        }

        return updatedOrigin
    }

    private func isInBounds(with dy: CGFloat = 0) -> Bool{
        let applicationFrame = getApplicationFrame()

        if !draggableInside(bounds: applicationFrame) {
            guard let window = view.window else {
                return false
            }

            let transformedMenuFrame = view.frame.transformed(from: window.frame)
            if dy < 0 && transformedMenuFrame.origin.y <= applicationFrame.minY {
                return false
            } else if dy > 0 && transformedMenuFrame.origin.y + transformedMenuFrame.height >= applicationFrame.maxY {
                return false
            }
        }

        return true
    }

    private func getApplicationFrame() -> CGRect {
        let applicationScreens = NSScreen.screens.dropFirst()
        let first = applicationScreens.first?.frame ?? .zero
        return applicationScreens.reduce(first) { $0.union($1.frame) }
    }

    /*private func resetPosition(in screenFrame: NSRect) {
        guard let window = view.window else {
            return
        }
        var origin = window.frame.origin
        origin.y = screenFrame.midY - style.menuWindowSize.height / 2
        window.setFrameOrigin(origin)
    }*/
}
