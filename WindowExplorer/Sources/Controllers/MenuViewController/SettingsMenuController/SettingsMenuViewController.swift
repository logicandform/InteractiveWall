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

    var color: NSColor {
        switch self {
        case .showLabels:
            return style.menuSelectedColor
        case .showMiniMap:
            return style.menuSelectedColor
        case .showLightbox:
            return style.menuSelectedColor
        case .schools:
            return style.schoolColor
        case .events:
            return style.eventColor
        case .organizations:
            return style.organizationColor
        case .artifacts:
            return style.artifactColor
        }
    }

    var secondaryColor: NSColor {
        switch self {
        case .showLabels:
            return style.menuSecondarySelectedColor
        case .showMiniMap:
            return style.menuSecondarySelectedColor
        case .showLightbox:
            return style.menuSecondarySelectedColor
        case .schools:
            return style.schoolSecondarySelectedColor
        case .events:
            return style.eventSecondarySelectedColor
        case .organizations:
            return style.organizationSecondarySelectedColor
        case .artifacts:
            return style.artifactSecondarySelectedColor
        }
    }
}


class SettingsMenuViewController: NSViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "SettingsMenu")

    @IBOutlet weak var labelsText: NSTextField!
    @IBOutlet weak var miniMapText: NSTextField!
    @IBOutlet weak var lightboxText: NSTextField!
    @IBOutlet weak var schoolsText: NSTextField!
    @IBOutlet weak var eventsText: NSTextField!
    @IBOutlet weak var organizationsText: NSTextField!
    @IBOutlet weak var artifactsText: NSTextField!

    var gestureManager: GestureManager!
    private var labelsSwitch: SwitchControl!
    private var miniMapSwitch: SwitchControl!
    private var lightboxSwitch: SwitchControl!
    private var schoolsSwitch: SwitchControl!
    private var eventsSwitch: SwitchControl!
    private var organizationsSwitch: SwitchControl!
    private var artifactsSwitch: SwitchControl!

    private var switchForSettingsType = [SettingsTypes: SwitchControl]()
    private var textFieldForSettingsType = [SettingsTypes: NSTextField]()


    // MARK: Life-cycle 

    override func viewDidLoad() {
        super.viewDidLoad()

        gestureManager = GestureManager(responder: self)

        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor

        textFieldForSettingsType = [.showLabels: labelsText, .showMiniMap: miniMapText, .showLightbox: lightboxText, .schools: schoolsText, .events: eventsText, .organizations: organizationsText, .artifacts: artifactsText]
        setupSwitches()
        switchForSettingsType = [.showLabels: labelsSwitch, .showMiniMap: miniMapSwitch, .showLightbox: lightboxSwitch, .schools: schoolsSwitch, .events: eventsSwitch, .organizations: organizationsSwitch, .artifacts: artifactsSwitch]


        setupGestures()
    }


    // MARK: Setup

    private func setupSwitches() {
        labelsSwitch = setupSwitch(for: .showLabels)
        miniMapSwitch = setupSwitch(for: .showMiniMap)
        lightboxSwitch = setupSwitch(for: .showLightbox)
        schoolsSwitch = setupSwitch(for: .schools)
        eventsSwitch = setupSwitch(for: .events)
        organizationsSwitch = setupSwitch(for: .organizations)
        artifactsSwitch = setupSwitch(for: .artifacts)
    }

    private func setupSwitch(for type: SettingsTypes) -> SwitchControl? {
        guard let textField = textFieldForSettingsType[type] else {
            return nil
        }

        let toggleSwitch: SwitchControl = {
            let toggle = SwitchControl(isOn: true, frame: style.toggleSwitchFrame)
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

    private func setupGestures() {
        setupGesture(for: .showLabels)
        setupGesture(for: .showMiniMap)
        setupGesture(for: .showLightbox)
        setupGesture(for: .schools)
        setupGesture(for: .artifacts)
        setupGesture(for: .events)
        setupGesture(for: .organizations)
    }

    private func setupGesture(for type: SettingsTypes) {
        guard let toggleSwitch = switchForSettingsType[type] else {
            return
        }

        let toggleTap = TapGestureRecognizer()
        gestureManager.add(toggleTap, to: toggleSwitch)

        toggleTap.gestureUpdated = { [weak self] tap in
            if tap.state == .ended {
                self?.handle(toggleSwitch: toggleSwitch)
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
        if view.alphaValue == 0 {
            return false
        } else {
            return view.frame.contains(position)
        }
    }


    // MARK: Helpers

    private func handle(toggleSwitch: SwitchControl) {
        toggleSwitch.isOn = !toggleSwitch.isOn
    }
}
