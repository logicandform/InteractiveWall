//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum SettingsTypes {
    case showLabels
    case showMiniMap
    case showLightbox
    case schools
    case events
    case organizations
    case artifacts
}


class SettingsMenuViewController: NSViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "SettingsMenu")

    var gestureManager: GestureManager!
    private var labelsSwitch: MacToggle?
    private var miniMapSwitch: MacToggle?
    private var lightboxSwitch: MacToggle?
    private var schoolsSwitch: MacToggle?
    private var eventsSwitch: MacToggle?
    private var organizationsSwitch: MacToggle?
    private var artifactsSwitch: MacToggle?

    private var switchForSettingsType = [SettingsTypes: MacToggle?]()


    // MARK: Life-cycle 

    override func viewDidLoad() {
        super.viewDidLoad()

        gestureManager = GestureManager(responder: self)

        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor

        switchForSettingsType = [.showLabels: labelsSwitch, .showMiniMap: miniMapSwitch, .showLightbox: lightboxSwitch, .schools: schoolsSwitch, .events: eventsSwitch, .organizations: organizationsSwitch, .artifacts: artifactsSwitch]

        setupSwitches()

        guard let labelsSwitch = labelsSwitch else {
            return
        }

        let toggleTap = TapGestureRecognizer()
        gestureManager.add(toggleTap, to: labelsSwitch)
        toggleTap.gestureUpdated = handleToggle(_:)
    }


    // MARK: Setup

    private func setupSwitches() {
        labelsSwitch = setupSwitch(for: .showLabels)
//        miniMapSwitch = setupSwitch(for: .showMiniMap)
//        lightboxSwitch = setupSwitch(for: .showLightbox)
//        schoolsSwitch = setupSwitch(for: .schools)
//        eventsSwitch = setupSwitch(for: .events)
//        organizationsSwitch = setupSwitch(for: .organizations)
//        artifactsSwitch = setupSwitch(for: .artifacts)
    }

    private func setupSwitch(for type: SettingsTypes) -> MacToggle {
        let toggleSwitch: MacToggle = {
            let view = MacToggle(height: 20)
            view.isOn = true
            view.fillColor = style.artifactColor
            return view
        }()

        view.addSubview(toggleSwitch)
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false

        toggleSwitch.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        toggleSwitch.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        return toggleSwitch
    }


    // MARK: Gesture Handling

    private func handleToggle(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended else {
            return
        }

        labelsSwitch?.isOn = false
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
}
