//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class MenuButtonView: NSView {
    private let buttonType: MenuButtonType
    private var toggleStatus: ButtonState = .off
    private var primaryImage: NSView?
    private var detailImage: NSView?


    private struct Constants {
        static let imageTransitionDuration = 0.5
    }


    // MARK: Init

    init(type: MenuButtonType, buttonSize: NSRect) {
        buttonType = type
        super.init(frame: buttonSize)
        setupButton()
    }

    required public init?(coder: NSCoder) {
        buttonType = MenuButtonType.map
        super.init(coder: coder)
        setupButton()
    }


    // MARK: Setup

    private func setupButton() {
        guard let imageIcon = buttonType.image else {
            return
        }

        primaryImage = NSView()
        if let primaryImage = primaryImage {
            addSubview(primaryImage)
            primaryImage.wantsLayer = true
            primaryImage.layer?.contents = imageIcon
            primaryImage.translatesAutoresizingMaskIntoConstraints = false
            primaryImage.widthAnchor.constraint(equalToConstant: imageIcon.size.width).isActive = true
            primaryImage.heightAnchor.constraint(equalToConstant: imageIcon.size.height).isActive = true
            primaryImage.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            primaryImage.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        }

        guard let secondaryPlaceholder = buttonType.detailImage else {
            return
        }

        wantsLayer = true
        layer?.backgroundColor = style.menuSelectedColor.cgColor
        detailImage = NSView()
        if let detailImage = detailImage {
            addSubview(detailImage)
            detailImage.wantsLayer = true
            detailImage.translatesAutoresizingMaskIntoConstraints = false
            detailImage.widthAnchor.constraint(equalToConstant: secondaryPlaceholder.size.width).isActive = true
            detailImage.heightAnchor.constraint(equalToConstant: secondaryPlaceholder.size.height).isActive = true
            detailImage.trailingAnchor.constraint(equalTo: trailingAnchor, constant: style.menuLockIconPosition.width).isActive = true
            detailImage.topAnchor.constraint(equalTo: topAnchor, constant: style.menuLockIconPosition.height).isActive = true
        }
    }


    // MARK: API

    func toggle(to status: ButtonState) {
        toggleStatus = status
        let image = status == .on ? buttonType.selectedImage : buttonType.image
        primaryImage?.transition(to: image, duration: Constants.imageTransitionDuration)
    }
}
