//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

enum Side {
    case right
    case left
}

class MenuViewController: NSViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "Menu")

    @IBOutlet weak var leftSearchRecordLabel: NSTextField!
    @IBOutlet weak var leftSwitchInterfaceLabel: NSTextField!
    @IBOutlet weak var rightSearchRecordLabel: NSTextField!
    @IBOutlet weak var rightSwitchInterfaceLabel: NSTextField!

    var gestureManager: GestureManager!


    // MARK: Init

    /// Displays the menuVC between maps on each screen
    static func instantiate() {
        for screen in NSScreen.screens.sorted(by: { $0.frame.minX < $1.frame.minX }).dropFirst() {
            let screenFrame = screen.frame
            let xSpacing = screenFrame.width / CGFloat(Configuration.mapsPerScreen)
            if Configuration.mapsPerScreen == 1 {
                let x = screenFrame.maxX - style.menuWindowSize.width / 2 - (xSpacing / 2)
                let y = screenFrame.midY - style.menuWindowSize.height / 2
                WindowManager.instance.display(.menu, at: CGPoint(x: x, y: y))
            } else {
                for menuNumber in 1...(Configuration.mapsPerScreen - 1) {
                    let x = screenFrame.maxX - style.menuWindowSize.width / 2 - CGFloat(menuNumber) * xSpacing
                    let y = screenFrame.midY - style.menuWindowSize.height / 2
                    WindowManager.instance.display(.menu, at: CGPoint(x: x, y: y))
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

        setupGestures()
    }


    // MARK: Setup

    private func setupGestures() {
        let leftSearchRecordLabelTap = TapGestureRecognizer()
        gestureManager.add(leftSearchRecordLabelTap, to: leftSearchRecordLabel)
        leftSearchRecordLabelTap.gestureUpdated = handleLeftSearchRecordTap(_:)

        let rightSearchRecordLabelTap = TapGestureRecognizer()
        gestureManager.add(rightSearchRecordLabelTap, to: rightSearchRecordLabel)
        rightSearchRecordLabelTap.gestureUpdated = handleRightSearchRecordTap(_:)

        let leftSwitchInterfaceLabelTap = TapGestureRecognizer()
        gestureManager.add(leftSwitchInterfaceLabelTap, to: leftSwitchInterfaceLabel)
        leftSwitchInterfaceLabelTap.gestureUpdated = handleLeftSwitchInterfaceTap(_:)

        let rightSwitchInterfaceLabelTap = TapGestureRecognizer()
        gestureManager.add(rightSwitchInterfaceLabelTap, to: rightSwitchInterfaceLabel)
        rightSwitchInterfaceLabelTap.gestureUpdated = handleRightSwitchInterfaceTap(_:)
    }


    // MARK: Gesture Handling

    private func handleLeftSearchRecordTap(_ gesture: GestureRecognizer) {
        if let tap = gesture as? TapGestureRecognizer, tap.state == .ended {
            displaySearchInterface(on: .left)
        }
    }

    private func handleRightSearchRecordTap(_ gesture: GestureRecognizer) {
        if let tap = gesture as? TapGestureRecognizer, tap.state == .ended {
            displaySearchInterface(on: .right)
        }
    }

    private func handleLeftSwitchInterfaceTap(_ gesture: GestureRecognizer) {
        if let tap = gesture as? TapGestureRecognizer, tap.state == .ended {
            print("leftSwitchInterfaceLabelTap gesture handling not implemented")
        }
    }

    private func handleRightSwitchInterfaceTap(_ gesture: GestureRecognizer) {
        if let tap = gesture as? TapGestureRecognizer, tap.state == .ended {
            print("leftSwitchInterfaceLabelTap gesture handling not implemented")
        }
    }


    // MARK: GestureResponder

    /// Determines if the bounds of the draggable area is inside a given rect
    func draggableInside(bounds: CGRect) -> Bool {
        if view.window == nil {
            return false
        }

       return true
    }


    // MARK: Helpers

    private func displaySearchInterface(on side: Side) {
        guard var origin = view.window?.frame.origin else {
            return
        }

        switch side {
        case .left:
            origin.x -= style.searchWindowSize.width + style.windowMargins
        case .right:
            origin.x += style.windowMargins + view.frame.width
        }

        WindowManager.instance.display(.search, at: origin)
    }
}
