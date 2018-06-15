//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class SettingsMenuViewController: NSViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "SettingsMenu")

    @IBOutlet weak var labelsText: NSTextField!
    @IBOutlet weak var miniMapText: NSTextField!
    @IBOutlet weak var schoolsText: NSTextField!
    @IBOutlet weak var eventsText: NSTextField!
    @IBOutlet weak var organizationsText: NSTextField!
    @IBOutlet weak var artifactsText: NSTextField!

    var gestureManager: GestureManager!
    private var labelsSwitch: SwitchControl!
    private var miniMapSwitch: SwitchControl!
    private var schoolsSwitch: SwitchControl!
    private var eventsSwitch: SwitchControl!
    private var organizationsSwitch: SwitchControl!
    private var artifactsSwitch: SwitchControl!

    private var switchForSettingsType = [SettingsTypes: SwitchControl]()
    private var textFieldForSettingsType = [SettingsTypes: NSTextField]()


    private struct Keys {
        static let id = "id"
        static let map = "map"
        static let group = "group"
        static let gesture = "gestureType"
        static let animated = "amimated"
        static let toggleOn = "toggleOn"
        static let switchType = "switchType"
    }


    // MARK: Life-cycle 

    override func viewDidLoad() {
        super.viewDidLoad()

        gestureManager = GestureManager(responder: self)

        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor

        setupSwitches()
        setupGestures()
    }


    // MARK: Setup

    private func setupSwitches() {
        textFieldForSettingsType = [.showLabels: labelsText, .showMiniMap: miniMapText, .toggleSchools: schoolsText, .toggleEvents: eventsText, .toggleOrganizations: organizationsText, .toggleArtifacts: artifactsText]

        labelsSwitch = setupSwitch(for: .showLabels)
        miniMapSwitch = setupSwitch(for: .showMiniMap, on: false)
        schoolsSwitch = setupSwitch(for: .toggleSchools)
        eventsSwitch = setupSwitch(for: .toggleEvents)
        organizationsSwitch = setupSwitch(for: .toggleOrganizations)
        artifactsSwitch = setupSwitch(for: .toggleArtifacts)

        switchForSettingsType = [.showLabels: labelsSwitch, .showMiniMap: miniMapSwitch, .toggleSchools: schoolsSwitch, .toggleEvents: eventsSwitch, .toggleOrganizations: organizationsSwitch, .toggleArtifacts: artifactsSwitch]
    }

    private func setupGestures() {
        setupGesture(for: .showLabels)
        setupGesture(for: .showMiniMap)
        setupGesture(for: .toggleSchools)
        setupGesture(for: .toggleArtifacts)
        setupGesture(for: .toggleEvents)
        setupGesture(for: .toggleOrganizations)
    }


    // MARK: API

    func reset() {
        view.isHidden = true
        labelsSwitch.isOn = true
        miniMapSwitch.isOn = false
        schoolsSwitch.isOn = true
        eventsSwitch.isOn = true
        artifactsSwitch.isOn = true
        organizationsSwitch.isOn = true
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
        if view.isHidden {
            return false
        } else {
            return view.frame.contains(position)
        }
    }


    // MARK: Helpers

    private func handle(toggleSwitch: SwitchControl, type: SettingsTypes) {
        guard let appID = view.calculateAppID() else {
            return
        }

        toggleSwitch.isOn = !toggleSwitch.isOn
        let info: JSON = [Keys.id: appID, Keys.toggleOn: toggleSwitch.isOn, Keys.switchType: type.rawValue]
        DistributedNotificationCenter.default().postNotificationName(MapNotification.toggleSwitch.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    private func setupSwitch(for type: SettingsTypes, on: Bool = true) -> SwitchControl? {
        guard let textField = textFieldForSettingsType[type] else {
            return nil
        }

        let toggleSwitch: SwitchControl = {
            let toggle = SwitchControl(isOn: on, frame: style.toggleSwitchFrame)
            toggle.knobBackgroundColor = type.color
            toggle.disabledKnobBackgroundColor = style.toggleUnselectedColor
            toggle.tintColor = type.secondaryColor
            toggle.disabledBackgroundColor = style.toggleSecondaryUnselectedColor
            return toggle
        }()

        view.addSubview(toggleSwitch)
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        toggleSwitch.centerYAnchor.constraint(equalTo: textField.centerYAnchor).isActive = true
        toggleSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: style.toggleSwitchOffset).isActive = true
        toggleSwitch.heightAnchor.constraint(equalToConstant: style.toggleSwitchFrame.height).isActive = true
        toggleSwitch.widthAnchor.constraint(equalToConstant: style.toggleSwitchFrame.width).isActive = true
        return toggleSwitch
    }

    private func setupGesture(for type: SettingsTypes) {
        guard let toggleSwitch = switchForSettingsType[type] else {
            return
        }

        let toggleTap = TapGestureRecognizer()
        gestureManager.add(toggleTap, to: toggleSwitch)
        toggleTap.gestureUpdated = { [weak self] tap in
            if tap.state == .ended {
                self?.handle(toggleSwitch: toggleSwitch, type: type)
            }
        }
    }
}
