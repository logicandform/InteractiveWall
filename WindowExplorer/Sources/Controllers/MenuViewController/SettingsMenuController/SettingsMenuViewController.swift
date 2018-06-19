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
    private var appID: Int!
    private var labelsSwitch: SwitchControl!
    private var miniMapSwitch: SwitchControl!
    private var schoolsSwitch: SwitchControl!
    private var eventsSwitch: SwitchControl!
    private var organizationsSwitch: SwitchControl!
    private var artifactsSwitch: SwitchControl!

    private var switchForSettingsType = [SettingsType: SwitchControl]()
    private var textFieldForSettingsType = [SettingsType: NSTextField]()

    private struct Keys {
        static let id = "id"
        static let recordType = "recordType"
        static let status = "status"
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        gestureManager = GestureManager(responder: self)

        setupSwitches()
        setupGestures()
        setupNotifications()
    }


    // MARK: API

    func set(appID: Int) {
        self.appID = appID
    }

    func reset() {
        view.isHidden = true
        labelsSwitch.isOn = true
        miniMapSwitch.isOn = false
        schoolsSwitch.isOn = true
        eventsSwitch.isOn = true
        artifactsSwitch.isOn = true
        organizationsSwitch.isOn = true
    }

    func updateOrigin(relativeTo button: CGPoint, with frame: NSRect) {
        guard let window = view.window, let screen = window.screen else {
            return
        }

        let updatedVerticalPosition = button.y + frame.origin.y + frame.height - view.frame.height
        if updatedVerticalPosition < 0 {
            view.window?.setFrameOrigin(CGPoint(x: window.frame.origin.x, y: screen.frame.minY))
        } else {
            view.window?.setFrameOrigin(CGPoint(x: window.frame.origin.x, y: updatedVerticalPosition))
        }
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

    private func setupNotifications() {
        for notification in SettingsNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }


    // MARK: Gesture Handling

    private func toggle(_ switchControl: SwitchControl, with type: SettingsType) {
        switchControl.isOn = !switchControl.isOn
        let recordType = type.recordType?.rawValue ?? ""
        let info: JSON = [Keys.id: appID, Keys.recordType: recordType, Keys.status: switchControl.isOn]
        DistributedNotificationCenter.default().postNotificationName(SettingsNotification.with(type).name, object: nil, userInfo: info, deliverImmediately: true)
    }


    // MARK: Notification Handling

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo, let id = info[Keys.id] as? Int, let status = info[Keys.status] as? Bool else {
            return
        }

        // Only respond to notifications from the same group, or if group is nil
        if let group = ConnectionManager.instance.groupForApp(id: appID) {
            if group != ConnectionManager.instance.groupForApp(id: id) {
                return
            }
        }

        switch notification.name {
        case SettingsNotification.filter.name:
            if let rawRecordType = info[Keys.recordType] as? String, let recordType = RecordType(rawValue: rawRecordType), let setting = SettingsType.from(recordType: recordType) {
                switchForSettingsType[setting]?.isOn = status
            }
        case SettingsNotification.labels.name:
            switchForSettingsType[.showLabels]?.isOn = status
        case SettingsNotification.miniMap.name:
            switchForSettingsType[.showMiniMap]?.isOn = status
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
        return view.isHidden ? false : view.frame.contains(position)
    }


    // MARK: Helpers

    private func setupSwitch(for type: SettingsType, on: Bool = true) -> SwitchControl? {
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

    private func setupGesture(for type: SettingsType) {
        guard let toggleSwitch = switchForSettingsType[type] else {
            return
        }

        let toggleTap = TapGestureRecognizer()
        gestureManager.add(toggleTap, to: toggleSwitch)
        toggleTap.gestureUpdated = { [weak self] tap in
            if tap.state == .ended {
                self?.toggle(toggleSwitch, with: type)
            }
        }
    }
}
